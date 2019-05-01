# Description

Module for executing Python3 code and accessing Python libraries from Perl 6.

Note that this library is largely based on the Inline::Python.

# Usage

First, import necessary modules and get a reference to the \__main__ module.
```
use Inline::Python3;
use Inline::Python3::PyModule;

# initialize the environment
start-python;

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

 There exists  a way to bypass the problem:

```
say $main<sum>(1, 2);
```

Note that "$main.sum(...)" is invoking a function defined in $main, while "$main\<sum>" is accessing a $main's attribute, which is a callable object. 

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

say $main<Foo>.some_static_method;

say $main.dump_foo($main.Foo(6))
```

So far,  all functions and class are defined in the \__main__ module. But you can  use other modules too.

```
my $string = PyModule('string');
```

Then you can use the string module happily:

```
say $string.capwords('foo bar')
```

You may also use python's operators:

```
use Inline::Python3::PyOperators;
my $pyobject = ... ;
my $pylist = ... ;
say $pyobject ?in $pylist;
```

Basically, unary python operators start with `??` while binary ones start with `?`. There are a few of exceptions. See the comments in PyOperator.pm6.

See more usage in t/*.t files.

# A Complete Example

Following is a runnable example, which use keras to train a cnn on the mnist dataset.

The code is based on the [example](https://github.com/keras-team/keras/blob/master/examples/mnist_cnn.py) from keras document.

```
#! /usr/bin/env perl6

use Inline::Python3;
use Inline::Python3::PyModule;

start-python;

sub np { PyModule('numpy') }
sub keras { PyModule('keras') }

my $batch-size = 128;
my $num-classes = 10;
my $epochs = 12;

my @image-dim = do {
    keras.backend.image_data_format eq 'channels_first' ??
    (1, 28, 28) !! (28, 28, 1)
}

my ($train, $test) = keras.datasets.mnist.load_data.list.map: -> $/ {
    np.true_divide($0.reshape($0.shape[0], |@image-dim).astype('float32'), 255),
    keras.utils.to_categorical($1, $num-classes)
}

my $inputs = keras.layers.Input(shape => @image-dim);
my $outputs = do given PyModule('keras.layers') {
    $inputs
    ==> .Conv2D(32, (3, 3), :activation<relu>)()
    ==> .Conv2D(64, (3, 3), :activation<relu>)()
    ==> .MaxPooling2D(pool_size => (2,2))()
    ==> .Dropout(0.25)()
    ==> .Flatten()()
    ==> .Dense(128, :activation<relu>)()
    ==> .Dropout(0.5)()
    ==> .Dense($num-classes, :activation<softmax>)()
}

given keras.models.Model(:$inputs, :$outputs) {
    .compile(
	loss => keras.losses<categorical_crossentropy>,
	optimizer => keras.optimizers.Adadelta,
	metrics => ['accuracy']
    );

    .fit(
	|$train, batch_size => $batch-size,
	epochs => $epochs, verbose => 1,
	validation_data => $test
    );

    .evaluate(|$test, verbose => 0);
}
```

# Build

You will need a Python built with the -fPIC option (position independent code). Most distributions build their Python that way. 

You can choose which python to be used by settinng the environment variable PYTHON_CONFIG to the path to python3.*-config.  If you don't specify one, the builder will use the first result of shell command 'locate python3-config'.


With a python in your path, then build:

```
perl6 configure.pl6
make test
# Sorry, I don't know how to implement the "make install" :(
make install
```

Or you can use the zef:

```
zef install .
```

Note that at present this library cannot be built with python interpreter provided by anaconda.

# Reference

- [Inline::Python](https://github.com/niner/Inline-Python)

- [Perl6 Documents](https://docs.perl6.org)

- [Perl6 Specification](https://design.perl6.org/)

- [Extending and Embedding the Python Interpreter](https://docs.python.org/3/extending/index.html)

- [Python/C API Reference Manual](https://docs.python.org/3/c-api/index.html)

- [Porting Python2 Extension Modules to Python 3](https://docs.python.org/3.6/howto/cporting.html?highlight=pymodinit_func)



# Contact

schwaa@outlook.com
