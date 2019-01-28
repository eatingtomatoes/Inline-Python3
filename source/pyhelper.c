#include "Python.h"
#include "datetime.h"

void py_init_python()
{
    /* sometimes Python needs to know about argc and argv to be happy */
    int _python_argc = 1;
    wchar_t* _python_argv[] = {
        L"python",
    };

    Py_SetProgramName(L"python");
    Py_Initialize();

    PySys_SetArgv(_python_argc, _python_argv); /* Tk needs this */
    PyDateTime_IMPORT;
}

int py_mode_single_input() { return Py_single_input; }

int py_mode_file_input() { return Py_file_input; }

int py_mode_eval_input() { return Py_eval_input; }

int py_instance_check(PyObject* obj)
{
    unsigned long tp_flags = obj->ob_type->tp_flags;
    return (!((tp_flags & Py_TPFLAGS_LONG_SUBCLASS)
        || (tp_flags & Py_TPFLAGS_LIST_SUBCLASS)
        || (tp_flags & Py_TPFLAGS_TUPLE_SUBCLASS)
        || (tp_flags & Py_TPFLAGS_BYTES_SUBCLASS)
        || (tp_flags & Py_TPFLAGS_UNICODE_SUBCLASS)
        || (tp_flags & Py_TPFLAGS_DICT_SUBCLASS)
        || (tp_flags & Py_TPFLAGS_TYPE_SUBCLASS)));
}

int py_tuple_check(PyObject* object) { return PyTuple_Check(object); }

int py_int_check(PyObject* obj) { return PyLong_Check(obj); }

int py_float_check(PyObject* obj) { return PyFloat_Check(obj); }

int py_unicode_check(PyObject* obj) { return PyUnicode_Check(obj); }

int py_bytes_check(PyObject* object) { return PyBytes_Check(object); }

int py_bytearray_check(PyObject* object) { return PyByteArray_Check(object); }

int py_sequence_check(PyObject* obj) { return PySequence_Check(obj); }

int py_mapping_check(PyObject* obj) { return PyMapping_Check(obj); }

int py_callable_check(PyObject* obj) { return PyCallable_Check(obj); }

int py_module_check(PyObject* obj) { return PyModule_Check(obj); }

int py_none_check(PyObject* obj) { return obj == Py_None; }

int py_type_check(PyObject* obj) { return PyType_Check(obj); }

int py_object_is_instance(PyObject *inst, PyObject *cls) {
    return PyObject_IsInstance(inst, cls);
}


long py_int_from_py(PyObject* obj) { return PyLong_AsLong(obj); }

double py_float_from_py(PyObject* obj) { return PyFloat_AsDouble(obj); }

PyObject* py_int_to_py(long num) { return PyLong_FromLong(num); }

PyObject* py_float_to_py(double num) { return PyFloat_FromDouble(num); }

PyObject* py_str_to_py(int len, char* str)
{
    return PyUnicode_DecodeUTF8(str, len, "replace");
}

PyObject* py_unicode_to_utf8(PyObject* obj)
{
    return PyUnicode_AsUTF8String(obj); /* new reference */ // bytes object
}

int py_sequence_length(PyObject* obj) { return PySequence_Length(obj); }

PyObject* py_sequence_get_item(PyObject* obj, int item)
{
    return PySequence_GetItem(obj, item);
}

PyObject* py_mapping_items(PyObject* obj) { return PyMapping_Items(obj); }

PyObject* py_tuple_new(int len) { return PyTuple_New(len); }

void py_tuple_set_item(PyObject* tuple, int i, PyObject* item)
{
    PyTuple_SetItem(tuple, i, item);
}

PyObject* py_list_new(int len) { return PyList_New(len); }

void py_list_set_item(PyObject* list, int i, PyObject* item)
{
    PyList_SetItem(list, i, item);
}

PyObject* py_dict_new(void) { return PyDict_New(); }

void py_dict_set_item(PyObject* dict, PyObject* key, PyObject* item)
{
    PyDict_SetItem(dict, key, item);
}

PyObject* py_tuple_get_item(PyObject* object, Py_ssize_t index)
{
    return PyTuple_GetItem(object, index);
}

const char* py_bytes_as_string(PyObject* object)
{
    return PyBytes_AsString(object);
}

PyObject* py_none(void)
{
    Py_INCREF(Py_None);
    return Py_None;
}

/* PyTypeObject* py_type_type() { */
/*     return PyType_Type; */
/* } */

void py_dec_ref(PyObject* obj) { Py_DECREF(obj); }

void py_inc_ref(PyObject* obj) { Py_INCREF(obj); }


void py_raise_missing_func(const char* name)
{
    PyErr_Format(PyExc_NameError, "name '%s' is not defined", name);
}

void py_fetch_error(PyObject** exception)
{
    /* ex_type, ex_value, ex_trace, ex_message */
    PyErr_Fetch(&exception[0], &exception[1], &exception[2]);
    if (exception[0] == NULL)
        return;
    PyErr_NormalizeException(&exception[0], &exception[1], &exception[2]);
    exception[3] = PyObject_Str(exception[1]); /* new reference */
}

void py_raise_missing_method(PyObject* obj, char* name)
{
    PyObject* class = PyObject_GetAttrString(obj, "__class__");
    if (class) {
        PyObject* class_name = PyObject_GetAttrString(class, "__name__");
        /* char *c_class_name = PyString_AsString(class_name); */
        const char* c_class_name = PyUnicode_AsUTF8(class_name);
        PyErr_Format(PyExc_NameError, "%s instance has no attribute '%s'",
            c_class_name, name);
        Py_DECREF(class_name);
        Py_DECREF(class);
    } else {
        PyErr_Format(PyExc_NameError, "instance has no attribute '%s'", name);
    }
}



