class PythonException is Exception {
    has $.object;

    method message {
	given $.object {
	    when Str { $.object }
	    default { 'mysterious exception from the python world' }
	}
    }

    method reset-object($object) {
	$!object = $object
    }
}
