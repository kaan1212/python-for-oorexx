// See: https://docs.python.org/3/extending/embedding.html#pure-embedding

#include <oorexxapi.h>
#include <Python.h>

PyObject* pModule;

void initialize() {
	Py_Initialize();

	PyObject* pName = PyUnicode_FromString("pyrexx");
	pModule = PyImport_Import(pName);
	Py_DECREF(pName);
}

int finalize() {
	if (Py_FinalizeEx() < 0) {
		return 120;
	}

	return 0;
}

const char* invoke_function(const char* name, int argc, const char* argv[]) {
	PyObject* pFunc, * pArgs, * pValue;

	pFunc = PyObject_GetAttrString(pModule, name);
	pArgs = PyTuple_New(argc);
	
	for (int i = 0; i < argc; i++) {
		PyTuple_SetItem(pArgs, i, PyUnicode_FromString(argv[i]));
	}

	pValue = PyObject_CallObject(pFunc, pArgs);
	const char* string = PyUnicode_AsUTF8(pValue);

	Py_DECREF(pValue);
	Py_DECREF(pArgs);
	Py_DECREF(pFunc);
	
	return string;
}

RexxRoutine0(RexxObjectPtr, PyRexx_Initialize) {
	initialize();
	return NULLOBJECT;
}

RexxRoutine0(int, PyRexx_Finalize) {
	return finalize();
}

RexxRoutine1(CSTRING, PyRexx_Import, CSTRING, name) {
	int argc = 1;
	const char* argv[] = { name };

	return invoke_function("invoke_import", argc, argv);
}

RexxRoutine2(CSTRING, PyRexx_CallFunction, CSTRING, name, CSTRING, args) {
	int argc = 2;
	const char* argv[] = { name, args };

	return invoke_function("invoke_function", argc, argv);
}

RexxRoutine3(CSTRING, PyRexx_CallMethod, CSTRING, identity, CSTRING, name, CSTRING, args) {
	int argc = 3;
	const char* argv[] = { identity, name, args };

	return invoke_function("invoke_method", argc, argv);
}

RexxRoutine1(CSTRING, PyRexx_GetStringVersion, CSTRING, identity) {
	int argc = 1;
	const char* argv[] = { identity };

	return invoke_function("invoke_str", argc, argv);
}

RexxRoutineEntry orx_funcs[] = {
	REXX_TYPED_ROUTINE(PyRexx_Initialize,		PyRexx_Initialize),
	REXX_TYPED_ROUTINE(PyRexx_Finalize,			PyRexx_Finalize),
	REXX_TYPED_ROUTINE(PyRexx_Import,			PyRexx_Import),
	REXX_TYPED_ROUTINE(PyRexx_CallFunction,		PyRexx_CallFunction),
	REXX_TYPED_ROUTINE(PyRexx_CallMethod,		PyRexx_CallMethod),
	REXX_TYPED_ROUTINE(PyRexx_GetStringVersion, PyRexx_GetStringVersion),
	REXX_LAST_ROUTINE()
};

RexxPackageEntry PyRexxExternalRoutines_package_entry = {
	STANDARD_PACKAGE_HEADER
	REXX_CURRENT_INTERPRETER_VERSION,	// ooRexx version at compilation time or higher
	"PyRexxExternalRoutines",			// name of the package
	"1.0.0",							// package information
	NULL,								// no load function
	NULL,								// no unload function
	orx_funcs,							// the exported routines
	NULL								// the exported methods
};

// package loading stub.
OOREXX_GET_PACKAGE(PyRexxExternalRoutines);
