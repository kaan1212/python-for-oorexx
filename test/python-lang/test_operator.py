'''
operator — Standard operators as functions

See:
https://docs.python.org/3/library/operator.html
https://docs.python.org/3/library/operator.html#mapping-operators-to-functions

https://docs.python.org/3/reference/datamodel.html#emulating-container-types
'''

import unittest
import operator


class OperatorTestCase(unittest.TestCase):

    def test_containment(self):
        # >>> list = [1, 2, 3]
        # >>> 1 in list
        # True

        list = [1, 2, 3]
        outcome = operator.contains(list, 1)
        self.assertTrue(outcome)

    def test_indexed_assignment(self):
        # >>> list = [1, 2, 3]
        # >>> list[0] = 10

        list = [1, 2, 3]
        operator.setitem(list, 0, 10)
        self.assertSequenceEqual(list, [10, 2, 3])

    def test_indexed_deletion(self):
        # >>> list = [1, 2, 3]
        # >>> del list[0]

        list = [1, 2, 3]
        operator.delitem(list, 0)
        self.assertSequenceEqual(list, [2, 3])

    def test_indexing(self):
        # >>> list = [1, 2, 3]
        # >>> list[0]
        # 1

        list = [1, 2, 3]
        value = operator.getitem(list, 0)
        self.assertEqual(value, 1)

    def test_slice_assignment(self):
        # >>> list = [1, 2, 3]
        # >>> list[0:2] = [10, 20]

        list = [1, 2, 3]
        operator.setitem(list, slice(0, 2), [10, 20])
        self.assertSequenceEqual(list, [10, 20, 3])

    def test_slice_deletion(self):
        # >>> list = [1, 2, 3]
        # >>> del list[0:2]

        list = [1, 2, 3]
        operator.delitem(list, slice(0, 2))
        self.assertSequenceEqual(list, [3])

    def test_slicing(self):
        # >>> list = [1, 2, 3]
        # >>> list[0:2]
        # [1, 2]

        list = [1, 2, 3]
        list = operator.getitem(list, slice(0, 2))
        self.assertSequenceEqual(list, [1, 2])


if __name__ == '__main__':
    unittest.main()
