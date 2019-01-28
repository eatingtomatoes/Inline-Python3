#include "Python.h"

typedef PyObject* (*Perl6Func)(const char* name, PyObject* args, PyObject** error);

Perl6Func perl6_call_handle;

void py_set_perl6_call_handle(Perl6Func func) {
    perl6_call_handle = func;
}

PyObject* call_perl6(PyObject* self, PyObject* args) {
    PyObject* name = PyTuple_GetItem(args, 0);
    const char* name_str = PyUnicode_AsUTF8(name);
    PyObject* params = PyTuple_GetItem(args, 1);
    
    PyObject* error = NULL;
    PyObject* result = perl6_call_handle(name_str, params, &error);

    if (error) {
        PyErr_SetObject(PyExc_Exception, error);
        return NULL;
    }
    
    return result;
}

static PyMethodDef perl6_functions[] = {
    {"call_perl6", call_perl6, METH_VARARGS, "call into perl6"},    
    {NULL, NULL, 0, NULL}
};

static struct PyModuleDef perl6_module = {
    PyModuleDef_HEAD_INIT,
    "perl6",
    "perl6 -- Access a Perl 6 interpreter transparently",
    -1, /* m_size */
    perl6_functions, /* m_methods */
};

PyMODINIT_FUNC PyInit_libperl6(void){
    return PyModule_Create(&perl6_module);
}
