use Inline::Python3::ConverterService;
use Inline::Python3::PyInstance;
use Inline::Python3::PyTuple;
use Inline::Python3::Config;
use Inline::Python3::Utilities;

class PyCallable is PyInstance does Callable {
    method CALL-ME(|args) {
	my $py-args = $converter-serv.encode(PyTuple.new(args.list));
	my $py-kwargs = $converter-serv.encode(args.hash);
	py_object_call($.ref, $py-args, $py-kwargs) free-after {
	    $converter-serv.detect-exception;
	    $converter-serv.decode($^result)
	}	
    }

    sub py_object_call(PyRef, PyRef, PyRef --> PyRef)
    is capi('PyObject_Call') { ... }
}
