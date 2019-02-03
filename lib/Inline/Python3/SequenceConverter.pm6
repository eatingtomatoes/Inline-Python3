use Inline::Python3::ConverterService;
use Inline::Python3::Converter;
use Inline::Python3::ObjectConverter;
use Inline::Python3::PySequence;
use Inline::Python3::Utilities;
use Inline::Python3::Config;

# The proxy class for any sequence
class SequenceConverter does Converter {
    method level { ObjectConverter.level + 1 }
    
    multi method accept-py(PyRef:D $_) {
	.&py_sequence_check
    }

    multi method accept-perl6(Positional:D $_) { True }

    multi method from-py($_) {
	PySequence.new(ref => $_)
    }

    multi method to-py($_) {
    	py_list_new($_.elems) modified-by -> $py-array {
    	    for @$_.kv -> $i, $value {
    		py_list_set_item($py-array, $i, $converter-serv.encode($value));
    	    }
    	}	
    }

    sub py_unicode_check(PyRef --> int32) is capi { ... }
    
    sub py_sequence_check(PyRef --> int32) is capi { ... }

    sub py_sequence_length(PyRef --> int32) is capi { ... }

    sub py_sequence_get_item(PyRef, int32 --> PyRef) is capi { ... }

    sub py_list_new(int32 --> PyRef) is capi { ... }

    sub py_list_set_item(PyRef, int32, PyRef) is capi { ... }
}
