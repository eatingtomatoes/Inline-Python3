use Inline::Python3::PyInterface;

# some utilities to help manage the ref-count.
module Utilities {
    sub infix:<modified-by>($object, &modify) is export {
	modify($object);
	$object;
    }

    sub infix:<free-after>($object, &user) is export {
	LAST { $object andthen py_dec_ref($_) }
	user($object);
    }
}
