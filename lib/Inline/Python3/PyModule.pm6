use Inline::Python3::ConverterService;
use Inline::Python3::PyObject;
use Inline::Python3::Config;
use Inline::Python3::Utilities;

class PyModule is PyObject {
    my %cache;
    
    method CALL-ME(Str:D $name) {
	%cache{$name} // do {
	    my $module = py_import($name);
	    $converter-serv.detect-exception;
	    %cache.append($name, PyModule.new(ref => $module));
	    %cache{$name}
	}
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

    method interpolate($code, *%mode) {
	my ($body, $perl6-vars, $python-vars) = transform-sigl($code);
	$perl6-vars.cache;
	my $values = $perl6-vars.map({ $converter-serv.encode(OUTERS::CALLERS::CALLERS::($^id)) });
	my $keys = $python-vars.map({ $converter-serv.encode($^id) });

	my $globals = py_module_getdict($.ref);	
	for (@$keys Z @$values) -> ($key, $value) {
	    py_dict_set_item($globals, $key, $value);
	}

	self.run($body, |%mode) modified-by {
	    for @$keys { py_dict_del_item($globals, $^key) }
	}
    }

    sub create-new-id($id) {
	'inline_perl6_id_' ~ $id;
    }
    
    sub transform-sigl($code) {
	my token id { <alpha> [ '-' * <alnum>] * }
	my token sigil  { '$' | '@' | '%' }

	$code ~~ m:g/ <sigil> <id> /;        
	my $perl6-vars = $/.map(~ *).unique;
	
	my $body = $code;
	$body ~~ s:g/ <sigil> <id> /{ create-new-id(~ $<id>) }/;
	my $python-vars = $/.map(~ *<id>).unique.map({ create-new-id $^id });

	$body, $perl6-vars, $python-vars
    }
    
    sub py_import_addmodule(Str --> PyRef) is capi('PyImport_AddModule') { ... }

    sub py_module_getdict(PyRef --> PyRef) is capi('PyModule_GetDict') { ... }

    sub py_import(Str --> PyRef) is capi('PyImport_ImportModule') { ... }

    sub py_mode_eval_input(--> int32) is capi { ... }

    sub py_mode_file_input(--> int32) is capi { ... }

    sub py_mode_single_input(--> int32) is capi { ... }

    sub py_dict_set_item(PyRef, PyRef, PyRef) is capi { ... }

    sub py_dict_del_item(PyRef, PyRef --> int32)
    is capi('PyDict_DelItem') { ... }
    
    sub py_run_string(Str, int32, PyRef, PyRef --> PyRef)
    is capi('PyRun_String') { ... }
}

sub prefix:<~\>\>> ($code) is export {
    PyModule('__main__').interpolate($code)
}

sub prefix:<~\>> ($code) is export {
    PyModule('__main__').interpolate($code, :eval)
}
