use Inline::Python3::Config;

class ConverterService {
    method register($type) { ... }

    method decode(PyRef $object) { ... }

    method encode($object --> PyRef) { ... }

    method who-accept-it($object, :$encode, :$decode) { ... }

    method stringify(PyRef:D $object) { ... }
    
    method detect-exception { ... }
}

our $converter-serv;
