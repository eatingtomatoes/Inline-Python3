use Inline::Python3::ConverterService;

role Converter {
    method init { $converter-serv.register(self) }    
    
    method level { ... }

    multi method accept-py($object) { False }

    multi method accept-perl6($object) { False }

    multi method from-py($object)  { die "unimplement role method" }

    multi method to-py($object) { die "unimplement role method" }
}
