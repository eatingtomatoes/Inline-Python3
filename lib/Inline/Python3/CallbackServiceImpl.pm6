use NativeCall;
use Inline::Python3::CallbackService;
use Inline::Python3::ConverterService;
use Inline::Python3::Config;

class CallbackServiceImpl is CallbackService  {
    has %.callbacks = %();

    method BUILD {
	py_set_perl6_call_handle(&dispatch-callback);	
    }
    
    method register(Callable $callback) {
	my $name = self.id($callback);
	if not defined (%!callbacks{$name}) {
	    %!callbacks.push($name => $callback)
	} else {
	    die "error: callback $name has been registered!"
	}
    }

    # To guide the python call to the right perl6 callback
    sub dispatch-callback(Str $name, PyRef $args, Pointer $error --> PyRef) {
	CATCH {
	    default {
		my $message = $converter-serv.encode($_.gist);
		nativecast(CArray[Pointer], $error)[0] = $message;
	    }
	}

	with ($callback-serv.callbacks{$name}) { $_($args) }
	else { die "error: no such callback: $name" }
    }

    # The helper to calculate a perl6 callback's python name
    method id(Callable $callback) {
	$callback.gist ~~ /\&(\S+)/;
	~$0
    }

    sub py_set_perl6_call_handle(&handle (Str, PyRef, PyRef --> PyRef))
    is pymodule { ... }
}
