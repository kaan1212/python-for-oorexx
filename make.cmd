@REM By default, the ooRexx installer sets the environment variable REXX_HOME to C:\Program Files\oorexx for all users.
set OOREXX_PATH="%REXX_HOME%"

set PYTHON_PATH=C:\Users\%USERNAME%\AppData\Local\Programs\Python\Python312
set PYTHON_LIBRARY=python312

rm --force PyRexx.dll
rm --force %PYTHON_LIBRARY%.dll

g++ -shared -o PyRexx.dll PyRexx.cpp ^
    -I%OOREXX_PATH%\api ^
    -I%PYTHON_PATH%\include -L%PYTHON_PATH%\libs -l%PYTHON_LIBRARY%

copy %PYTHON_PATH%\%PYTHON_LIBRARY%.dll %PYTHON_LIBRARY%.dll
