use Inline::Python3::ConverterService;
use Inline::Python3::PyObject;
use Inline::Python3::Config;

class PySequence is PyObject does Positional does Iterable {
    method elems { py_sequence_length($.ref) }

    method AT-POS($pos) {
	$converter-serv.decode(py_sequence_get_item($.ref, $pos))
    }

    method EXISTS-POS($pos) { $pos < self.elems }

    class SequenceIterator does Iterator {
	has $.sequence;
	has $.index;

	method pull-one {
	    given $!index {
		$_ < $.sequence.elems ?? $!sequence[$_++] !! IterationEnd;
	    }
	}
    }

    method iterator {
	SequenceIterator.new(
	    sequence => self,
	    index => 0
	)
    }

    method list { ($_ for self) }
    
    sub py_sequence_length(PyRef --> int32) is capi { ... }

    sub py_sequence_get_item(PyRef, int32 --> PyRef) is capi { ... }
}
