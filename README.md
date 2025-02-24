# What is Python for ooRexx?

Python for ooRexx is a library to enable ooRexx to interact with Python classes, objects, and functions.

It connects the ooRexx C++ API with the Python/C API.

The idea for this library came from [Prof. Dr. Rony G. Flatscher](https://ronyrexx.net/), who is the original author of [BSF4ooRexx](https://sourceforge.net/projects/bsf4oorexx/) – a bidirectional bridge between Java and ooRexx.

# Limitations

This library is under active development. Therefore, breaking changes are currently not avoidable.

The ultimate goal is to support Linux, macOS, Windows operating systems, the Python standard library, and Python packages installed with pip.
However, the library is currently developed and tested on Windows only, and only the Python standard library is supported at present.

# Requirements

* Windows 10 or later
* [ooRexx 5.1.0](https://sourceforge.net/projects/oorexx/files/oorexx/)
* [Python 3.12.x](https://www.python.org/downloads/windows/)
* Python for ooRexx: `PyRexx.cls`, `PyRexx.dll`, and `pyrexx.py`.

Other versions of Windows, ooRexx and Python 3 might work, but have not been explicitly tested.

The three files required for Python for ooRexx can be downloaded from this repository. `PyRexx.dll` was built with Python 3.12.7.
`PyRexx.dll` is forward- and backwards-compatible across a minor release of Python.
So, `PyRexx.dll` compiled for Python 3.12.7 will work on 3.12.0 and vice versa, but will need to be compiled separately for 3.11.x and 3.13.x.

Backward and forward compatibility will be improved in future releases.

# Setup

**Environment variables**

Path: `PyRexx.dll` must be able to find the local installation of Python. Therefore, add the installation directory to the `Path` environment variable. On a Windows system, the installation directory typically defaults to `C:\Users\Username\AppData\Local\Programs\Python\Python312`.

PYTHONPATH: `PyRexx.dll` must also be able to find the `pyrexx.py` module, which will be located in the same directory. Therefore, create a new environment variablee `PYTHONPATH` and set its value to `.` (dot).

**Files**

Optional: If you want to make Python for ooRexx globally available, put `PyRexx.cls`, `PyRexx.dll`, and `pyrexx.py` into your ooRexx installation directory. On a Windows system, the installation directory typically defaults to `C:\Program Files\oorexx`. The tutorial below will use a local copy of these files.

# Tutorial

Create a new directory and put a copy of `PyRexx.cls`, `PyRexx.dll`, and `pyrexx.py` into it. Create a new file `hello.rex` and put the following contents to it:

```
py = .PyRexx~new()
py~print('hello, world')

::requires 'PyRexx.cls'
```

To run the example in the command-line, just type:

    > rexx hello

This will use Python's built-in function [print](https://docs.python.org/3/library/functions.html#print) to display `hello, world` on the screen.

A good place to learn about more advanced usage are the [unit tests](test/stdlib) for the Python standard library.

# Build

This library has been successfully built with MSYS2 version 20241208.

1. Download and install [MSYS2](https://www.msys2.org/).
2. In the MSYS2 terminal run the following command: `$ pacman -S --needed base-devel mingw-w64-ucrt-x86_64-toolchain`
3. Clone or download this Git repository.
4. Edit `make.cmd` to adjust the variables to your system's settings.
5. Run `make.cmd` in the Widows command-line.

# Test

Python for ooRexx comes with a minimal version of ooRexxUnit.

From the Git repository move the `Lib` directory and the `PythonXYZ.dll` file to some other place to enable the use of the system's local Python installation.

Unfortunately, due to a yet to be solved bug regarding the Python datetime module, its test group has to be executed seperatly.

To run all other test groups in the command-line, just type:

    C:\python-for-oorexx>rexx testOORexx -R test -x datetime.testGroup

To run a specific test group, just type:

    C:\python-for-oorexx>rexx testOORexx -R test -f datetime.testGroup
