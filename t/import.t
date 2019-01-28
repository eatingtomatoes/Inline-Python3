#!/usr/bin/env perl6

use v6;
use lib <lib>;
use Inline::PythonObjects::PyInterface;
use Inline::PythonObjects;
use Test;

my $string = PyModule('string', :import);

#my $py = Inline::Python.default_python;
# is(string::capwords('foo bar'), 'Foo Bar');
is($string.capwords('foo bar'), 'Foo Bar');

#use sys:from<Python>;
#BEGIN sys::path::append('t/pylib');

# the 'named.py' has been deleted so it is impossible to succeed
#
# use named:from<Python>;
# my $named = PyModule('named', :import);
# is $named.test_named(a => 1, b => 2), 3;
# is $named.test_kwargs(a => 1, b => 2), 2;

done-testing;
