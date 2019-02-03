use Inline::Python3::PyObject;
use Inline::Python3::Config;

class PyPerl6 is PyObject {
    constant perl6-object-class = "Perl6Object";
    constant perl6-object-mark = "__perl6_object_index__";

    submethod init {
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
	my $args = $converter-center.decode($py-args);
	my $object = Perl6Instance.pool.get($args[0]);
	$converter-center.encode($object(|$args[1..*-1]));
    }

    # to respond to the call of perl6 method in python world
    sub call_method(PyRef:D $py-args) {
	my $args = $converter-center.decode($py-args);
	my $object = Perl6Instance.pool.get($args[0]);
	my $name = $args[1];
	my $method = $object.^can($name)[0];
	if $method.arity > 0 {
	    $converter-center.encode($method.assuming($object));
	} else {
	    $converter-center.encode($object."$method"());
	}
    }

    # free the space occupied by the index of perl6 instance
    # note that all callbacks must not return a NULL, or the python interpreter
    # will get mad.
    sub delete_instance(PyRef:D $py-args) {
	my $args = $converter-center.decode($py-args);
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
	) free-after { $converter-center.decode($^py-index); }
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

