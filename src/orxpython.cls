-- orxpython.dll
::requires 'orxpython' library


::routine unbox public
    use arg pythonObject

    type = .Python~new~type(pythonObject)~__name__~py.fromPythonString

    select case type
        when 'NoneType' then return .nil
        when 'bool' then return pythonObject~py.fromPythonString == 'True'
        when 'int', 'float', 'str' then return pythonObject~py.fromPythonString
        otherwise return pythonObject
    end


::class 'Python' public
    ::attribute False get
    ::attribute True get
    ::attribute None get

    ::attribute pythonObjectRegistry get private

    ::method init
        expose False True None pythonObjectRegistry
        pythonObjectRegistry = .StringTable~new

        debug = .false
        call PyRexx_Initialize 'orxpython', debug

        False = self~getPythonProxyObject(PyRexx_CallFunction('get_builtin_constant_identity', 'False'))
        True = self~getPythonProxyObject(PyRexx_CallFunction('get_builtin_constant_identity', 'True'))
        None = self~getPythonProxyObject(PyRexx_CallFunction('get_builtin_constant_identity', 'None'))
        /* Alternative:
        False = self~callFunction('get_builtin_constant', 'False')
        True = self~callFunction('get_builtin_constant', 'True')
        None = self~callFunction('get_builtin_constant', 'None')
        */

        -- Import Python standard operators ([key], [start:stop:step], del, in) as functions.
        self~import('operator')

    ::method import
        use arg name
        call PyRexx_CallFunction 'invoke_import', name

    ::method from
        use arg name
        return .PythonFromClause~new(name)

    ::method unknown
        use arg name, args

        if name~dataType() == 'NUM' then
            return self~callFunction('int', name)

        return self~callFunction(name, args)

    ::method callFunction
        use arg name, args

        if \ args~isA(.Array) then
            args = arg(2, 'Array')

        identity = PyRexx_CallFunction('invoke_function', .Array~of(name, args))

        return self~getPythonProxyObject(identity)

    ::method callMethod
        use arg identity, name, args

        if \ args~isA(.Array) then
            args = arg(3, 'Array')

        identity = PyRexx_CallFunction('invoke_method', .Array~of(identity, name, args))

        return self~getPythonProxyObject(identity)

    ::method getPythonProxyObject private
        expose pythonObjectRegistry
        use arg identity

        if \ pythonObjectRegistry~hasIndex(identity) then
            pythonObjectRegistry[identity] = .PythonObject~new(self, identity)

        return pythonObjectRegistry[identity]

    ::method kwd
        use arg keyword, value

        kwargs = self~kwargs
        kwargs[keyword] = value

        return kwargs

    ::method kwargs
        use arg dict=(self~callFunction('dict'))

        -- Mark this dictionary for storing keyword arguments.
        dict['kwargs'] = 'kwargs'

        return dict

    ::method '[]'
        list = self~callFunction('list')

        do i=1 to arg()
            list~append(arg(i))
        end

        return list

    ::method escape
        -- See: https://docs.python.org/3/reference/lexical_analysis.html#escape-sequences
        use arg string
        return string,
            ~changeStr('\n', .String~nl),
            ~changeStr('\t', .String~tab)

    ::method defineClass
        use arg rexxClassOrObject, pythonBaseClassName

        if rexxClassOrObject~isInstanceOf(.Class) then do
            args = arg(3, 'Array')

            rexxClass = rexxClassOrObject
            rexxObject = rexxClass~sendWith('new', args)
        end
        else do
            rexxObject = rexxClassOrObject
            rexxClass = rexxObject~class
        end

        rexxMethodNames = rexxObject~instanceMethods(rexxClass)~allIndexes
        pythonMethodNames = self~callFunction('get_corresponding_python_methodnames', pythonBaseClassName, rexxMethodNames)

        pythonMethodNamesUnboxed = .Array~new

        do pythonMethodName over pythonMethodNames
            pythonMethodNamesUnboxed~append(unbox(pythonMethodName))
        end

        rexxClassName = rexxClass~id
        call PyRexx_DefineClass rexxObject, rexxClassName, pythonBaseClassName, pythonMethodNamesUnboxed, self


::class 'PythonObject'
    ::attribute runtime get private
    ::attribute identity get

    ::method init
        expose runtime identity
        use arg runtime, identity

    ::method unknown
        expose runtime identity
        use arg name, args
        return runtime~callMethod(identity, name, args)

    ::method py.fromPythonString
        expose identity
        return PyRexx_CallFunction('invoke_str', identity)

    ::method makeArray
        expose runtime

        -- Materialize len for performance.
        len = unbox(runtime~callFunction('len', self))
        array = .Array~new(len)

        do i=0 to len-1
            index = runtime~callFunction('int', i)
            array~append(self[index])
        end

        return array

    ::method '='
        use arg b
        a = self~makeString
        return a = b

    ::method '[]='
        expose runtime
        use arg value, key

        -- Indexing.
        return runtime~callFunction('operator.setitem', self, key, value)

    ::method '[]'
        expose runtime

        -- Indexing.
        if arg() == 1 then
            return runtime~callFunction('operator.getitem', self, arg(1))

        /*
            Slicing.

            Python implementation detail:
            "a[1:2] = b
            is translated to
            a[slice(1, 2, None)] = b
            Missing slice items are always filled with None."
            See: https://docs.python.org/3/reference/datamodel.html#object.__length_hint__
        */
        use arg start=.nil, stop=.nil, step=.nil
        slice = runtime~callFunction('slice', start, stop, step)
        return self[slice]


::class 'PythonFromClause'
    ::method init
        expose name
        use arg name

    ::method import
        expose name
        fromlist = arg(1, 'Array')
        call PyRexx_CallFunction 'invoke_from_import', .Array~of(name, fromlist)
