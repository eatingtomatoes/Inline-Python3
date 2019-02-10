use Inline::Python3::PyTuple;

use Test;

lives-ok {
    PyTuple.new((1,));

    PyTuple.new((1, 2, 3));

    PyTuple.new((1, "hello"));
}, 'basic tuple constructor';

lives-ok {
    is PyTuple.new((1,)), ??(1,);
    is PyTuple.new((1, 2, 3)), ??(1, 2, 3);
    is PyTuple.new((1, "hello")), ??(1, "hello");
}, 'convenient operators';

done-testing;
