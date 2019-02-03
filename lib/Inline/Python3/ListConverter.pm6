use Inline::Python3::Converter;
use Inline::Python3::SequenceConverter;
use Inline::Python3::Config;
use Inline::Python3::PyList;

class ListConverter does Converter {
    method level { SequenceConverter.level + 1 }

    # method accept-py($_) {
    # 	.defined && py_list_check($_)
    # }

    # method from-py($_) {
    # 	PyList.new(ref => $_)
    # }

    sub py_list_check(PyRef --> int32) is capi { ... }
}
