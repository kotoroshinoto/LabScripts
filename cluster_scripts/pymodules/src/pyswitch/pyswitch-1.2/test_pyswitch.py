try:
    import unittest2 as unittest
except ImportError:
    import unittest

import re
from pyswitch import Switch, SwitchError

class TestSwitch(unittest.TestCase):

    def test_unknown(self):
        mySwitch = Switch()
        
        with self.assertRaises(SwitchError) as ec:
            mySwitch.switch(1)
        self.assertIn('1', ec.exception.message)
        
        with self.assertRaises(SwitchError) as ec:
            mySwitch.switch('oops')
        self.assertIn('oops', ec.exception.message)
            
    def test_dupcase(self):
        mySwitch = Switch()
        
        @mySwitch.case(1)
        def gotOne(value):
            return value
        
        with self.assertRaises(SwitchError) as ec:
            @mySwitch.case(1)
            def gotAnotherOne(value):
                return value
        self.assertIn('Duplicate', ec.exception.message)
        
        @mySwitch.caseRegEx('hi.*')
        def gotRegex(value):
            return value
        
        with self.assertRaises(SwitchError) as ec:
            @mySwitch.caseRegEx('hi.*')
            def gotAnotherRegex(value):
                return value
        self.assertIn('Duplicate', ec.exception.message)
        
        @mySwitch.caseIn('hi')
        def gotHi(value):
            return value
        
        with self.assertRaises(SwitchError) as ec:
            @mySwitch.caseIn('hi')
            def gotAnotherHi(value):
                return value
        self.assertIn('Duplicate', ec.exception.message)
        
    def test_exact(self):
        mySwitch = Switch()
        
        @mySwitch.case(1)
        def got1(value):
            return ('got1', value)
        
        @mySwitch.case(2)
        def got2(value):
            return ('got2', value)
        
        @mySwitch.case('three')
        def gotThree(value):
            return ('gotThree', value)
        
        @mySwitch.case(4)
        def got4(value):
            return ('got4', value)
            
        self.assertEqual(mySwitch.switch(1), ('got1', 1))
        self.assertEqual(mySwitch.switch(2), ('got2', 2))
        self.assertEqual(mySwitch.switch('three'), ('gotThree', 'three'))
        self.assertEqual(mySwitch.switch(4), ('got4', 4))
        with self.assertRaises(SwitchError):
            mySwitch.switch(0)
            mySwitch.switch(3)
            mySwitch.switch(5)
        
    def test_exact_sequence(self):
        mySwitch = Switch()
        
        @mySwitch.case([1, 2, 3])
        def got1thru3(value):
            return ('got1thru3', value)
        
        @mySwitch.case(4)
        def got4(value):
            return ('got4', value)
        
        @mySwitch.case([6, 7])
        def got6thru7(value):
            return ('got6thru7', value)
        
        self.assertEqual(mySwitch.switch(1), ('got1thru3', 1))
        self.assertEqual(mySwitch.switch(2), ('got1thru3', 2))
        self.assertEqual(mySwitch.switch(3), ('got1thru3', 3))
        self.assertEqual(mySwitch.switch(4), ('got4', 4))
        self.assertEqual(mySwitch.switch(6), ('got6thru7', 6))
        self.assertEqual(mySwitch.switch(7), ('got6thru7', 7))
        with self.assertRaises(SwitchError):
            mySwitch.switch(0)
            mySwitch.switch(5)
            myswitch.switch(8)

    def test_regex_single(self):
        mySwitch = Switch()
        
        @mySwitch.caseRegEx('th.*')
        def gotA(matchObj):
            return ('gotA', matchObj.group(0))
        
        @mySwitch.caseRegEx(re.compile('bar$'))
        def gotB(matchObj):
            return ('gotB', matchObj.group(0))
        
        self.assertEqual(mySwitch.switch('thesis'), ('gotA', 'thesis'))
        self.assertEqual(mySwitch.switch('foobar'), ('gotB', 'bar'))
        
        with self.assertRaises(SwitchError):
            mySwitch.switch('barfoo')
            
    def test_in_str(self):
        mySwitch = Switch()
        
        @mySwitch.caseIn('lol')
        def gotLOL(value):
            return ('gotLOL', value)
        
        self.assertEqual(mySwitch.switch('frololic'), ('gotLOL', 'lol'))
        
    def test_in_sequence(self):
        mySwitch = Switch()
        
        @mySwitch.caseIn('lol')
        def gotLOL(value):
            return ('gotLOL', value)
        
        self.assertEqual(mySwitch.switch(['foo', 'lol', 'bar']),
                         ('gotLOL', 'lol'))
         
    def test_defaultHandler(self):
        mySwitch = Switch()
        
        @mySwitch.default
        def gotDefault(value):
            return ('gotDefault', value)
        
        self.assertEqual(mySwitch.switch(1), ('gotDefault', 1))
        
    def test_additionalInfo(self):
        mySwitch = Switch()
       
        @mySwitch.case(1)
        def gotOne(value, *args, **kwargs):
            return ('gotOne', value, args, kwargs)
        
        self.assertEqual(mySwitch.switch(1, 'foo', bar=True), ('gotOne', 1, ('foo',), {'bar': True}))
        
    def test_mixed(self):
        mySwitch = Switch()
        
        @mySwitch.default
        def gotDefault(value, *args, **kwargs):
            return ('gotDefault', value, args, kwargs)
         
        @mySwitch.case(1)
        def got1(value, *args, **kwargs):
            return ('got1', value, args, kwargs)
        
        @mySwitch.caseIn('hell')
        def getHell(value, *args, **kwargs):
            return ('gotHell', value, args, kwargs)
        
        @mySwitch.case(range(10, 15))
        def gotRange10to15(value, *args, **kwargs):
            return ('gotRange10to15', value, args, kwargs)
        
        @mySwitch.case([ 99, 'hundred' ])
        def gotStuff(value, *args, **kwargs):
            return ('gotStuff', value, args, kwargs)
        
        @mySwitch.caseRegEx('ten.*')
        def gotTenDotStar(matchObj, *args, **kwargs):
            return ('gotTenDotStar', matchObj.group(0), args, kwargs)
        
        self.assertEqual(mySwitch.switch(1, 1.5), ('got1', 1, (1.5,), {}))
        self.assertEqual(mySwitch.switch(11, key='hi'), ('gotRange10to15', 11, (), {'key': 'hi'}))
        self.assertEqual(mySwitch.switch(5, 'oops'), ('gotDefault', 5, ('oops',), {}))
        self.assertEqual(mySwitch.switch('tennison', profession='poet'), ('gotTenDotStar', 'tennison', (), {'profession': 'poet'}))
        self.assertEqual(mySwitch.switch('well, hello there'), ('gotHell', 'hell', (), {}))
        
    def test_call(self):
        mySwitch = Switch()
        
        @mySwitch.case(1)
        def got1(value, *args, **kwargs):
            return ('got1', value, args, kwargs)
        
        self.assertEqual(mySwitch(1), ('got1', 1, (), {}))
                        
        
if __name__ == '__main__':
    unittest.main()
