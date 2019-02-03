use Inline::Python3::Converter;
use Inline::Python3::ObjectConverter;
use Inline::Python3::Config;

class IntegerConverter does Converter {
    method level { ObjectConverter.level + 1 }
    
    multi method accept-py(PyRef:D $_) {
	.&py_int_check
    }

    multi method accept-perl6(Int:D $_) { True }
    
    multi method from-py($_) {
	py_int_from_py($_)	
    }

    multi method to-py($_) {
	py_int_to_py($_)
    }

    sub py_int_from_py(PyRef --> int32) is capi { ... }
    
    sub py_int_check(PyRef --> int32) is capi { ... }

    sub py_int_to_py(int32 --> PyRef) is capi  { ... }
}
