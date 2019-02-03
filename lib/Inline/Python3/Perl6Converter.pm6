use Inline::Python3::ConverterService;
use Inline::Python3::CallbackService;
use Inline::Python3::Converter;
use Inline::Python3::ObjectConverter;
use Inline::Python3::CallableConverter;
use Inline::Python3::PyModule;
use Inline::Python3::Config;
use Inline::Python3::ObjectPool;
use Inline::Python3::Utilities;

sub callback_id($object) {
    $callback-serv.id($object)
}

class Perl6Converter does Converter {
    constant perl6-object-class = "Perl6Object";
    constant perl6-object-mark = "__perl6_object_index__";

    method init {
	$converter-serv.register(self);
	$callback-serv.register(&call_instance);
	$callback-serv.register(&call_method);
	$callback-serv.register(&delete_instance);
	
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
	my $args = $converter-serv.decode($py-args);
	my $object = Perl6Converter.pool.get($args[0]);
	$converter-serv.encode($object(|$args[1..*-1]));
    }

    # to respond to the call of perl6 method in python world
    sub call_method(PyRef:D $py-args) {
	my $args = $converter-serv.decode($py-args);
	my $object = Perl6Converter.pool.get($args[0]);
	say 'in call_method: => ' ~ $args.perl;
	my $name = $args[1];
	my $method = $object.^can($name)[0];
	if $method.arity > 0 {
	    $converter-serv.encode($method.assuming($object));
	} else {
	    $converter-serv.encode($object."$method"());
	}
    }

    # free the space occupied by the index of perl6 instance
    # note that all callbacks must not return a NULL, or the python interpreter
    # will get mad.
    sub delete_instance(PyRef:D $py-args) {
	my $args = $converter-serv.decode($py-args);
	Perl6Converter.pool.free($args[0]);
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

    method level { CallableConverter.level + 1 }
    
    multi method accept-py(PyRef:D $_) {
	py_object_has_attr_string($_, perl6-object-mark)
    }

    multi method accept-perl6($_) {
	.&defined && ($_ !~~ (Int | Str | Num | Rat | Positional | Map | PyRef))
    }
    
    multi method from-py($_) {
	$.pool.get: py_object_get_attr_string(
	    $_, perl6-object-mark
	) free-after { $converter-serv.decode($^py-index); }
    }

    multi method to-py($object) {
	my $module = py_import_addmodule('__main__');
	my $globals = py_module_getdict($module);
	my $locals = $globals;
	my $index = $.pool.keep($object);	
	
	py_run_string(
	    "{ perl6-object-class }({$index})",
	    py_mode_eval_input, $globals, $locals
	) modified-by -> $ { $converter-serv.detect-exception }
    }

    sub py_run_string(Str, int32, PyRef, PyRef --> PyRef)
    is capi('PyRun_String') { ... }

    sub py_mode_eval_input(--> int32) is capi { ... }

    sub py_import_addmodule(Str --> PyRef) is capi('PyImport_AddModule') { ... }

    sub py_module_getdict(PyRef --> PyRef) is capi('PyModule_GetDict') { ... }

    sub py_object_get_attr_string(PyRef, Str --> PyRef)
    is capi('PyObject_GetAttrString') { ... }

    sub py_object_has_attr_string(PyRef, Str --> int32)
    is capi('PyObject_HasAttrString') { ... }

    sub py_none of PyRef is capi { ... }
}

