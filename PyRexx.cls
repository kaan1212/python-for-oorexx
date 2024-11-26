-- PyRexx.dll
::requires 'PyRexx' library

::class PythonConstant
    -- Singleton.

    ::constant False (.PythonConstant~new('bool', 'False', .false))
    ::constant True (.PythonConstant~new('bool', 'True', .true))
    ::constant None (.PythonConstant~new('NoneType', 'None', .nil))

    ::attribute pythonType get
    ::attribute pythonValue get
    ::attribute rexxValue get private

    ::method init private
        expose pythonType pythonValue rexxValue
        use arg pythonType, pythonValue, rexxValue

    ::method '='
        expose rexxValue
        use arg b
        return b = rexxValue

    ::method makeString
        expose rexxValue
        return rexxValue

::class PyRexx public
    ::constant False (.PythonConstant~False)
    ::constant True (.PythonConstant~True)
    ::constant None (.PythonConstant~None)

    ::method init
        call InitPython

        -- Import Python standard operators ([key], [start:stop:step], del, in) as functions.
        self~import('operator')

    ::method import
        use arg name
        call ImportPythonModule name

    ::method unknown
        use arg name, arguments
        return self~callFunction(name, arguments)

    ::method callFunction
        use arg name, arguments

        if arg() == 1 then
            arguments = .Array~new

        request = buildRequest('', name, arguments)
        response = CallPythonFunction(request)

        return getReturnValue(self, response)

    ::method kwargs
        -- If a dictionary was passed, just return it.
        -- Otherwise return a new dictionary.
        dict = .nil

        if arg() == 1 then
            dict = arg(1)
        else
            dict = self~dict

        -- Mark this dictionary for storing keyword arguments.
        dict['kwargs'] = 'kwargs'

        return dict

    ::method '[]'
        -- Return an empty list.
        if arg() == 0 then
            return self~list

        -- Return a non-empty list.
        list = self~list

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

::class PythonInstance
    ::attribute context get private
    ::attribute identity get

    ::method init
        expose context identity
        use arg context, identity

    ::method unknown
        use arg name, arguments
        return self~callMethod(name, arguments)

    ::method callMethod
        expose context identity
        use arg name, arguments

        request = buildRequest(identity, name, arguments)
        response = CallPythonFunction(request)

        return getReturnValue(context, response)

    ::method makeString
        -- Call the Python object's special __str__() method
        -- to retrieve a nicely printable string representation.
        expose identity

        request = buildRequest(identity, '__str__', '')
        response = CallPythonFunction(request)

        if response = 'True' then
            return .true
        else if response = 'False' then
            return .false
        else if response = 'None' then
            return .nil
        else
            return response

    ::method '='
        use arg b
        a = self~makeString

        return a = b

    ::method '[]='
        expose context
        use arg value, key

        -- Indexing.
        return context~setitem(self, key, value)

    ::method '[]'
        expose context

        -- Indexing.
        if arg() == 1 then do
            key = arg(1)
            return context~getitem(self, key)
        end

        -- Slicing.
        -- See: https://docs.python.org/3/reference/datamodel.html#object.__length_hint__
        use arg start=.nil, stop=.nil, step=.nil
        slice = context~slice(start, stop, step)
        return self[slice]

::routine buildRequest
    -- Example: buildRequest('', 'print', 'hello, world') returns ';print;str;hello, world'

    use arg objectIdentity, callableName, callableArgs

    request = objectIdentity';'callableName

    do arg over callableArgs
        type = .nil
        value = .nil

        if arg == .nil then do
            type = .PythonConstant~None~pythonType
            value = .PythonConstant~None~pythonValue
        end
        else if arg~isA(.String) then do
            type = 'str'
            value = arg
        end
        else if arg~isA(.PythonConstant) then do
            type = arg~pythonType
            value = arg~pythonValue
        end
        else if arg~isA(.PythonInstance) then do
            type = 'ref'
            value = arg~identity
        end

        request = request';'type';'value
    end

    return request

::routine getReturnValue
    use arg context, response

    hasReturnValue = response \= 'NoneType;None'

    if hasReturnValue then
        return .PythonInstance~new(context, response)
    else
        return .nil
