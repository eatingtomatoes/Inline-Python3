use Inline::Python3::Converter;
use Inline::Python3::PyObject;
use Inline::Python3::Perl6Converter;

class ProxyConverter does Converter {
    method level { Perl6Converter.level + 1 }

    multi method accept-perl6(PyObject:D $_) { True }

    multi method to-py($_) { .ref }
}
