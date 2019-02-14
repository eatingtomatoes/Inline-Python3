use Inline::Python3::ConverterService;
use Inline::Python3::PySequence;
use Inline::Python3::Config;
use Inline::Python3::PyTuple;

class PyNumpyArray is PySequence {
    method at(*@indices) {
	my @args = (@indices Z self.shape.list).map: -> ($_, $length) {
	    $_ ~~ Callable ?? $_($length) !! $_
	}
	self.__getitem__(PyTuple.new(@args));
    }

    method AT-POS($indices) {
	my @args = ($indices.list Z self.shape.list).map: -> ($_, $length) {
	    $_ ~~ Callable ?? $_($length) !! $_
	}
	self.__getitem__(PyTuple.new(@args));	
    }
}

multi postcircumfix:<[ ]> (PyNumpyArray:D $array, $indices) is export {
    $array.AT-POS($indices)
}
