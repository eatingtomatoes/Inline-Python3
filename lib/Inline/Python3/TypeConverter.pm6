use Inline::Python3::Converter;
use Inline::Python3::CallableConverter;
use Inline::Python3::PyType;
use Inline::Python3::Config;

class TypeConverter does Converter {
    method level { CallableConverter.level + 1 }
    
    multi method accept-py(PyRef:D $_) {
	.&py_type_check
    }

    multi method from-py($object) {
	PyType.new(ref => $object)
    }

    sub py_type_check(PyRef --> int32) is capi { ... }
}
