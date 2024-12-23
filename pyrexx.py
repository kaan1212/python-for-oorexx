import builtins
import importlib
import sys


debug_enabled = False
objects = {}


# Public.
def debug_on():
    global debug_enabled
    debug_enabled = True


# Public.
def debug_off():
    global debug_enabled
    debug_enabled = False


# Private.
def debug(*args):
    if debug_enabled:
        print(*args)


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
def invoke_import(name):
    globals()[name] = importlib.import_module(name)


# Public.
def invoke_from_import(name, fromlist):
    module = __import__(name, globals(), locals(), fromlist, 0)

    for name in fromlist:
        globals()[name] = getattr(module, name)


# Public.
def invoke_function(name, arguments):
    function = resolve_function(name)
    object = invoke_function_with_arguments(function, arguments)

    identity = id(object)
    objects[identity] = object

    return str(identity)


# Public.
def invoke_method(identity, name, arguments):
    identity = int(identity)
    object = objects[identity]
    name = name.lower()

    try:
        value = getattr(object, name)
    except AttributeError as err:
        print('AttributeError:', err)

    if callable(value):
        value = invoke_function_with_arguments(value, arguments)

    identity = id(value)
    objects[identity] = value

    return str(identity)


# Private.
def resolve_function(name):
    name = name.lower()
    debug('Resolving', name)

    function = resolve_in_globals(name)

    if function != None:
        return function
    elif hasattr(builtins, name):
        debug('    Built-in identifier')
        return getattr(builtins, name)
    else:
        print('Function not found:', name)
        sys.exit(1)


# Private.
def resolve_in_globals(name):
    # Shortcut for exact match.
    if name in globals():
        value = globals()[name]
        debug('    globals():', name)
        return value
    elif '.' not in name:
        return None

    # Greedy search of possibly hierarchical module name in globals().
    # Example:
    #   datetime.datetime.now
    #   module.class.classmethod
    left = name
    while True:
        index = left.rfind('.')
        if index == -1:
            return None

        left = left[:index]
        if left in globals():
            value = globals()[left]
            debug('    globals():', value)
            break

    # Right part.
    right = name[len(left)+1:]

    for name in right.split('.'):
        value = getattr_caseless(value, name)
        debug('    Attribute:', value)

    return value


# Private.
def getattr_caseless(object, name):
    name = name.lower()
    matches = [attr for attr in dir(object) if attr.lower() == name]

    match len(matches):
        case 1:
            return getattr(object, matches[0])
        case 0:
            print(f'Error: {object} has no attribute {name}')
            sys.exit(1)
        case _:
            print(f'Error: {object} has no unambiguous attribute {name}: {matches}')  # nopep8
            sys.exit(1)


# Private.
def invoke_function_with_arguments(function, arguments):
    try:
        if contains_kwargs(arguments):
            args = arguments[:-1]
            kwargs = arguments[-1]

            kwargs = kwargs.copy()
            del kwargs['kwargs']

            return function(*args, **kwargs)
        else:
            return function(*arguments)
    except TypeError as err:
        print('TypeError:', err)
        sys.exit(1)


# Private.
def contains_kwargs(args):
    if args:
        last_arg = args[-1]
        return isinstance(last_arg, dict) and 'kwargs' in last_arg
    else:
        return False
