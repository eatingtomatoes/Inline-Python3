#!/usr/bin/env perl6

use v6;
use lib <lib>;
use Inline::Python3;
use Test;

plan 10;

my $main = PyModule('__main__');
$main.run(q[
def identity(a):
    return a
]);

class Foo {
}

# failed
# expected: Buf.new(228,98,99)
#      got: $[228, 98, 99]
#
# at present it don't support Buf type
#
for ('abcö',
     # Buf.new('äbc'.encode('latin-1')),
     24, 2.4.Num, [1, 2], { a => 1, b => 2}, Any, Foo.new) -> $obj {

    is-deeply $main.identity($obj), $obj, "Can round-trip " ~ $obj.^name;
}

$main.run(q/
# coding=utf-8
def check_utf8(str):
    return str == 'Töst'
/);

# say $main.check_utf8('Töst');
ok($main.check_utf8('Töst'), 'UTF-8 string recognized in Python');


# failed
# 'list' object has no attribute 'decode'

# at present it don't support Buf type
#
# $main.run(q/
# # coding=utf-8
# def check_latin1(str):
#     print(type(str))
#     return str.decode('latin-1') == 'Töst';
# /);

# ok($main.check_latin1('Töst'.encode('latin-1')), 'latin-1 works in Python');

$main.run(q/
def is_two_point_five(a):
    return a == 2.5;
/);

ok($main.is_two_point_five(2.5));
ok($main.is_two_point_five(Num.new(2.5)));

# vim: ft=perl6
