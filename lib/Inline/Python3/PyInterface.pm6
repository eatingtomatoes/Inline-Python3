unit module PyInterface;

use NativeCall;

# here are some binds for python's c api.

my constant $pyhelper is export = %?RESOURCES<libraries/pyhelper>.Str;
my constant $perl6 = %?RESOURCES<libraries/perl6>.Str;

constant PyRef is export = Pointer;

sub py_import(Str --> PyRef)
is symbol('PyImport_ImportModule')
is export is native($pyhelper)
{ ... }

sub py_instance_check(PyRef --> int32)
is export is native($pyhelper)
{ ... }

sub py_int_check(PyRef --> int32)
is export is native($pyhelper)
{ ... }

sub py_float_check(PyRef --> int32)
is export is native($pyhelper)
{ ... }

sub py_unicode_check(PyRef --> int32)
is export is native($pyhelper)
{ ... }


sub py_sequence_check(PyRef --> int32)
is export is native($pyhelper)
{ ... }

sub py_mapping_check(PyRef --> int32)
is export is native($pyhelper)
{ ... }

sub py_callable_check(PyRef --> int32)
is export is native($pyhelper)
{ ... }

sub py_none_check(PyRef --> int32)
is export is native($pyhelper)
{ ... }

sub py_object_is_instance(PyRef, PyRef --> int32)
is export is native($pyhelper)
{ ... }

sub py_type_check(PyRef --> int32)
is export is native($pyhelper)
{ ... }


sub py_int_from_py(PyRef --> int32)
is export is native($pyhelper)
{ ... }


sub py_int_to_py(int32 --> PyRef)
is export is native($pyhelper)
{ ... }

sub py_float_from_py(PyRef --> num64)
is export is native($pyhelper)
{ ... }

sub py_float_to_py(num64 --> PyRef)
is export is native($pyhelper)
{ ... }

sub py_unicode_to_utf8(PyRef --> PyRef)
is export is native($pyhelper)
{ ... }

sub py_str_to_py(int32, Str --> PyRef)
is export is native($pyhelper)
{ ... }


sub py_tuple_new(int32 --> PyRef)
is export is native($pyhelper)
{ ... }

sub py_tuple_set_item(PyRef, int32, PyRef)
is export is native($pyhelper)
{ ... }

sub py_list_new(int32 --> PyRef)
is export is native($pyhelper)
{ ... }

sub py_list_set_item(PyRef, int32, PyRef)
is export is native($pyhelper)
{ ... }

sub py_dict_new(--> PyRef)
is export is native($pyhelper)
{ ... }

sub py_dict_set_item(PyRef, PyRef, PyRef)
is export is native($pyhelper)
{ ... }

sub py_sequence_length(PyRef --> int32)
is export is native($pyhelper)
{ ... }

sub py_sequence_get_item(PyRef, int32 --> PyRef)
is export is native($pyhelper)
{ ... }

sub py_mapping_items(PyRef --> PyRef)
is export is native($pyhelper)
{ ... }

sub py_none(--> PyRef)
is export is native($pyhelper)
{ ... }

sub py_dec_ref(PyRef)
is export is native($pyhelper)
{ ... }


sub py_inc_ref(PyRef)
is export is native($pyhelper)
{ ... }


sub py_fetch_error(CArray[PyRef])
is export is native($pyhelper)
{ ... }

sub py_import_addmodule(Str --> PyRef)
is export is native($pyhelper)
is symbol('PyImport_AddModule')
{ ... }

sub py_module_getdict(PyRef --> PyRef)
is export is native($pyhelper)
is symbol('PyModule_GetDict')
{ ... }

sub py_mapping_getitemstring(PyRef, Str --> PyRef)
is export is native($pyhelper)
is symbol('PyMapping_GetItemString')
{ ... }

sub py_object_call(PyRef, PyRef, PyRef --> PyRef)
is export is native($pyhelper)
is symbol('PyObject_Call')
{ ... }


sub py_raise_missing_func(Str)
is export is native($pyhelper)
{ ... }

sub py_raise_missing_method(PyRef, Str)
is export is native($pyhelper)
{ ... }

sub py_run_string(Str, int32, PyRef, PyRef --> PyRef)
is export is native($pyhelper)
is symbol('PyRun_String')
{ ... }

sub py_mode_eval_input(--> int32)
is export is native($pyhelper)
{ ... }

sub py_mode_file_input(--> int32)
is export is native($pyhelper)
{ ... }

sub py_mode_single_input(--> int32)
is export is native($pyhelper)
{ ... }

sub py_object_get_attr_string(PyRef, Str --> PyRef)
is export is native($pyhelper)
is symbol('PyObject_GetAttrString')
{ ... }

sub py_object_has_attr_string(PyRef, Str --> int32)
is export is native($pyhelper)
is symbol('PyObject_HasAttrString')
{ ... }

sub py_init_python()
is export is native($pyhelper)
{ ... }

sub py_module_check(PyRef --> int32)
is export is native($pyhelper)
{ ... }

sub py_object_str(PyRef --> PyRef)
is export is native($pyhelper)
is symbol('PyObject_Str')
{ ... }

sub py_tuple_check(PyRef --> int32)
is export is native($pyhelper)
{ ... }

sub py_bytes_check(PyRef --> int32)
is export is native($pyhelper)
{ ... }

sub py_bytearray_check(PyRef --> int32)
is export is native($pyhelper)
{ ... }

sub py_tuple_get_item(PyRef, int32 --> PyRef)
is export is native($pyhelper)
{ ... }

sub py_bytes_as_string(PyRef --> Str)
is export is native($pyhelper)
{ ... }

sub py_type_type(--> Pointer)
is export is native($pyhelper)
{ ... }

sub py_set_perl6_call_handle(&handle (Str, PyRef, PyRef --> PyRef))
is export is native($perl6)
{ ... }

