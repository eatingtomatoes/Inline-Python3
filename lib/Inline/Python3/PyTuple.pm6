class PyTuple {
    has @.array;

    method new(@array) { self.bless(:@array) }

    method perl { 'tuple: ' ~ @!array }

    method Str { 'tuple: ' ~ @!array.Str }

    method gist { 'tuple:' ~ @!array.gist }
}

sub circumfix:<??( )> (List:D $args) is export { PyTuple.new($args) }
