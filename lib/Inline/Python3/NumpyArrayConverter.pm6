use Inline::Python3::ConverterService;
use Inline::Python3::Converter;
use Inline::Python3::SequenceConverter;
use Inline::Python3::PyNumpyArray;
use Inline::Python3::Utilities;
use Inline::Python3::Config;

class NumpyArrayConverter does Converter {
    method level { SequenceConverter.level + 1 }
    
    multi method accept-py(PyRef:D $_) {
	.&py_sequence_check && .&py_object_has_attr_str('shape')
    }

    multi method from-py($_) {
	PyNumpyArray.new(ref => $_)
    }

    sub py_object_has_attr_str(PyRef, Str --> int32)
    is capi('PyObject_HasAttrString') { ... }

    sub py_sequence_check(PyRef --> int32) is capi { ... }    
}
