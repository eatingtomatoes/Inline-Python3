use Inline::Python3::Converter;
use Inline::Python3::ObjectConverter;
use Inline::Python3::Config;

class NoneConverter does Converter {
    method level { ObjectConverter.level + 1 }
    
    multi method accept-py(PyRef:D $_) {
	.&py_none_check
    }

    multi method accept-py(PyRef:U $_) { True }
    
    multi method accept-perl6($_) {
	not defined $_
    }
    
    multi method from-py($_) { Any }

    multi method to-py($_) { py_none }

    sub py_none_check(PyRef --> int32) is capi { ... }

    sub py_none(--> PyRef) is capi { ... }
}
