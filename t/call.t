#!/usr/bin/env perl6

use v6.c;
use lib <lib>;
use Inline::PythonObjects;

say "1..11";

my $main = PyModule('__main__');

$main.run('

def test():
    print("ok 1 - executing a parameterless function without return value");
    return;

def test_int_params(a, b):
    if a == 2 and b == 1:
        print("ok 2 - int params");
    else:
        print("not ok 2 - int params");
    return;

def test_str_params(a, b, i):
    if a == "Hello" and b == "Python":
        print("ok %i - str params" % i);
    else:
        print("not ok %i - str params" % i);
    return;

def test_int_retval():
    return 1;

def test_int_retvals():
    return 3, 1, 2;

def test_str_retval():
    return u"Hello Perl 6!";

def test_mixed_retvals():
    return (u"Hello", u"Perl", 6);

def test_none(undef):
    return undef is None;

import types
def test_hash(h):
    return (
        isinstance(h, types.DictType)
        and len(h.keys()) == 2
        and "a" in h
        and "b" in h
        and h["a"] == 2
        and isinstance(h["b"], types.DictType)
        and isinstance(h["b"]["c"], list)
        and len(h["b"]["c"]) == 2
        and h["b"]["c"][0] == 4
        and h["b"]["c"][1] == 3
    )

def test_foo(foo):
    return foo.test();

class Foo:
    def __init__(self, val):
        self.val = val

    def test(self):
        return self.val

# caution !!! the name "sum" conflicts with the sum of perl6
    def sum_(self, a, b):
        return a + b
');

$main.test;
$main.test_int_params(2, 1);
$main.test_str_params('Hello', 'Python', 3);

$main.run('
import sys
sys.stdout.flush()
');

say $main.test_int_retval;
if ($main.test_int_retval == 1) {
    say "ok 4 - return one int";
}
else {
    say "not ok 4 - return one int";
}
my $retvals = $main.test_int_retvals;
if ($retvals.elems == 3 and $retvals[0] == 3 and $retvals[1] == 1 and $retvals[2] == 2) {
    say "ok 5 - return three ints";
}
else {
    say "not ok 5 - return three ints";
    say "    got: {$retvals}";
    say "    expected: 3, 1, 2";
}
if $main.test_str_retval eq 'Hello Perl 6!' {
    say "ok 6 - return one string";
}
else {
    say "not ok 6 - return one string";
}
$retvals = $main.test_mixed_retvals;

if ($retvals == 3 and $retvals[0] eq 'Hello' and $retvals[1] eq 'Perl' and $retvals[2] == 6) {
    say "ok 7 - return mixed values";
}
else {
    say "not ok 7 - return mixed values";
    say "    got: {$retvals}";
    say "    expected: 'Hello', 'Perl', 6";
}

say $main.Foo(1).test;
if ($main.Foo(1).test() == 1) {
    say "ok 8 - Python method call";
}
else {
    say "not ok 8 - Python method call";
}

if ($main.Foo(1).sum_(3, 1) == 4) {
    say "ok 9 - Python method call with parameters";
}
else {
    say "not ok 9 - Python method call with parameters";
}

if ($main.test_none(Any) == 1) {
    say "ok 10 - Any converted to undef";
}
else {
    say "not ok 10 - Any converted to undef";
}


# error in python code:
#    module 'types' has no attribute 'DictType'
#
# if ($main.test_hash(${a => 2, b => {c => [4, 3]}}) == 1) {
#     say "ok 11 - Passing hashes to Python";
# }
# else {
#     say "not ok 11 - Passing hashes to Python";
#}

if ($main.test_foo($main.Foo(6)) == 6) {
    say "ok 11 - Passing Python objects back from Perl 6";
}
else {
    say "not ok 11 - Passing Python objects back from Perl 6";
}

$main.test_str_params(:i(12), :a<Hello>, :b<Python>);

# vim: ft=perl6
