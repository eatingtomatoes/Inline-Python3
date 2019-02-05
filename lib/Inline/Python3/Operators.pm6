sub prefix:<~&~> (Str $code) is export {
    PyModule('__main__').run($code)
}

sub prefix:<~&> (Str $code) is export {
    PyModule('__main__').run($code, :eval)
}

# discard values
sub prefix:<~&~!>(Str $) is export {}
