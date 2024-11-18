from types import ModuleType
import builtins


objects = {}


# Public.
def invoke_import(module_name):
    globals()[module_name] = __import__(module_name)
    return f'Imported {module_name}.'


# Public.
def invoke_function(request):
    '''
    Invokes dynamically functions and methods.
    '''

    # Parse request.
    object_identity, function_name, arguments = parse_request(request)

    if function_name == 'NoneType':
        return_value = None
    else:
        # Apply function invocation rewrites.
        function_name, arguments = apply_rewrites(function_name, arguments)

        # Resolve function.
        function = resolve_function(object_identity, function_name)

        # Invoke function with arguments.
        return_value = invoke_function_with_arguments(function, arguments)

    # Return None or object identity.
    return process_response(return_value, plain=function_name == '__str__')


# Private.
def parse_request(request):
    object_identity = None
    function_name = None
    arguments = []

    if request == ';NoneType':
        function_name = 'NoneType'
    else:
        token = request.split(';')
        object_identity = token[0]
        function_name = token[1].lower()

        for i in range(2, len(token), 2):
            arg_type = token[i]
            arg_value = token[i+1]

            match arg_type:
                case 'NoneType': arguments.append(None)
                case 'bool' if arg_value == 'True': arguments.append(True)
                case 'bool' if arg_value == 'False': arguments.append(False)
                case 'str': arguments.append(arg_value)
                case 'ref': arguments.append(objects[int(arg_value)])

    return object_identity, function_name, arguments


# Private.
def apply_rewrites(function_name, arguments):
    if function_name == '_slice':
        function_name = '__getitem__'
        s = slice(arguments[0], arguments[1], arguments[2])
        arguments = [s]

    return function_name, arguments


# Private.
def resolve_function(object_identity, function_name):
    if object_identity:
        # Resolve a method on an existing object.
        object = objects[int(object_identity)]

        function = getattr(object, function_name)
    elif function_name in globals():
        # Resolve a user-defined function.
        function = globals()[function_name]
    elif hasattr(builtins, function_name):
        # Resolve a built-in function.
        function = getattr(builtins, function_name)
    else:
        # Resolve a module function.
        for value in globals().values():
            if isinstance(value, ModuleType) and hasattr(value, function_name):
                function = getattr(value, function_name)
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


# Private.
def process_response(object, plain=False):
    if plain:
        return object
    elif object == None:
        return 'NoneType;None'
    else:
        objects[id(object)] = object
        return str(id(object))
