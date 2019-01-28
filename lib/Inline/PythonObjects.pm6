unit module PythonObjects;

use NativeCall;

use Inline::PythonObjects::PyInterface;
use Inline::PythonObjects::Utilities;
use Inline::PythonObjects::PythonException;
use Inline::PythonObjects::ObjectPool;


# Every python object proxy class must have their type registered in the 'type-center'.
# When a pyhton object comes from the python world, the static method from-py will go through
# the type-center and test which proxy class can decode the PyObject.
# The first who answer yes will be used to convert the python object into perl6 one.
# The order of testing depends on the levels of those proxy class. Higher level means higher precedence.

# Basic class for all the python object proxy.
class PyObject is export {
    INIT {
	my @.type-center = Array.new;
	py_init_python;
    }

    # Every object class must have a level, which is used to determine the class's
    # precedence of inspecting coming PyObject then converting it to perl6 proxy.
    # Default value is the base class's plus oen. Higher value means higher precedence.
    method level { self.^parents.elems }

    # To register the proxy class.
    # Sorting the sequence after every registration is quite inefficient, however I don't know how to
    # make it fast as well as keep the user code simple. 
    method register($type) {
	@.type-center.append($type);
	@.type-center.=sort(- *.level);
    }    

    # Can this proxy class decode the coming PyObject ? Default to no. 
    multi method accept-py($object --> Bool) { False }

    # Can this proxy class encode the perl6 object ? Default to no.
    multi method accept-perl6($object --> Bool) { False }    

    # The static method to decode a PyObject.
    # usage: my $py-object = ...
    #        my $perl6-object = PyObject.from-py($py-object)
    multi method from-py(PyRef $object) {
	for @.type-center -> $type {
	    if $type.accept-py($object) {
		$type.from-py($object).return
	    }
	}

	die "unknown python object: " ~ $object.perl;
    }

    # The static method to encode a perl6 object.
    # usage: my $perl6-object = ...
    #        my $py-object = PyObject.to-py($perl6-object)
    multi method to-py($object --> PyRef) {
	for @.type-center -> $type {
	    if $type.accept-perl6($object) {
		$type.to-py($object).return
	    }
	}
	
	die "unknown perl6 object: " ~ $object.perl;
    }

    # The static method to detect the exception raised in c code.
    # If there does exist one, the method will convert it into PythonException
    # and rethrow it.
    method detect-exception is hidden-from-backtrace {
	my @exception := CArray[Pointer].allocate(4);
	py_fetch_error(@exception);
	my $ex_type    = @exception[0];
	my $ex_message = @exception[3];

	if $ex_type {
	    my $message = PyObject.from-py($ex_message);
            @exception[$_] and py_dec_ref(@exception[$_]) for ^4;
	    my $object-str = py_object_str(@exception[2]);
	    PythonException.new(object => $message).throw
	}	
    }

    # The static method to dump the type-center and show which proxy class
    # can decode/encode the object.
    # It exists for debugging. 
    method who-accept-it($object, :$to-py, :$from-py) {
	@.type-center.map: do -> $type {
	    with $to-py { ($type, $type.accept-perl6($object)) }
	    orwith $from-py { ($type, $type.accept-py($object)) }
	    else { die 'to-py or from-py ?' }
	}
    }

    # The static method to convert a PyObject into a perl6 string.
    # It exists for debugging.
    method stringify(PyRef $object) {
	my $str = py_object_str($object);
	PyObject.from-py($str);
    }
}

# This class collects all perl6 callbacks and guides the python fucntion call to the right
# perl6 callback.
class CallbackCenter {
    INIT {
	my %.callbacks = Array.new;
	py_set_perl6_call_handle(&dispatch-callback);	
    }

    # To reegister the perl6 callback.
    # Python code will use the callback's perl6 name as its name in python environment,
    # so its name must be a valid pyhton identifier.
    method register(Callable $callback) {
	my $name = CallbackCenter.id($callback);
	if not defined (%.callbacks{$name}) {
	    %.callbacks.push($name => $callback)
	} else {
	    die "callback $name has been registered!"
	}
    }

    # To guide the python call to the right perl6 callback
    sub dispatch-callback(Str $name, PyRef $args, Pointer $error --> PyRef) {
	CATCH {
	    default {
		my $message = PyObject.to-py($_.gist);
		nativecast(CArray[Pointer], $error)[0] = $message;
	    }
	}
	
	with (CallbackCenter.callbacks{$name}) {
	    $_($args);
	} else {
	    die "no such callback: $name"
	}
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
    INIT { $?CLASS.register($?CLASS) }

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
    INIT { $?CLASS.register($?CLASS) }
}

# The proxy class for integer
class PyInteger is PyAtomic is export {
    INIT { $?CLASS.register($?CLASS) }

    multi method accept-py(PyRef:D $object) {
	py_int_check($object);
    }

    multi method accept-perl6(Int $object) { True }
    
    multi method from-py(PyRef:D $object) {
	py_int_from_py($object)
    }

    multi method to-py(Int $object) {
	py_int_to_py($object)
    }
}

# The basic proxy for real number
class PyFloat is PyAtomic is export {
    INIT { $?CLASS.register($?CLASS) }

    multi method accept-py(PyRef:D $object) {
	py_float_check($object);
    }
    
    multi method accept-perl6(Num $object) { True }

    multi method accept-perl6(Rat $object) { True }    
    
    multi method from-py(PyRef:D $object) {
	py_float_from_py($object)
    }

    multi method to-py(Num $object) {
	py_float_to_py($object)
    }

    multi method to-py(Rat $object) {
	py_float_to_py($object.Num)
    }
}

# The proxy class for any sequence
class PySequence is PyAtomic is export {
    INIT { $?CLASS.register($?CLASS) }

    multi method accept-py(PyRef:D $object) {
	py_sequence_check($object)
    }

    multi method accept-perl6(Positional $object) { True }

    # Caution: PySequence treats the unit of unicode as a PySequence,
    # so without PyUnicode registered, using PySequence to decode
    # a unicode string will cause infinite recursion !!!
    multi method from-py(PyRef:D $object) {
    	my @array;
    	for 0..^py_sequence_length($object) -> $i {
    	    py_sequence_get_item($object, $i) temporarily -> $item {
    		@array[$i] = PyObject.from-py($item);
    	    }
    	}
    	@array	
    }

    multi method to-py(Positional $object) {
    	py_list_new($object.elems) modified-by -> $py-array {
    	    for @$object.kv -> $i, $value {
    		py_list_set_item($py-array, $i, PyObject.to-py($value));
    	    }
    	}	
    }    
}

# The proxy class for has
class PyMap is PyAtomic is export {
    INIT { $?CLASS.register($?CLASS) }

    multi method accept-py(PyRef:D $object) {
	py_mapping_check($object)
    }

    multi method accept-perl6(Map $object) { True }
    
    multi method from-py(PyRef:D $object) {
    	my %hash;
    	py_mapping_items($object) temporarily -> $sequence {	
    	    for PyObject.from-py($sequence) -> $item {
    		%hash{$item[0]} = $item[1]
    	    }
    	}
    	%hash
    }

    multi method to-py(Map $object) {
    	py_dict_new() modified-by -> $py-dict {
    	    for $object.kv -> $key, $value {
    		py_dict_set_item(
		    $py-dict, PyObject.to-py($key), PyObject.to-py($value)
		);
    	    }
    	}
    }        
}

# The proxy class for byte string python.
# As there exist two sorts of string type in python: bytes and unicode,
# I have to create two proxy classes for decode them.
class PyBytesString is PySequence is export {
    INIT { $?CLASS.register($?CLASS) }

    multi method accept-py(PyRef:D $object) {
	py_bytes_check($object)
    }
    
    multi method from-py(PyRef:D $object) {
	py_bytes_as_string($object).clone
    }

}

# The proxy class for unicode in python.
class PyUnicodeString is PySequence is export {
    INIT { $?CLASS.register($?CLASS) }

    multi method accept-py(PyRef:D $object) {
	py_unicode_check($object)
    }

    multi method accept-perl6(Str $object) { True }

    multi method from-py(PyRef:D $object) {
	my $string = py_unicode_to_utf8($object) or return;
	my $p6_str = py_bytes_as_string($string);
	py_dec_ref($string);
	$p6_str;	
    }

    multi method to-py(Str $object) {
	py_str_to_py($object.encode('UTF-8').bytes, $object);	
    }    
}

# The proxy for python tuple.
# As python's functions pass parameter in tuple,
# I have to create a proxy type to decode/encode functions' parameters.
class PyTuple is PySequence is export {
    INIT { $?CLASS.register($?CLASS) }

    has @.array;
    method new(@array) { self.bless(:@array) }
    
    multi method accept-perl6(PyTuple $object) { True }

    multi method to-py(PyTuple $object) {
    	py_tuple_new($object.array.elems) modified-by -> $py-tuple {
    	    for $object.array.kv -> $i, $value {
    		py_tuple_set_item($py-tuple, $i, PyObject.to-py($value))
    	    }
    	}	
    }        
}

# The proxy class for all non-atomic types. 
# It's name is bad, as it not only decodes instance object, but also does class obejct.
# This proxy class will guide attribute access/method call to their python object,
# so the use can use the pyhton object like pyhton code, e.g. Foo().get_name .
class PyInstance is PyObject is export {
    INIT { $?CLASS.register($?CLASS) }

    has $.ref;

    multi method accept-py(PyRef:D $object) {
	py_instance_check($object)
    }
    
    multi method accept-perl6(PyInstance $object) { True }
    
    multi method from-py(PyRef:D $object) {
	PyInstance.new(ref => $object)
    }

    multi method to-py(PyInstance $object) {
	$object.ref
    }

    # circular dependency ?
    # to passs the method call to the python object
    method FALLBACK($name, |args) {
	with py_object_get_attr_string($.ref, $name) {
	    if py_type_check($_) {
		# It's a little complex.
		# if the $_ is a class object, e.g. Foo, I cannot figure out if 
		# it's instantiating a python class(e.g. Foo()) or accessing a
		# static attribute/method, e.g. Foo.some_static_method.
		# So I decide to delay the decision to PyClass proxy. (then circular dependency???)
		my $object = PyObject.from-py($_);
		args.Bool ?? $object(|args) !! $object;
	    } else {
		PyObject.from-py: do {
		    if py_callable_check($_) {
			self.call-py-object($_, |args)
		    } else {
			$_
		    }
		}
	    }
	} else {
	    py_raise_missing_method($.ref, $name)
	}
    }

    method call-py-object(PyRef $object, |args --> PyRef) {
	my $py-args = PyObject.to-py(PyTuple.new(args.list));
	my $py-kwargs = PyObject.to-py(args.hash);
	my $result = py_object_call($object, $py-args, $py-kwargs);
	self.detect-exception;
	$result
    }
}

# The proxy for python module
# It derivatives from PyInstance, so you can use it like python code,
# e.g.
#     my $main PyModule('__main__');
#        $main.print(1,3,4,5)
#
#    PyModule('string', :import).digits
#
class PyModule is PyInstance is export {
    INIT { $?CLASS.register($?CLASS) }

    multi method accept-py(PyRef:D $object) {
	py_module_check($object)
    }
    
    multi method from-py(PyRef:D $object) {
	PyModule.new(ref => $object)
    }

    # To access a module namespace.
    # It will not import the module if you don't specify the keyword :import. 
    # Note that the '__main__' module doesn't need the keyword.
    method CALL-ME(Str $name, :$import) {
	# my $module = py_import_addmodule($name);
	my $module = do {
	    with $import {
		py_import($name) // die "failed to import the module: $name"
	    } else {
		py_import_addmodule($name);		
	    }
	}
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
	
	my $result = py_run_string(
	    $code, $mode, $globals, $locals
	);
	self.detect-exception;
	PyObject.from-py($result)
    }
}

# The proxy class for callable
# Note that besides functions and methods, class objects are also callable.
class PyCallable is PyInstance is export {
    INIT { $?CLASS.register($?CLASS) }

    multi method accept-py(PyRef:D $object) {
	py_callable_check($object)
    }
    
    multi method from-py(PyRef:D $object) {
	PyCallable.new(ref => $object)
    }

    method CALL-ME(|args) {
	my $result = self.call-py-object($.ref, |args);
	PyObject.from-py($result);
    }
}

# The proxy class for class object, e.g. type(SomeClass)
class PyType is PyCallable {
    INIT { $?CLASS.register($?CLASS) }

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
	# py_init_perl6;

	Perl6Instance.register($?CLASS);

	CallbackCenter.register(&call_instance);
	CallbackCenter.register(&call_method);
	
	PyModule('__main__').run(qq:to/PYTHON/);
	import sys
	sys.path.append('{%?RESOURCES<libraries>.Str}')
	import libperl6
	class {perl6-object-class}(object):
	    def __init__(self, index):
                self.{perl6-object-mark} = index
            def __getattr__(self, name):
                print("getattribute was called with " + name)
                return libperl6.call_perl6('{callback_id(&call_method)}', [self.{perl6-object-mark}, name])
            def __call__(self, *args):
                print('perl6 object called!!!!')
                return libperl6.call_perl6('{callback_id(&call_instance)}', [self.{perl6-object-mark}, *args])
	PYTHON

    }    

    # to respond to the call of perl6 instance in python world
    sub call_instance(PyRef $py-args) {
	my $args = PyObject.from-py($py-args);
	my $object = Perl6Instance.pool.get($args[0]);
	PyObject.to-py($object(|$args[1..*-1]));
    }

    # to respond to the call of perl6 method in python world
    sub call_method(PyRef $py-args) {
	my $args = PyObject.from-py($py-args);
	my $object = Perl6Instance.pool.get($args[0]);
	my $name = $args[1];
	my $method = $object.^can($name)[0];
	if $method.arity > 0 {
	    PyObject.to-py($method.assuming($object));
	} else {
	    PyObject.to-py($object."$method"());
	}
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
	my $py-index = py_object_get_attr_string(
	    $object, perl6-object-mark
	);
	my $index = PyObject.from-py($py-index);
	$.pool.get($index)
    }

    # Duplicate instance in pool !!!
    # Maybe we can add a mark in this object.
    # At present I allocate many the pool cells but free none.
    multi method to-py(Any:D $object) {
	my $index = $.pool.keep($object);

	my $module = py_import_addmodule('__main__');
	my $globals = py_module_getdict($module);
	my $locals = $globals;
	my $result = py_run_string(
	    "{ perl6-object-class }({$index})",
	    py_mode_eval_input, $globals, $locals
	);
	self.detect-exception;
	$result
    }
}

