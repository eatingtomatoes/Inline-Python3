#!/usr/bin/env perl6

use v6.c;
use Inline::Python3;
use Test;

my $main = PyModule('__main__');
$main.run(q:to/PYTHON/);
def identity(a):
    return a
PYTHON

class Foo {}

# failed
# expected: Buf.new(228,98,99)
#      got: $[228, 98, 99]
#
# at present it don't support Buf type
#
for ('abcö',
     # Buf.new('äbc'.encode('latin-1')),
     24,
     2.4.Num,
     [1, 2],
     { a => 1, b => 2},
     Any, Foo.new) -> $obj {
    is-deeply $main.identity($obj), $obj, "Can round-trip " ~ $obj.^name;
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
