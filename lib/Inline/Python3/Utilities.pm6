use Inline::Python3::PyInterface;

# some utilities to help manage the ref-count.
module Utilities {
    sub infix:<modified-by>(Any:D $object, &modify) is export {
	modify($object);
	$object;
    }

    sub infix:<temporarily>($object, &user) is export {
	LAST { $object andthen py_dec_ref($_) }
	user($object);
    }

    sub infix:<decref-after>(@objects, &user) is export {
	LAST {
	    defined $_ and py_dec_ref($_) for @objects;
	}
	user(|@objects)
    }
}
