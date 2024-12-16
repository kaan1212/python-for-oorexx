// See: https://docs.python.org/3/extending/embedding.html#pure-embedding

#include <oorexxapi.h>
#include <Python.h>

bool debug = 0;
PyObject* pModule;

RexxRoutine2(RexxObjectPtr, PyRexx_Initialize, CSTRING, moduleName, int, debugOn) {
	debug = debugOn;

	Py_Initialize();
	pModule = PyImport_ImportModule(moduleName);

	return NULLOBJECT;
}

RexxRoutine0(int, PyRexx_Finalize) {
	if (Py_FinalizeEx() < 0) {
		return 120;
	}

	return 0;
}

PyObject* rexxToPythonObject(RexxCallContext* context, RexxObjectPtr obj, int indent) {
	RexxClassObject stringClass = context->FindClass("String");
	RexxClassObject pythonInstanceClass = context->FindContextClass("PythonInstance");

	if (obj == NULL) {
		if (debug) printf("%*sNULL\n", indent, "");
		return NULL;
	}
	else if (obj == context->Nil()) {
		if (debug) printf("%*sRexxNil\n", indent, "");
		return Py_None;
	}
	else if (context->IsInstanceOf(obj, stringClass)) { // IsString() does not work correctly on integer literals.
		if (debug) printf("%*sRexxString: %s\n", indent, "", context->ObjectToStringValue(obj));

		PyObject* pString = PyUnicode_FromString(context->ObjectToStringValue(obj));
		return pString;
	}
	else if (context->IsArray(obj)) {
		if (debug) printf("%*sRexxArray\n", indent, "");

		RexxArrayObject array = (RexxArrayObject)obj;
		size_t size = context->ArrayItems(array);
		PyObject* pArgs = PyTuple_New(size);

		for (size_t i = 0; i < size; i++) {
			obj = context->ArrayAt(array, i + 1);
			PyTuple_SetItem(pArgs, i, rexxToPythonObject(context, obj, indent + 2));
		}

		return pArgs;
	}
	else if (context->IsInstanceOf(obj, pythonInstanceClass)) {
		RexxObjectPtr identity = context->SendMessage0(obj, "identity");
		uintptr_t ptr;
		context->ObjectToUintptr(identity, &ptr);

		if (debug) printf("%*sPythonInstance: %s\n", indent, "", context->ObjectToStringValue(identity));

		return (PyObject*)ptr;
	}
	else {
		printf("Unknown ooRexx class.\n");
	}
}

RexxRoutine2(RexxObjectPtr, PyRexx_CallFunction, CSTRING, name, OPTIONAL_RexxObjectPtr, obj) {
	if (debug) {
		printf("\n");
		printf("Function:\n");
		printf("  Name: %s\n", name);
		printf("  args:\n");
	}

	PyObject* pArgs = rexxToPythonObject(context, obj, 4);

	if (pArgs != NULL && !PyTuple_Check(pArgs)) {
		pArgs = PyTuple_Pack(1, pArgs);
	}

	PyObject* pFunc, * pValue;
	pFunc = PyObject_GetAttrString(pModule, name);
	pValue = PyObject_CallObject(pFunc, pArgs);

	RexxObjectPtr result = NULLOBJECT;

	if (Py_IsNone(pValue)) {
		result = NULLOBJECT; // Same as NULL.
		if (debug) printf("  Result: NULL\n");
	}
	else if (PyUnicode_Check(pValue)) {
		const char* string = PyUnicode_AsUTF8(pValue);
		result = context->NewStringFromAsciiz(string);
		if (debug) printf("  Result: String %s\n", string);
	}
	else {
		printf("  Result: Unknown\n");
	}

	Py_DECREF(pValue);
	//Py_DECREF(pArgs);
	Py_DECREF(pFunc);

	return result;
}

RexxRoutineEntry pyrexx_functions[] = {
	REXX_TYPED_ROUTINE(PyRexx_Initialize,		PyRexx_Initialize),
	REXX_TYPED_ROUTINE(PyRexx_Finalize,			PyRexx_Finalize),
	REXX_TYPED_ROUTINE(PyRexx_CallFunction,		PyRexx_CallFunction),
	REXX_LAST_ROUTINE()
};

RexxPackageEntry PyRexxExternalRoutines_package_entry = {
	STANDARD_PACKAGE_HEADER
	REXX_CURRENT_INTERPRETER_VERSION,	// ooRexx version at compilation time or higher
	"PyRexxExternalRoutines",			// name of the package
	"1.0.0",							// package information
	NULL,								// no load function
	NULL,								// no unload function
	pyrexx_functions,					// the exported routines
	NULL								// the exported methods
};

// package loading stub.
OOREXX_GET_PACKAGE(PyRexxExternalRoutines);
