use Inline::Python3::Converter;
use Inline::Python3::ObjectConverter;
use Inline::Python3::PyInstance;
use Inline::Python3::Config;

class InstanceConverter does Converter {
    method level { ObjectConverter.level + 1 }
    
    multi method accept-py(PyRef:D $_) {
	.&py_instance_check
    }

    multi method from-py($_) {
	PyInstance.new(ref => $_)
    }

    sub py_instance_check(PyRef --> int32) is capi { ... }
}
