use Inline::Python3::ConverterService;
use Inline::Python3::CallbackService;
use Inline::Python3::Config;
use Inline::Python3::Utilities;

class PyObject {
    has $.ref;

    submethod BUILD(:$!ref) { self.inc-py-ref }
    
    method AT-KEY(Str:D  $name) {
	with self.get-py-attr($name) {
	    $_ free-after { $converter-serv.decode($^attr) }
	} else {
	    die "{self.perl} doesn't have attribute: {$name}"
	}
    }

    method FALLBACK(Str:D $name, |args) {
	given self.AT-KEY($name) {
	    when Callable { $_(|args) }
	    default { $_ }
	}
    }

    submethod DESTROY { self.dec-py-ref }

    method Str { $converter-serv.stringify($!ref) }

    method perl { self.Str }

    method get-py-attr(Str:D $name) {
	sub f(PyRef, Str --> PyRef) is capi('PyObject_GetAttrString') { ... }
	f($!ref, $name) modified-by { $converter-serv.detect-exception }
    }

    method has-py-attr(Str:D $name) {
	sub f(PyRef, Str --> int32) is capi('PyObject_HasAttrString') { ... }
	f($!ref, $name) modified-by { $converter-serv.detect-exception }
    }

    method inc-py-ref {
	sub py_inc_ref(PyRef) is capi { ... }
	py_inc_ref($!ref) 
    } 

    method dec-py-ref {
	sub py_dec_ref(PyRef) is capi  { ... }
	py_dec_ref($!ref) 
    }
}
