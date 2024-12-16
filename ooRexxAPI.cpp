#include <oorexxapi.h>

RexxRoutine1(logical_t, IsString, RexxObjectPtr, obj) {
	return context->IsString(obj);
}

RexxRoutine2(logical_t, IsInstanceOfClass, RexxObjectPtr, obj, CSTRING, name) {
	RexxClassObject class_ = context->FindClass(name);
	
	return context->IsInstanceOf(obj, class_);
}

RexxRoutine2(logical_t, IsInstanceOfContextClass, RexxObjectPtr, obj, CSTRING, name) {
	RexxClassObject class_ = context->FindContextClass(name);
	
	return context->IsInstanceOf(obj, class_);
}

RexxRoutineEntry oorexxapi_functions[] = {
	REXX_TYPED_ROUTINE(IsString, IsString),
	REXX_TYPED_ROUTINE(IsInstanceOfClass, IsInstanceOfClass),
	REXX_TYPED_ROUTINE(IsInstanceOfContextClass, IsInstanceOfContextClass),
	REXX_LAST_ROUTINE()
};

RexxPackageEntry oorexxapi_package_entry = {
	STANDARD_PACKAGE_HEADER
	REXX_CURRENT_INTERPRETER_VERSION,	// ooRexx version at compilation time or higher
	"ooRexx API",						// name of the package
	"1.0.0",							// package information
	NULL,								// no load function
	NULL,								// no unload function
	oorexxapi_functions,				// the exported routines
	NULL								// the exported methods
};

// package loading stub.
OOREXX_GET_PACKAGE(oorexxapi);
