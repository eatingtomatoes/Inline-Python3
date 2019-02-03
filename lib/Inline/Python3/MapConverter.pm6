use Inline::Python3::ConverterService;
use Inline::Python3::Converter;
use Inline::Python3::ObjectConverter;
use Inline::Python3::PyMap;
use Inline::Python3::Config;
use Inline::Python3::Utilities;

# The proxy class for has
class MapConverter does Converter {
    method level { ObjectConverter.level + 1 }
    
    multi method accept-py(PyRef:D $_) {
	.&py_mapping_check
    }

    multi method accept-perl6(Map:D $_) { True }
    
    multi method from-py($_) {
	PyMap.new(ref => $_)
    }

    multi method to-py($_) {
    	py_dict_new() modified-by -> $py-dict {
    	    for $_.kv -> $key, $value {
    		py_dict_set_item(
		    $py-dict,
		    $converter-serv.encode($key),
		    $converter-serv.encode($value)
		);
    	    }
    	}
    }

    sub py_mapping_check(PyRef --> int32) is capi { ... }

    sub py_dict_new(--> PyRef) is capi { ... }

    sub py_dict_set_item(PyRef, PyRef, PyRef) is capi { ... }
}
