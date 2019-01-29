#!/usr/bin/env perl6

use v6;
use lib <lib>;
use Inline::Python3;
use Test;

plan 32;

my $main = PyModule('__main__');

$main.run(q/
from logging import warn
def test(obj):
    try:
        obj.ok(1)
    except Exception as e:
        warn(e)
    for i in range(10):
        retval = obj.test('Perl6')
        obj.ok(retval == 'Perl6')
        retval = obj.test('Perl6')
        obj.ok(retval == 'Perl6')
        retval = obj.test('Perl', 6)
        obj.ok(retval == ['Perl', 6])
/);

class Foo {
    method ok($value) {
        ok($value);
    }
    method test(*@args) {
        return |@args;
    }
}

my $foo = Foo.new;
$foo.ok(1);

$main.test($foo);

# vim: ft=perl6

