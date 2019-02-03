use Inline::Python3::ConverterService;
use Inline::Python3::CallbackService;
use Inline::Python3::Config;
use Inline::Python3::Utilities;

class PyObject {
    has $.ref;

    submethod BUILD(:$!ref) {
	py_inc_ref($!ref);
    }
    
    method AT-KEY(Str:D  $name) {
	# new reference
	with py_object_get_attr_string($!ref, $name) {
	    $converter-serv.detect-exception;
	    $_ free-after { $converter-serv.decode($^attr) }
	} else {
	    py_raise_missing_method($!ref, $name)
	}
    }

    method FALLBACK(Str:D $name, |args) {
	given self.AT-KEY($name) {
	    when Callable { $_(|args) }
	    default { $_ }
	}
    }

    submethod DESTROY {
	$!ref andthen py_dec_ref($_)
    }

    sub py_object_get_attr_string(PyRef, Str --> PyRef)
    is capi('PyObject_GetAttrString') { ... }

    sub py_dec_ref(PyRef) is capi  { ... }

    sub py_inc_ref(PyRef) is capi { ... }

    sub py_raise_missing_func(Str) is capi { ... }

    sub py_raise_missing_method(PyRef, Str) is capi { ... }
}
