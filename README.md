# TITLE

Inline::PythonObjects

# USAGE

First, import the module and get a reference to the __main__ module.
```
use Inline::PythonObjects;
my $main = PyModule('__main__');
```
Then, let's create a simple function:
```
$main.run(q:to/end/);
def plus_int(a, b):
	return a + b
end
```
Then you can call it:
```
$main.plus_int(2, 1);
```

You can do more:
```
class Foo:
    def __init__(self, val):
        self.val = val

    def test(self):
        return self.val

    def plus(self, a, b):
        return a + b
		
def test_foo(foo):
    return foo.test();
```		

Test it:

```
say $main.Foo(1).test;

say $main.Foo(1).sum_(3, 1);

say $main.test_foo($main.Foo(6))
```

You can find more usages in t/*.t files.


# DESCRIPTION

Module for executing Python code and accessing Python libraries from Perl 6.

Note that this library is largely based on the Inline::Python.

# BUILDING

You will need a Python built with the -fPIC option (position independent
code). Most distributions build their Python that way. To do this with pyenv,
use something like:


With a python in your path, then build:

```
    perl6 configure.pl6
    make test
    make install
```

