unit module Interpolation;

use Inline::Python3::PyModule;

sub create-new-id($id) {
    'inline_perl6_id_' ~ $id    
}

sub create-new-func {
    state $count = 0;
    'inline_perl6_func_' ~ $count++
}
sub transform-sigl($code) {
    my token id { <alpha> [ '-' * <alnum>] * }
    my token sigil  { '$' | '@' | '%' }

    $code ~~ m:g/ <sigil> <id> /;        
    my $perl6-vars = $/.map(~ *).unique;
    
    my $body = $code;
    $body ~~ s:g/ <sigil> <id> /{ create-new-id(~ $<id>) }/;
    my $python-vars = $/.map(~ *<id>).unique.map({ create-new-id $^id });

    $body, $perl6-vars, $python-vars
}

sub prefix:<~\>\>> ($code) is export {
    state $count = 0;
    my ($body, $ids, $new-ids) = transform-sigl($code);
    my $func-name = create-new-func;
    PyModule('__main__').run(qq:to/end/);
    def $func-name ({$new-ids.join(',')}):
        { $body.subst("\n", "\n    ", :g) }
    end
    my $args = $ids.map({ OUTER::CALLERS::($^id) });
    PyModule('__main__'){$func-name}(|$args);
}

sub prefix:< ~\> > ($code) is export {
    my ($body, $ids, $new-ids) = transform-sigl($code);
    my $lambda = "lambda {$new-ids.join(',')}: $body";
    my $args = $ids.map({ OUTER::CALLERS::($^id) });
    PyModule('__main__').run($lambda, :eval)(|$args);
}

sub prefix:<~&~>($code) is export {
    PyModule('__main__').run($code)
}
