from types import ModuleType
import builtins
import importlib


objects = {}


# Public.
def get_builtin_constant_identity(name):
    constant = get_builtin_constant(name)
    identity = id(constant)

    return str(identity)


# Public.
def get_builtin_constant(name):
    constant = None

    match name:
        case 'False': constant = False
        case 'True': constant = True
        case _: constant = None

    return constant


# Public.
def invoke_str(identity):
    identity = int(identity)
    object = objects[identity]
    return str(object)


# Public.
def invoke_import(module_name):
    globals()[module_name] = importlib.import_module(module_name)


# Public.
def invoke_function(name, arguments):
    name = name.lower()
    function = resolve_function(name)
    object = invoke_function_with_arguments(function, arguments)

    identity = id(object)
    objects[identity] = object

    return str(identity)


# Public.
def invoke_method(identity, name, arguments):
    identity = int(identity)
    name = name.lower()
    object = objects[identity]
    function = getattr(object, name)

    object = invoke_function_with_arguments(function, arguments)
    identity = id(object)
    objects[identity] = object

    return str(identity)


# Private.
def resolve_function(name):
    if name in globals():
        # Resolve a user-defined function.
        function = globals()[name]
    elif hasattr(builtins, name):
        # Resolve a built-in function.
        function = getattr(builtins, name)
    else:
        # Resolve a module function.
        for object in globals().values():
            if isinstance(object, ModuleType) and hasattr(object, name):
                function = getattr(object, name)
                break

    return function


# Private.
def invoke_function_with_arguments(function, arguments):
    if contains_kwargs(arguments):
        args = arguments[:-1]
        kwargs = arguments[-1]

        kwargs = kwargs.copy()
        del kwargs['kwargs']

        return function(*args, **kwargs)
    else:
        return function(*arguments)


# Private.
def contains_kwargs(args):
    if args:
        last_arg = args[-1]
        return isinstance(last_arg, dict) and 'kwargs' in last_arg
    else:
        return False
