use Inline::Python3::Converter;
use Inline::Python3::SequenceConverter;
use Inline::Python3::Config;

class BytesConverter does Converter {
    method level { SequenceConverter.level + 1 }
    
    multi method accept-py(PyRef:D $_) {
	.&py_bytes_check
    }

    multi method from-py($_) {
	py_bytes_as_string($.ref);	
    }

    multi method to-py($_) { ... }

    sub py_bytes_check(PyRef --> int32) is capi { ... }

    sub py_bytes_as_string(PyRef --> Str) is capi { ... }        
}
