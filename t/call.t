#!/usr/bin/env perl6

use v6.c;
use Test;
use Inline::Python3;
use Inline::Python3::PyModule;

start-python;

my $main = PyModule('__main__');

$main.run(q:to/PYTHON/);
def test_no_param_nor_retval():
    pass

def test_int_params(a, b):
    return a == 2 and b == 1

def test_str_params(a, b):
    return a == "Hello" and b == "Python"

def test_int_retval():
    return 1

def test_int_retvals():
    return 3, 1, 2

def test_str_retval():
    return "Hello Perl 6!"

def test_mixed_retvals():
    return ("Hello", "Perl", 6);

def test_none(undef):
    return undef is None

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
PYTHON

lives-ok {
    $main.test_no_param_nor_retval;
}, "no param nor retval";

ok $main.test_int_params(a => 2, b => 1), "int params";

ok $main<test_int_params>(a => 2, b => 1), "int params by AT-KEY";

ok $main.test_str_params(:a<Hello>, :b<Python>), "str params";

is $main.test_int_retval, 1, "return one int";

subtest {
    my $retvals = $main.test_int_retvals;
    is $retvals.elems, 3;
    is $retvals[0], 3;
    is $retvals[1], 1;
    is $retvals[2], 2;
}, "return three ints";

is $main.test_str_retval, 'Hello Perl 6!',"return one string";

subtest {
    my $retvals = $main.test_mixed_retvals;
    is $retvals.elems, 3;
    is $retvals[0], 'Hello';
    is $retvals[1], 'Perl';
    is $retvals[2], 6;
}, "return mixed values";

is $main.Foo(1).test(), 1, "Python method call";

is $main.Foo(1).sum_(3, 1), 4, "Python method call with parameters";

is $main.test_none(Any), 1, "Any converted to undef";

is $main.test_foo($main.Foo(6)), 6, "Passing Python objects back from Perl 6";

done-testing;
