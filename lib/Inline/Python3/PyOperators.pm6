unit module PyOperators;

use Inline::Python3::PyModule;

sub apply_unary_operation($operator, $x) is export {
    PyModule('__main__').run("lambda x:$operator x", :eval)($x)    
}

sub apply_binary_operation($operator, $x, $y) is export {
    PyModule('__main__').run("lambda x, y: x $operator y", :eval)($x, $y)
}

# Nearly All unary operators start with `??` while all binary ones start with `?`,
# except `|`, `^`, `//` are binary operators but start with ??.
our &infix:<?**> is export = &apply_binary_operation.assuming('**');

our &prefix:<??~> is export = &apply_unary_operation.assuming('~');
our &prefix:<??+> is export = &apply_unary_operation.assuming('+');
our &prefix:<??-> is export = &apply_unary_operation.assuming('-');

our &infix:<?*> is export = &apply_binary_operation.assuming('*');
our &infix:<?/> is export = &apply_binary_operation.assuming('/');
our &infix:<?%> is export = &apply_binary_operation.assuming('%');
our &infix:<??//> is export = &apply_binary_operation.assuming('//');

our &infix:<?+> is export = &apply_binary_operation.assuming('+');
our &infix:<?-> is export = &apply_binary_operation.assuming('-');

our &infix:<?\>\>> is export = &apply_binary_operation.assuming('>>');
our &infix:<?\<\<> is export = &apply_binary_operation.assuming('<<');

our &infix:<?&> is export = &apply_binary_operation.assuming('&');

our &infix:<??^> is export = &apply_binary_operation.assuming('^');
our &infix:<??|> is export = &apply_binary_operation.assuming('|');

our &infix:<?==> is export = &apply_binary_operation.assuming('==');
our &infix:<?!=> is export = &apply_binary_operation.assuming('!=');

our &infix:<?\<=> is export = &apply_binary_operation.assuming('<=');
our &infix:<?\<> is export = &apply_binary_operation.assuming('<');
our &infix:<?\>> is export = &apply_binary_operation.assuming('>');
our &infix:<?\>=> is export = &apply_binary_operation.assuming('>=');

our &infix:<?is> is export = &apply_binary_operation.assuming('is');
our &infix:<?is-not> is export = &apply_binary_operation.assuming('is not');

our &infix:<?in> is export = &apply_binary_operation.assuming('in');
our &infix:<?not-in> is export = &apply_binary_operation.assuming('not in');

our &prefix:<??not> is export = &apply_unary_operation.assuming('not');

our &infix:<?or> is export = &apply_binary_operation.assuming('or');
our &infix:<?and> is export = &apply_binary_operation.assuming('and');
