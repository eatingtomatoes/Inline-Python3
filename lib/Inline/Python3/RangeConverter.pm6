use Inline::Python3::ConverterService;
use Inline::Python3::Converter;
use Inline::Python3::SequenceConverter;
use Inline::Python3::PySequence;
use Inline::Python3::Utilities;
use Inline::Python3::Config;

# The proxy class for any sequence
class RangeConverter does Converter {
    method level { SequenceConverter.level + 1 }

    multi method accept-perl6(Range:D $_) { True }

    multi method to-py($_) {
	my $bounds = do given .bounds -> ($start, $end) {
	    .excludes-min ?? ($start + 1) !! $start,
	    .excludes-max ?? $end !! ($end + 1)
	}
	py_slice_new(
	    |$bounds.map({$converter-serv.encode($^x)}), py_none
	) modified-by { $converter-serv.detect-exception }
    }

    sub py_slice_new(PyRef, PyRef, PyRef --> PyRef)
    is capi('PySlice_New') { ... }

    sub py_none of PyRef is capi { ... }
}

