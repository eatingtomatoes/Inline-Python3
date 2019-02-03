use Inline::Python3::ConverterService;
use Inline::Python3::Converter;
use Inline::Python3::PyTuple;
use Inline::Python3::Config;
use Inline::Python3::Utilities;

class TupleConverter does Converter {
    method level { 100 }

    multi method accept-py($_) { False }
    
    multi method accept-perl6($_) {
	.defined && ($_ ~~ PyTuple);
    }

    multi method from-py($_) { ... }
    
    multi method to-py($_) {
    	py_tuple_new($_.array.elems) modified-by -> $py-tuple {
    	    for $_.array.kv -> $i, $value {
    		py_tuple_set_item($py-tuple, $i, $converter-serv.encode($value))
    	    }
    	}	
    }

    sub py_tuple_new(int32 --> PyRef) is capi { ... }

    sub py_tuple_set_item(PyRef, int32, PyRef) is capi { ... }
}
