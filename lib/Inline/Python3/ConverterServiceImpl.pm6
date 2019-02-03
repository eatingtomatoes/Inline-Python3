use NativeCall;
use Inline::Python3::ConverterService;
use Inline::Python3::Utilities;
use Inline::Python3::PythonException;
use Inline::Python3::Config;

class ConverterServiceImpl is ConverterService {
    has @!converters = Array.new;
	
    # To register the proxy class.
    # Sorting the sequence after every registration is quite inefficient, however I don't know how to
    # make it fast as well as keep the user code simple. 
    method register($converter) {
	@!converters.append($converter);
	@!converters.=sort(- *.level);	
    }    

    # The static method to decode a PyObject into perl6 object.
    # usage: my $py-object = ...
    #        my $perl6-object = ObjectConverter.decode($py-object)
    # Note that all $object passed in are borrowed reference.    
    method decode(PyRef $object) {
	for @!converters -> $converter {
	    if $converter.accept-py($object) {
		$converter.from-py($object).return
	    }
	}

	die "error: unknown python object: " ~ $object.perl;
    }

    # The static method to encode a perl6 object into PyObject.
    # usage: my $perl6-object = ...
    #        my $py-object = ObjectConverter.encode($perl6-object)
    method encode($object --> PyRef) {
	for @!converters -> $converter {
	    if $converter.accept-perl6($object) {
		$converter.to-py($object).return
	    }
	}
	
	die "unknown perl6 object: " ~ $object.perl;
    }

    # The static method to dump the type-center and show which proxy class
    # can decode/encode the object.
    # It exists for debugging. 
    method who-accept-it($object, :$encode, :$decode) {
	@!converters.map: do -> $converter {
	    say 'now to test: ' ~ $converter.perl;
	    with $encode { ($converter, $converter.accept-perl6($object)) }
	    orwith $decode { ($converter, $converter.accept-py($object)) }
	    else { die 'encode or decode ?' }
	}
    }

    # The static method to convert a PyObject into a perl6 string.
    # It exists for debugging.
    method stringify(PyRef:D $object) {
	py_object_str($object) free-after {
	    my $string = py_unicode_to_utf8($_);
	    py_bytes_as_string($string);
	}
    }
    
    # The static method to detect the exception raised in c code.
    # If there does exist one, the method will convert it into PythonException
    # and rethrow it.
    method detect-exception {
	my @exception := CArray[Pointer].allocate(4);
	py_fetch_error(@exception);
	my $ex-type = @exception[0];

	if $ex-type {
	    my $ex-name = self.stringify($ex-type);
	    my $ex-message = self.stringify(@exception[3]); 
            @exception[$_] and py_dec_ref(@exception[$_]) for ^4;
	    PythonException.new(message => "$ex-name $ex-message").throw
	}	
    }

    sub py_unicode_to_utf8(PyRef --> PyRef) is capi { ... }

    sub py_bytes_as_string(PyRef --> Str) is capi { ... }

    sub py_dec_ref(PyRef) is capi { ... }

    sub py_fetch_error(CArray[PyRef]) is capi { ... }

    sub py_object_str(PyRef --> PyRef) is capi('PyObject_Str') { ... }
}

 
