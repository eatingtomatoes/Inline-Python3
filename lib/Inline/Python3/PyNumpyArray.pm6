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
}

