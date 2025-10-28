-- orxpython.dll
::requires 'orxpython' library


::routine unbox public
    use arg pythonObject

    type = .Python~type(pythonObject)~__name__~py.fromPythonString

    select case type
        when 'NoneType' then return .nil
        when 'bool' then return pythonObject~py.fromPythonString == 'True'
        when 'int', 'float', 'str' then return pythonObject~py.fromPythonString
        otherwise return pythonObject
    end


::class 'Python' public
    ::attribute False class get
    ::attribute True class get
    ::attribute None class get

    ::attribute pythonObjectRegistry class get private

    ::method activate class
        use local debug
        debug = .false

        pythonObjectRegistry = .StringTable~new

        call PyRexx_Initialize 'orxpython', debug

        False = self~getPythonProxyObject(PyRexx_CallFunction('get_builtin_constant_id', 'False'))
        True = self~getPythonProxyObject(PyRexx_CallFunction('get_builtin_constant_id', 'True'))
        None = self~getPythonProxyObject(PyRexx_CallFunction('get_builtin_constant_id', 'None'))
        /* Alternative:
        False = self~callFunction('get_builtin_constant', 'False')
        True = self~callFunction('get_builtin_constant', 'True')
        None = self~callFunction('get_builtin_constant', 'None')
        */

        -- Import Python standard operators ([key], [start:stop:step], del, in) as functions.
        self~import('operator')

    ::method id class
        use arg pythonObject

        if arg() == 0 then
            return self~id:super
        else
            return self~callFunction('id', pythonObject)

    ::method import class
        use arg name
        call PyRexx_CallFunction 'invoke_import', name

    ::method from class
        use arg name
        return .PythonFromClause~new(name)

    ::method unknown class
        use arg name, args
        return self~callFunction(name, args)

    ::method callFunction class
        use arg name, args

        if \ args~isA(.Array) then
            args = arg(2, 'Array')

        id = PyRexx_CallFunction('invoke_function', .Array~of(name, args))

        return self~getPythonProxyObject(id)

    ::method callMethod class
        use arg id, name, args

        if \ args~isA(.Array) then
            args = arg(3, 'Array')

        id = PyRexx_CallFunction('invoke_method', .Array~of(id, name, args))

        return self~getPythonProxyObject(id)

    ::method getPythonProxyObject class private
        expose pythonObjectRegistry
        use arg id

        if \ pythonObjectRegistry~hasIndex(id) then
            pythonObjectRegistry[id] = .PythonObject~new(id)

        return pythonObjectRegistry[id]

    ::method kwd class
        use arg keyword, value

        kwargs = self~kwargs
        kwargs[keyword] = value

        return kwargs

    ::method kwargs class
        use arg dict=(self~callFunction('dict'))

        -- Mark this dictionary for storing keyword arguments.
        dict['kwargs'] = 'kwargs'

        return dict

    ::method py.listOf class
        list = self~callFunction('list')

        do i=1 to arg()
            list~append(arg(i))
        end

        return list

    ::method escape class
        -- See: https://docs.python.org/3/reference/lexical_analysis.html#escape-sequences
        use arg string
        return string,
            ~changeStr('\n', .String~nl),
            ~changeStr('\t', .String~tab)

    ::method defineClass class
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
        call PyRexx_DefineClass rexxObject, rexxClassName, pythonBaseClassName, pythonMethodNamesUnboxed


::class 'PythonObject'
    ::attribute id get

    ::method init
        expose id
        use arg id

    ::method objectName
        type = unbox(.Python~type(self)~__name__)
        id = unbox(.Python~id(self))

        return type || '@' || id

    ::method unknown
        expose id
        use arg name, args
        return .Python~callMethod(id, name, args)

    ::method py.fromPythonString
        expose id
        return PyRexx_CallFunction('invoke_str', id)

    ::method makeArray
        -- Materialize len for performance.
        len = unbox(.Python~callFunction('len', self))
        array = .Array~new(len)

        do i=0 to len-1
            index = .Python~callFunction('int', i)
            array~append(self[index])
        end

        return array

    ::method '='
        use arg b
        a = self~makeString
        return a = b

    ::method '[]='
        use arg value, key

        -- Indexing.
        return .Python~callFunction('operator.setitem', self, key, value)

    ::method '[]'
        -- Indexing.
        if arg() == 1 then
            return .Python~callFunction('operator.getitem', self, arg(1))

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
        slice = .Python~callFunction('slice', start, stop, step)
        return self[slice]


::class 'PythonFromClause'
    ::method init
        expose name
        use arg name

    ::method import
        expose name
        fromlist = arg(1, 'Array')
        call PyRexx_CallFunction 'invoke_from_import', .Array~of(name, fromlist)
