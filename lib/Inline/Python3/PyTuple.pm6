class PyTuple {
    has @.array;
    method new(@array) { self.bless(:@array) }
}
