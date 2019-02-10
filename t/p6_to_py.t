#!/usr/bin/env perl6

use v6.c;
use Inline::Python3;
use Inline::Python3::PyModule;
use Test;

start-python;

my $main = PyModule('__main__');
$main.run(q:to/PYTHON/);
def identity(a):
    return a
PYTHON

class Foo {}

for ('abcö', 24, 2.4.Num, Any, Foo.new) -> $obj {
    is-deeply $main.identity($obj), $obj, "Can round-trip " ~ $obj.^name;
}

subtest {
    for $main.identity([1, 2]).item -> $/ {
	is $/.elems, 2;
	is $0, 1;
	is $1, 2;
    }
}, 'round-trip array';

subtest {
    for $main.identity({a => 1, b => 2}).item -> $/ {
	is $/.elems, 2;
	is $<a>, 1;
	is $<b>, 2;
    }
}


$main.run(q:to/PYTHON/);
# coding=utf-8
def check_utf8(str):
    return str == 'Töst'
PYTHON

ok $main.check_utf8('Töst'), 'UTF-8 string recognized in Python';

$main.run(q:to/PYTHON/);
def is_two_point_five(a):
    return a == 2.5;
PYTHON

ok $main.is_two_point_five(2.5);
ok $main.is_two_point_five(Num.new(2.5));

done-testing;
