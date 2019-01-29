# Description

Module for executing Python3 code and accessing Python libraries from Perl 6.

Note that this library is largely based on the Inline::Python.

# Usage

First, import Inline::Python3 and get a reference to the \__main__ module.
```
use Inline::Python3;
my $main = PyModule('__main__');
```
Let's start from some simple code:

```
say $main.run('5', :eval);
say $main.run("Python"', :eval); 
```

The keyword "eval" asks the python interpreter to calculate a simple expression and return its value.

You can also use the keyword "file", which means several statements.  No keyword is OK, which defaults to the "file".

Then, let's define a simple function in python world:

```
$main.run(q:to/PYTHON/);
def plus_int(a, b):
	return a + b
PYTHON
```
Then you can call it in perl6 code like this:
```
$main.plus_int(2, 1);
```

Note that you cannot directly call a function/method whose name conflicts with that of any method of the perl6 class "Any". For example, if you define a function/method with the name "sum", then you cannot do this: $main.sum(x, y). The perl6 compiler will treat it as a method call of the class "Any".

Here follows a bit more complex example:

```
$main.run(q:to/PYTHON/);
class Foo:
    def __init__(self, value):
        self.value = value
  
    def some_method(self, a, b):
        return a + b
        
	@staticmethod
    def some_static_method():
    	return 666
	
def dump_foo(foo):
    return foo.value
PYTHON
```

You can instantiate the python class like this:

```
my $foo = $main.Foo(1);
```

Accessing its attribute or method is quite easy:

```
say $foo.value 

say $main.Foo(1).value;

say $main.Foo(1).some_method(3, 1);

say $main.Foo(1).some_static_method;

say $main.dump_foo($main.Foo(6))
```

So far,  all functions and class are defined in the \__main__ module. But you can  use other modules too.

```
my $string = PyModule('string', :import);
```

The keyword ":import" is necessary for all modules except the \__main__.

Then you can use the string module happily:

```
say $string.capwords('foo bar')
```

See more usage in t/*.t files.

# Build

You will need a Python built with the -fPIC option (position independent code). Most distributions build their Python that way. 


With a python in your path, then build:

```
    perl6 configure.pl6
    make test
    make install
```



# Reference

- [Inline::Python](https://github.com/niner/Inline-Python)

- [Perl6 Documents](https://docs.perl6.org)

- [Perl6 Specification](https://design.perl6.org/)

- [Extending and Embedding the Python Interpreter](https://docs.python.org/3/extending/index.html)

- [Python/C API Reference Manual](https://docs.python.org/3/c-api/index.html)

- [Porting Python2 Extension Modules to Python 3](https://docs.python.org/3.6/howto/cporting.html?highlight=pymodinit_func)