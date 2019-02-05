unit module Interpolation;

use Inline::Python3::PyModule;

# to execute python code of multiple lines;
sub prefix:<~&~> (Str $code) is export {
    PyModule('__main__').run($code)
}

# to evaluate python expression;
sub prefix:<~&> (Str $code) is export {
    PyModule('__main__').run($code, :eval)
}

# to discard code string
sub prefix:<~&~!>(Str $) is export {}

sub remove-sigl($expr) {
    my $copy = $expr;
    $copy ~~ s:g/ '$' | '@' | '%' //;
    $copy
}

sub prefix:< ~\> > (Str:D $expr) is export {    
    my token id { '$' <alnum> + }
    $expr ~~ m:g/<id>/;
    my $vars = $/.map(~ *).unique.cache;
    my $new-expr = remove-sigl("lambda { $vars.join(',') }: $expr");
    my $args = $vars.map({ OUTER::CALLERS::($^id) });
    PyModule('__main__').run($new-expr, :eval)(|$args);
}
