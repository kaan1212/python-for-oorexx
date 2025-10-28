import builtins
import importlib
import sys


debug_enabled = False
registry = {}


# Public.
def get_corresponding_python_methodnames(classname, methodnames):
    _class = resolve_function(classname)
    methodnames = [m.lower() for m in methodnames]

    result = []

    for m in methodnames:
        for n in dir(_class):
            if m == n.lower():
                result.append(n)

    return result


# Public.
def set_globals(key, value):
    globals()[key] = value


# Public.
def store_object(object):
    identity = id(object)
    registry[identity] = object
    return str(identity)


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
def get_builtin_constant_id(name):
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
    object = registry[identity]
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

    if callable(function):
        object = invoke_function_with_arguments(function, arguments)
    else:
        object = function

    identity = id(object)
    registry[identity] = object

    return str(identity)


# Public.
def invoke_method(identity, name, arguments):
    identity = int(identity)
    object = registry[identity]
    name = name.lower()

    if name.endswith('='):
        name = name[:-1]
        value = arguments[0]
        setattr(object, name, value)
    else:
        try:
            value = getattr(object, name)
        except AttributeError as err:
            print('AttributeError:', err)

        if callable(value):
            value = invoke_function_with_arguments(value, arguments)

    identity = id(value)
    registry[identity] = value

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
    if contains_caseless(globals(), name):
        value = getitem_caseless(globals(), name)
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
def contains_caseless(dict, key):
    key = key.lower()
    matches = [k for k in dict.keys() if k.lower() == key]

    match len(matches):
        case 1:
            return True
        case 0:
            return False
        case _:
            print(f'Error: dict has no unambiguous key {key}: {matches}')
            sys.exit(1)


# Private.
def getitem_caseless(dict, key):
    key = key.lower()
    matches = [k for k in dict.keys() if k.lower() == key]

    match len(matches):
        case 1:
            return dict[matches[0]]
        case 0:
            return None
        case _:
            print(f'Error: dict has no unambiguous key {key}: {matches}')
            sys.exit(1)


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
