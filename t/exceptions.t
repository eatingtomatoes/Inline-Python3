#!/usr/bin/env perl6

use v6;
use lib <lib>;
use Inline::PythonObjects::PythonException;
use Inline::PythonObjects;
use Test;

my $py = PyModule('__main__');
{
    try $py.run(q:heredoc/PYTHON/);
    raise Exception(u"foo")
    PYTHON

    ok 1, 'survived Python exception';
    # ok $!.isa('X::AdHoc'), 'got an exception';
    # ok $!.Str() ~~ m/foo/, 'exception message found';
}
{
    $py.run(q:heredoc/PYTHON/);
        def perish():
            raise Exception(u"foo")
        PYTHON
    try $py.perish;
    ok 1, 'survived Python exception in function call';
    # ok $!.isa('X::AdHoc'), 'got an exception from function call';
    # ok $!.Str() ~~ m/foo/, 'exception message found from function call';
}
{
    $py.run(q:heredoc/PYTHON/);
        class Foo:
            def depart(self):
                raise Exception(u"foo")
        PYTHON
    my $foo = $py.Foo().depart;
    # $foo.depart;
    CATCH {
        ok 1, 'survived Python exception in method call';
        when X::AdHoc {
            ok $_.isa('X::AdHoc'), 'got an exception from method call';
            ok $_.Str() ~~ m/foo/, 'exception message found from method call';
        }
	when PythonException {
	}
    }
}
{
    $py.non_existing;
    CATCH {
        ok 1, 'survived calling missing Python function';
        when X::AdHoc {
            ok $_.isa('X::AdHoc'), 'got an exception for calling a missing function';
            is $_.Str(), "name 'non_existing' is not defined", 'exception message found for missing function';
        }
	when PythonException {
	}
    }
}
{
    $py.run(q:heredoc/PYTHON/);
        class Foo:
            pass
        PYTHON
    my $foo = $py.Foo;
    $foo.non_existing;
    CATCH {
        ok 1, 'survived Python missing method';
        when X::AdHoc {
            ok $_.isa('X::AdHoc'), 'got an exception for calling missing method';
            is $_.Str(), "Foo instance has no attribute 'non_existing'", 'exception message found for calling missing method';
        }
	when PythonException {}
    }
}


class Foo {
    method depart {
        die "foo";
    }
}

$py.run(q:heredoc/PYTHON/);
    import logging
    def test_foo(foo):
        try:
            foo.depart()
        except Exception as e:
    # return e.message
            return "foo"
    PYTHON

is $py.test_foo(Foo.new), 'foo';

{
    $py.run(q:heredoc/PYTHON/);
        def pass_through(foo):
            foo.depart()
        PYTHON
    $py.pass_through(Foo.new);
    CATCH {
        ok 1, 'P6 exception made it through Python code';
        when X::AdHoc {
            ok $_.isa('X::AdHoc'), 'got an exception from method call';
            ok $_.Str() ~~ m/foo/, 'exception message found from method call';
        }
	when PythonException {
	}
    }
}

done-testing;

# vim: ft=perl6
