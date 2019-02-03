use Inline::Python3::Converter;
use Inline::Python3::InstanceConverter;
use Inline::Python3::PyCallable;
use Inline::Python3::Config;

class CallableConverter does Converter {
    method level { InstanceConverter.level + 1 }

    multi method accept-py(PyRef:D $_) {
	.&py_callable_check
    }

    multi method from-py($_) {
	PyCallable.new(ref => $_)
    }

    sub py_callable_check(PyRef --> int32) is capi { ... }
}
