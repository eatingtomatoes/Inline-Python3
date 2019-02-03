use Inline::Python3::Converter;
use Inline::Python3::SequenceConverter;
use Inline::Python3::Config;

class UnicodeConverter does Converter {
    method level { SequenceConverter.level + 1 }
    
    multi method accept-py(PyRef:D $_) {
	.&py_unicode_check
    }

    multi method accept-perl6(Str:D $_) { True }

    multi method from-py($_) {
	my $string = py_unicode_to_utf8($_);
	py_bytes_as_string($string);
    }

    multi method to-py($_) {
	py_str_to_py($_.encode('UTF-8').bytes, $_);	
    }

    sub py_unicode_to_utf8(PyRef --> PyRef) is capi { ... }

    sub py_bytes_as_string(PyRef --> Str) is capi { ... }

    sub py_unicode_check(PyRef --> int32) is capi { ... }

    sub py_str_to_py(int32, Str --> PyRef) is capi { ... }
}
