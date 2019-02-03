use Inline::Python3::Converter;
use Inline::Python3::ObjectConverter;
use Inline::Python3::PyModule;
use Inline::Python3::Config;

class ModuleConverter does Converter {
    method level { ObjectConverter.level + 1 }
    
    multi method accept-py(PyRef:D $_) {
	.&py_module_check
    }

    multi method from-py($_) {
	PyModule.new(ref => $_)
    }

    sub py_module_check(PyRef --> int32) is capi { ... }
}
