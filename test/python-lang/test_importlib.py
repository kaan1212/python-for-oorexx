'''
importlib — The implementation of import

See:
https://docs.python.org/3/library/importlib.html
https://docs.python.org/3/library/importlib.html#importlib.import_module

https://docs.python.org/3/library/sys.html#sys.modules
https://docs.python.org/3/library/builtins.html#module-builtins
'''

import unittest
import importlib
import sys
from types import BuiltinFunctionType, FunctionType


class ImportlibTestCase(unittest.TestCase):

    def test_import_function(self):
        # importlib.import_module() function stores the module only in the sys.modules dictionary.

        module_name = 'csv'

        self.assertNotIn(module_name, globals())
        self.assertNotIn(module_name, locals())
        self.assertNotIn(module_name, sys.modules)

        importlib.import_module(module_name)

        self.assertNotIn(module_name, globals())
        self.assertNotIn(module_name, locals())
        self.assertIn(module_name, sys.modules)

    def test_import_statement(self):
        # import statement stores the module only in the locals() and sys.modules dictionary.

        module_name = 'datetime'

        self.assertNotIn(module_name, globals())
        self.assertNotIn(module_name, locals())
        self.assertNotIn(module_name, sys.modules)

        import datetime

        self.assertNotIn(module_name, globals())
        self.assertIn(module_name, locals())
        self.assertIn(module_name, sys.modules)

    def test_reload(self):
        # importlib.import_module() does not import already imported modules, but importlib.reload() does.

        module_name = 'foo.bar.baz'
        function_name = 'auto_increment'

        module = importlib.import_module(module_name)
        function = getattr(module, function_name)
        self.assertEqual(function(), 1)
        self.assertEqual(function(), 2)

        module = importlib.import_module(module_name)
        function = getattr(module, function_name)
        self.assertEqual(function(), 3)
        self.assertEqual(function(), 4)

        module = importlib.reload(module)
        function = getattr(module, function_name)
        self.assertEqual(function(), 1)
        self.assertEqual(function(), 2)

    def test_user_function_1(self):
        # >>> foo()
        # 'bar'

        module_name = __name__
        function_name = 'foo'

        module = importlib.import_module(module_name)
        function = getattr(module, function_name)

        self.assertIsInstance(function, FunctionType)
        self.assertEqual(function(), 'bar')

    def test_user_function_2(self):
        # >>> foo()
        # 'bar'

        function_name = 'foo'
        function = globals()[function_name]

        self.assertIsInstance(function, FunctionType)
        self.assertEqual(function(), 'bar')

    def test_user_module(self):
        # >>> import foo.bar.baz
        # >>> foo.bar.baz.qux()
        # 'quux'

        module_name = 'foo.bar.baz'
        function_name = 'qux'

        module = importlib.import_module(module_name)
        function = getattr(module, function_name)

        self.assertIsInstance(function, FunctionType)
        self.assertEqual(function(), 'quux')

    def test_builtin_function_1(self):
        # >>> abs(-1)
        # 1

        module_name = 'builtins'
        function_name = 'abs'

        module = importlib.import_module(module_name)
        function = getattr(module, function_name)

        self.assertIsInstance(function, BuiltinFunctionType)
        self.assertEqual(function(-1), 1)

    def test_builtin_function_2(self):
        # >>> abs(-1)
        # 1

        function_name = 'abs'

        import builtins
        function = getattr(builtins, function_name)

        self.assertIsInstance(function, BuiltinFunctionType)
        self.assertEqual(function(-1), 1)

    def test_builtin_function_3(self):
        # >>> abs(-1)
        # 1

        function_name = 'abs'

        module = __builtins__
        function = getattr(module, function_name)

        self.assertIsInstance(function, BuiltinFunctionType)
        self.assertEqual(function(-1), 1)

    def test_stdlib_function(self):
        # >>> import urllib.parse
        # >>> urllib.parse.urljoin('https://www.python.org', 'about/')
        # 'https://www.python.org/about/'

        module_name = 'urllib.parse'
        function_name = 'urljoin'

        module = importlib.import_module(module_name)
        function = getattr(module, function_name)

        url = function('https://www.python.org', 'about/')

        self.assertIsInstance(function, FunctionType)
        self.assertEqual(url, 'https://www.python.org/about/')

    def test_stdlib_class(self):
        # >>> import io
        # >>>
        # >>> output = io.StringIO()
        # >>> output.write('First line.\n')
        # >>> print('Second line.', file=output)
        # >>>
        # >>> output.getvalue()
        # 'First line.\nSecond line.\n'
        # >>>
        # >>> output.close()

        module_name = 'io'
        class_name = 'StringIO'

        module = importlib.import_module(module_name)
        cls = getattr(module, class_name)

        output = cls()
        output.write('First line.\n')
        print('Second line.', file=output)
        contents = output.getvalue()
        output.close()

        import io
        self.assertEqual(cls, io.StringIO)
        self.assertEqual(contents, 'First line.\nSecond line.\n')


def foo():
    return 'bar'


if __name__ == '__main__':
    unittest.main()
