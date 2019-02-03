use Inline::Python3::ConverterService;
use Inline::Python3::PyObject;
use Inline::Python3::Config;
use Inline::Python3::Utilities;

class PyMap is PyObject does Iterable does Associative {
    method AT-KEY(Str:D $key) {
	if self.EXISTS-KEY($key) {
	    $converter-serv.decode(
		py_mapping_get_item_string($.ref, $key)
	    )
	} 
    }

    method EXISTS-KEY(Str:D $key) {
	py_mapping_has_key_string($.ref, $key)
    }	

    class MapIterator does Iterator {
	has $.sequence;
	has $.seq-iter;

	method pull-one {
	    my $list := $!seq-iter.pull-one;
	    if $list =:= IterationEnd {
		IterationEnd
	    } else {
		Pair.new($list[0], $list[1])
	    }
	}
    }

    method iterator {
	my $seq = $converter-serv.decode(py_mapping_items($.ref));
	MapIterator.new(
	    sequence => $seq,
	    seq-iter => $seq.iterator
	)
    }

    method Hash {
	my %hash;
    	py_mapping_items($.ref) free-after -> $sequence {	
    	    for $converter-serv.decode($sequence) -> $item {
    		%hash{$item[0]} = $item[1]
    	    }
    	}
    	%hash	
    }

    method perl {
	self.Hash.perl
    }

    method Str {
	self.Hash.Str
    }
    
    sub py_mapping_get_item_string(PyRef, Str --> PyRef)
    is capi('PyMapping_GetItemString') { ... }
    
    sub py_mapping_has_key_string(PyRef, Str --> int32) 
    is capi('PyMapping_HasKeyString') { ... }

    sub py_mapping_items(PyRef --> PyRef) is capi { ... }
    
}
