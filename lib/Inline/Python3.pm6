unit module Python3;

use NativeCall;

use Inline::Python3::PyInterface;
use Inline::Python3::Utilities;
use Inline::Python3::ObjectPool;

# Essential Guide:
#
# 1. Architecture
# Every object from the python api was represented in a pointer to PyObject.
# Then there rises an essential problem: how to decode the pointers into perl6 objects and
# encode the latter into the former as well as keep the code clean.
#
# I can use various Py*_Check functions provided by python api to test if a PyObject belongs
# to certeain python class. But the question is that an PyObject can belong to several python class.
# For example, a python string object belongs to the 'str' class; at the same time it's also a sequence.
# Thus, the order of using these Py*_Checks matters!  
#
# After several unsuccessful experiments, I came up with the Blackboard architecture(Please correct me if I'm wrong):
# First, set a global data structure to store all python object proxy classes. When an PyObject
# pointer needs decoding, go through the data structure and ask each proxy class if it
# can decode the pointer. Then choose the first one who says yes to do the job. The order of
# asking depends on those classes' level. The higher of a class's level, the earlier it will be
# asked. In order to set a proper level value for each Py*_Check, I built a proxy class hierarchy.
# The deeper of a class's position, the higher of its level. Every proxy has either an "accept-py" method 
# or an "accept-perl6" method, or even both. The former is used to test if it can decode the coming
# PyObject, while the latter for encoding a perl6 object. If a class accepts the coming object, its "from-py" method
# or the "to-py" method wil do the actual job.
#
# 2. User Interface
# In order to make the library easy to use, some proxy class implement the FALLBACK method
# such that users can access python's functions or values as if ther are accessing those of a perl6 module or object..
#
# 3. Principle
# (1) Keep the code extensible.
# (2) Strive to avoid cyclic dependency.

# Simple wrapper for python exception
class PythonException is Exception is export {
    has $.message;
}

# Interface for all the python object proxy.
class PyObject is export {
    # Every object class must have a level, which is used to determine the class's
    # precedence of inspecting coming PyObject then converting it to perl6 proxy.
    # Default value is the base class's plus oen. Higher value means higher precedence.
    method level { self.^parents.elems }

    # Can this proxy class decode the coming PyObject ? Default to no. 
    multi method accept-py($object --> Bool) { False }

    # Can this proxy class encode the perl6 object ? Default to no.
    multi method accept-perl6($object --> Bool) { False }    

    # Method to decode PyObject.
    # Note that all $object passed in are borrowed reference.
    multi method from-py(PyRef $object) { ... }

    # Method to encode perl6 object
    multi method to-py($object --> PyRef) { ... }
}

# Every python object proxy class must have their type registered in the 'type-center'.
# When a pyhton object comes from the python world, the static method from-py will go through
# the type-center and test which proxy class can decode the PyObject.
# The first who answer yes will be used to convert the python object into perl6 one.
# The order of testing depends on the levels of those proxy class. Higher level means higher precedence.

class ObjectConverter {
    INIT {
	my PyObject:U @.type-center = ();
	py_init_python;
    }

    # To register the proxy class.
    # Sorting the sequence after every registration is quite inefficient, however I don't know how to
    # make it fast as well as keep the user code simple. 
    method register($type) {
	@.type-center.append($type);
	@.type-center.=sort(- *.level);
    }    

    # The static method to decode a PyObject into perl6 object.
    # usage: my $py-object = ...
    #        my $perl6-object = ObjectConverter.decode($py-object)
    # Note that all $object passed in are borrowed reference.    
    method decode(PyRef $object) {
	for @.type-center -> $type {
	    if $type.accept-py($object) {
		$type.from-py($object).return
	    }
	}

	die "error: unknown python object: " ~ $object.perl;
    }

    # The static method to encode a perl6 object into PyObject.
    # usage: my $perl6-object = ...
    #        my $py-object = ObjectConverter.encode($perl6-object)
    method encode($object --> PyRef) {
	for @.type-center -> $type {
	    if $type.accept-perl6($object) {
		$type.to-py($object).return
	    }
	}
	
	die "unknown perl6 object: " ~ $object.perl;
    }

    # The static method to dump the type-center and show which proxy class
    # can decode/encode the object.
    # It exists for debugging. 
    method who-accept-it($object, :$encode, :$decode) {
	@.type-center.map: do -> $type {
	    with $encode { ($type, $type.accept-perl6($object)) }
	    orwith $decode { ($type, $type.accept-py($object)) }
	    else { die 'encode or decode ?' }
	}
    }

    # The static method to convert a PyObject into a perl6 string.
    # It exists for debugging.
    method stringify(PyRef:D $object) {
	py_object_str($object) free-after {
	    self.decode($^py-str);
	}
    }
    
    # The static method to detect the exception raised in c code.
    # If there does exist one, the method will convert it into PythonException
    # and rethrow it.
    method detect-exception {
	my @exception := CArray[Pointer].allocate(4);
	py_fetch_error(@exception);
	my $ex-type = @exception[0];

	if $ex-type {
	    my $ex-name = self.stringify($ex-type);
	    my $ex-message = self.stringify(@exception[3]); 
            @exception[$_] and py_dec_ref(@exception[$_]) for ^4;
	    PythonException.new(message => "$ex-name $ex-message").throw
	}	
    }    
}


# This class collects all perl6 callbacks and guides the python fucntion call to the right
# perl6 callback.
class CallbackCenter {
    INIT {
	my %.callbacks = ();
	py_set_perl6_call_handle(&dispatch-callback);	
    }

    # To reegister the perl6 callback.
    # Python code will use the callback's perl6 name as its name in python environment,
    # so its name must be a valid pyhton identifier.
    method register(Callable $callback) {
	my $name = self.id($callback);
	if not defined (%.callbacks{$name}) {
	    %.callbacks.push($name => $callback)
	} else {
	    die "error: callback $name has been registered!"
	}
    }

    # To guide the python call to the right perl6 callback
    sub dispatch-callback(Str $name, PyRef $args, Pointer $error --> PyRef) {
	CATCH {
	    default {
		my $message = ObjectConverter.encode($_.gist);
		nativecast(CArray[Pointer], $error)[0] = $message;
	    }
	}

	with (CallbackCenter.callbacks{$name}) { $_($args) }
	else { die "error: no such callback: $name" }
    }

    # The helper to calculate a perl6 callback's python name
    method id(Callable $callback) {
	$callback.gist ~~ /\&(\S+)/;
	~$0
    }
}

# Helper for shortening code.
sub callback_id(Callable $callback) {
    CallbackCenter.id($callback)
}

# The proxy class for python's None & perl6's Any.
class PyNone is PyObject is export {
    INIT { ObjectConverter.register($?CLASS) }

    multi method accept-py(PyRef:D $object) {
	py_none_check($object)
    }

    multi method accept-py(PyRef:U $object) { True }
    
    multi method accept-perl6(Any:U $object) { True }
    
    multi method from-py(PyRef $object) {
	Any
    }

    multi method to-py(Any:U $object) {
	py_none
    }
}

# The base proxy for all basic objects, such as numbers, strings and arrays,
# It exists for increasing the level value and thus higher precedence.
class PyAtomic is PyObject is export {
    INIT { ObjectConverter.register($?CLASS) }
}

# The proxy class for integer
class PyInteger is PyAtomic is export {
    INIT { ObjectConverter.register($?CLASS) }

    multi method accept-py(PyRef:D $object) {
	py_int_check($object);
    }

    multi method accept-perl6(Int:D $object) { True }
    
    multi method from-py(PyRef:D $object) {
	py_int_from_py($object)
    }

    multi method to-py(Int $object) {
	py_int_to_py($object)
    }
}

# The basic proxy for real number
class PyFloat is PyAtomic is export {
    INIT { ObjectConverter.register($?CLASS) }

    multi method accept-py(PyRef:D $object) {
	py_float_check($object);
    }
    
    multi method accept-perl6(Num:D $object) { True }

    multi method accept-perl6(Rat:D $object) { True }    
    
    multi method from-py(PyRef:D $object) {
	py_float_from_py($object)
    }

    multi method to-py(Num:D $object) {
	py_float_to_py($object)
    }

    multi method to-py(Rat:D $object) {
	py_float_to_py($object.Num)
    }
}

# The proxy class for any sequence
class PySequence is PyAtomic is export {
    INIT { ObjectConverter.register($?CLASS) }

    multi method accept-py(PyRef:D $object) {
	py_sequence_check($object)
    }

    multi method accept-perl6(Positional:D $object) { True }

    # Caution: PySequence treats the unit of unicode as a PySequence,
    # so without PyUnicode registered, using PySequence to decode
    # a unicode string will cause infinite recursion !!!
    multi method from-py(PyRef:D $object) {
    	my @array;
    	for 0..^py_sequence_length($object) -> $i {
    	    py_sequence_get_item($object, $i) free-after -> $item {
    		@array[$i] = ObjectConverter.decode($item);
    	    }
    	}
    	@array	
    }

    multi method to-py(Positional:D $object) {
    	py_list_new($object.elems) modified-by -> $py-array {
    	    for @$object.kv -> $i, $value {
    		py_list_set_item($py-array, $i, ObjectConverter.encode($value));
    	    }
    	}	
    }    
}

# The proxy class for has
class PyMap is PyAtomic is export {
    INIT { ObjectConverter.register($?CLASS) }

    multi method accept-py(PyRef:D $object) {
	py_mapping_check($object)
    }

    multi method accept-perl6(Map:D $object) { True }
    
    multi method from-py(PyRef:D $object) {
    	my %hash;
    	py_mapping_items($object) free-after -> $sequence {	
    	    for ObjectConverter.decode($sequence) -> $item {
    		%hash{$item[0]} = $item[1]
    	    }
    	}
    	%hash
    }

    multi method to-py(Map:D $object) {
    	py_dict_new() modified-by -> $py-dict {
    	    for $object.kv -> $key, $value {
    		py_dict_set_item(
		    $py-dict,
		    ObjectConverter.encode($key),
		    ObjectConverter.encode($value)
		);
    	    }
    	}
    }        
}

# The proxy class for byte string python.
# As there exist two sorts of string type in python: bytes and unicode,
# I have to create two proxy classes for decode them.
class PyBytesString is PySequence is export {
    INIT { ObjectConverter.register($?CLASS) }

    multi method accept-py(PyRef:D $object) {
	py_bytes_check($object)
    }
    
    multi method from-py(PyRef:D $object) {
	my $str = py_bytes_as_string($object);
	$str # is this a deep clone
    }
}

# The proxy class for unicode in python.
class PyUnicodeString is PySequence is export {
    INIT { ObjectConverter.register($?CLASS) }

    multi method accept-py(PyRef:D $object) {
	py_unicode_check($object)
    }

    multi method accept-perl6(Str:D $object) { True }

    multi method from-py(PyRef:D $object) {
	my $string = py_unicode_to_utf8($object);
	my $str = py_bytes_as_string($string);
	$str # is this a deep clone?
    }

    multi method to-py(Str:D $object) {
	py_str_to_py($object.encode('UTF-8').bytes, $object);	
    }    
}

# The proxy for python tuple.
# As python's functions pass parameter in tuple,
# I have to create a proxy type to decode/encode functions' parameters.
class PyTuple is PySequence is export {
    INIT { ObjectConverter.register($?CLASS) }

    has @.array;
    
    method new(@array) { self.bless(:@array) }
    
    multi method accept-perl6(PyTuple:D $object) { True }

    multi method to-py(PyTuple:D $object) {
    	py_tuple_new($object.array.elems) modified-by -> $py-tuple {
    	    for $object.array.kv -> $i, $value {
    		py_tuple_set_item($py-tuple, $i, ObjectConverter.encode($value))
    	    }
    	}	
    }        
}

# The proxy class for all non-atomic types. 
# It's name is bad, as it not only decodes instance object, but also does class obejct.
# This proxy class will guide attribute access/method call to their python object,
# so the use can use the pyhton object like pyhton code, e.g. Foo().get_name .
class PyInstance is PyObject is export {
    INIT { ObjectConverter.register($?CLASS) }

    has $.ref;

    multi method accept-py(PyRef:D $object) {
	py_instance_check($object)
    }
    
    multi method accept-perl6(PyInstance:D $object) { True }
    
    multi method from-py(PyRef:D $object) {
	PyInstance.new(ref => $object)
    }

    multi method to-py(PyInstance:D $object) {
	$object.ref
    }

    # cyclic dependency ?
    # to passs the method call to the python object
    method FALLBACK($name, |args) {
	with py_object_get_attr_string($.ref, $name) {
	    $_ free-after -> $attr {
		if py_type_check($attr) {
		    # It's a little complex.
		    # if the $_ is a class object, e.g. Foo, I cannot figure out if 
		    # it's instantiating a python class(e.g. Foo()) or accessing a
		    # static attribute/method, e.g. Foo.some_static_method.
		    # So I decide to delay the decision to PyClass proxy. (then cyclic dependency???)
		    my $proxy = ObjectConverter.decode($attr);
		    args.Bool ?? $proxy(|args) !! $proxy;
		} else {
		    do {
			py_callable_check($attr) ?? self.call-py-object($attr, |args) !! $attr;
		    } free-after { ObjectConverter.decode($^result) }
		}
	    }
	} else {
	    py_raise_missing_method($.ref, $name)
	}
    }

    method call-py-object(PyRef:D $object, |args --> PyRef) {
	my $py-args = ObjectConverter.encode(PyTuple.new(args.list));
	my $py-kwargs = ObjectConverter.encode(args.hash);
	py_object_call($object, $py-args, $py-kwargs) modified-by -> $ {
	    ObjectConverter.detect-exception
	}
    }

    submethod DESTROY {
	$!ref and py_dec_ref($!ref)
    }
}

# The proxy for python module
# It derivatives from PyInstance, so you can use it like python code,
# e.g.
#     my $main PyModule('__main__');
#        $main.print(1,3,4,5)
#
#    PyModule('string').digits
#
class PyModule is PyInstance is export {
    INIT { ObjectConverter.register($?CLASS) }

    multi method accept-py(PyRef:D $object) {
	py_module_check($object)
    }
    
    multi method from-py(PyRef:D $object) {
	PyModule.new(ref => $object)
    }

    # To import a module.
    method CALL-ME(Str $name) {
	my $module = py_import($name);
	ObjectConverter.detect-exception;
	PyModule.new(ref => $module)
    }

    # To feed a string of python code to python interpreter then fethch the result.
    # if you don't specify any keyword, :file will be chosed.
    method run($code, :$single, :$eval, :$file) {
	my $globals = py_module_getdict($.ref);
	my $locals = $globals;

	my $mode = do {
	    with $single { py_mode_single_input }
	    orwith $eval { py_mode_eval_input }
	    else { py_mode_file_input }
	}
	
	py_run_string($code, $mode, $globals, $locals) free-after {	 
	    ObjectConverter.detect-exception;   
	    ObjectConverter.decode($^result)
	}
    }
}

# The proxy class for callable
# Note that besides functions and methods, class objects are also callable.
class PyCallable is PyInstance is export {
    INIT { ObjectConverter.register($?CLASS) }

    multi method accept-py(PyRef:D $object) {
	py_callable_check($object)
    }
    
    multi method from-py(PyRef:D $object) {
	PyCallable.new(ref => $object)
    }

    method CALL-ME(|args) {
	self.call-py-object($.ref, |args) free-after {
	    ObjectConverter.decode($^result);
	}
    }
}

# The proxy class for class object, e.g. type(SomeClass)
class PyType is PyCallable {
    INIT { ObjectConverter.register($?CLASS) }

    multi method accept-py(PyRef:D $object) {
	py_type_check($object)
    }
    
    multi method from-py(PyRef:D $object) {
	PyType.new(ref => $object)
    }
}

# The proxy class for perl6 object in python world
# It will create a proxy object in python  world and reference the perl6 objects with an index of obejct pool.
#
# Do not do this in perl6 code: PyModule('__main__').Perl6Object(x);
# Or you will create a ghost Perl6Object instance in python world
class Perl6Instance is PyInstance is export {
    constant perl6-object-class = "Perl6Object";
    constant perl6-object-mark = "__perl6_object_index__";

    INIT {
	ObjectConverter.register($?CLASS);
	CallbackCenter.register(&call_instance);
	CallbackCenter.register(&call_method);
	CallbackCenter.register(&delete_instance);
	
	my ($dir, $name) = get-perl6-module-path;
	
	PyModule('__main__').run(qq:to/PYTHON/);
	import sys
	sys.path.append("$dir")
	import { $name }
	class {perl6-object-class}:
	    def __init__(self, index):
                self.{perl6-object-mark} = index
            def __getattr__(self, name):
                return libperl6.call_perl6('{callback_id(&call_method)}', [self.{perl6-object-mark}, name])
            def __call__(self, *args):
                return libperl6.call_perl6('{callback_id(&call_instance)}', [self.{perl6-object-mark}, *args])
            def __del__(self):
                libperl6.call_perl6('{callback_id(&delete_instance)}', [self.{perl6-object-mark}])					 
        PYTHON
    }    

    # to respond to the call of perl6 instance in python world
    sub call_instance(PyRef:D $py-args) {
	my $args = ObjectConverter.decode($py-args);
	my $object = Perl6Instance.pool.get($args[0]);
	ObjectConverter.encode($object(|$args[1..*-1]));
    }

    # to respond to the call of perl6 method in python world
    sub call_method(PyRef:D $py-args) {
	my $args = ObjectConverter.decode($py-args);
	my $object = Perl6Instance.pool.get($args[0]);
	my $name = $args[1];
	my $method = $object.^can($name)[0];
	if $method.arity > 0 {
	    ObjectConverter.encode($method.assuming($object));
	} else {
	    ObjectConverter.encode($object."$method"());
	}
    }

    # free the space occupied by the index of perl6 instance
    # note that all callbacks must not return a NULL, or the python interpreter
    # will get mad.
    sub delete_instance(PyRef:D $py-args) {
	my $args = ObjectConverter.decode($py-args);
	Perl6Instance.pool.free($args[0]);
	py_none
    }

    sub get-perl6-module-path {
	# Since the name of dynamic link library will be hashed after "zef install .",
	# I have to give the library a static name by creating a soft link.
	my $resource-id = %?RESOURCES<libraries/perl6>.Str;
	my $lib-path = do given $resource-id.IO {
	    $_.e ?? $_ !! $*VM.platform-library-name($_).IO;
	}
	
	$lib-path.e or die "library not exist: $lib-path.Str";
	
	my $tmp-path = $*VM.platform-library-name($*TMPDIR.add('perl6')).IO;
	$tmp-path.unlink;
	$lib-path.link($tmp-path);

	($*TMPDIR, $tmp-path.basename.IO.extension('', parts => 1..*))
    }
    
    my $.pool = ObjectPool.new;

    method level { PyCallable.level + 1 }
    
    multi method accept-py(PyRef:D $object) {
	py_object_has_attr_string($object, perl6-object-mark)
    }

    multi method accept-perl6(Any:D $object) {
	$object !~~ (Int | Str | Num | Rat | Positional | Map)
    }
    
    multi method from-py(PyRef:D $object) {
	$.pool.get: py_object_get_attr_string(
	    $object, perl6-object-mark
	) free-after { ObjectConverter.decode($^py-index); }
    }

    # Duplicate instance in pool !!!
    # Maybe we can add a mark in this object.
    # At present I allocate many the pool cells but free none.
    multi method to-py(Any:D $object) {
	my $module = py_import_addmodule('__main__');
	my $globals = py_module_getdict($module);
	my $locals = $globals;
	my $index = $.pool.keep($object);	
	
	py_run_string(
	    "{ perl6-object-class }({$index})",
	    py_mode_eval_input, $globals, $locals
	) modified-by -> $ { ObjectConverter.detect-exception }
    }
}

