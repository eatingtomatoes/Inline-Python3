use Inline::Python3::Converter;
use Inline::Python3::ObjectConverter;
use Inline::Python3::Config;

class FloatConverter does Converter {
    method level { ObjectConverter.level + 1 }
    
    multi method accept-py(PyRef:D $_) {
	.&py_float_check
    }
    
    multi method accept-perl6($_) {
	$_ ~~ (Num:D | Rat:D)
    }

    multi method from-py($_) {
	py_float_from_py($_)	
    }

    multi method to-py($_) {
	given $_ {
	    when Num { py_float_to_py($_) }
	    when Rat { py_float_to_py($_.Num) }
	}
    }

    sub py_float_from_py(PyRef --> num64) is capi { ... }    
    
    sub py_float_check(PyRef --> int32) is capi { ... }

    sub py_float_to_py(num64 --> PyRef) is capi { ... }
}

