use Inline::Python3::ConverterService;
use Inline::Python3::PyObject;
use Inline::Python3::Config;
use Inline::Python3::Utilities;

class PyModule is PyObject {
    method CALL-ME(Str $name) {
	my $module = py_import($name);
	$converter-serv.detect-exception;
	PyModule.new(ref => $module)
    }

    method run($code, :$single, :$eval, :$file) {
	my $globals = py_module_getdict($.ref);
	my $locals = $globals;

	my $mode = do {
	    with $single { py_mode_single_input }
	    orwith $eval { py_mode_eval_input }
	    else { py_mode_file_input }
	}
	
	py_run_string($code, $mode, $globals, $locals) free-after {
	    $converter-serv.detect-exception;
	    $converter-serv.decode($^result)
	}
    }
    
    sub py_import_addmodule(Str --> PyRef) is capi('PyImport_AddModule') { ... }

    sub py_module_getdict(PyRef --> PyRef) is capi('PyModule_GetDict') { ... }

    sub py_import(Str --> PyRef) is capi('PyImport_ImportModule') { ... }

    sub py_mode_eval_input(--> int32) is capi { ... }

    sub py_mode_file_input(--> int32) is capi { ... }

    sub py_mode_single_input(--> int32) is capi { ... }

    sub py_run_string(Str, int32, PyRef, PyRef --> PyRef)
    is capi('PyRun_String')
    { ... }
}

