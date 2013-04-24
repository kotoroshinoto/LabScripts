'''
Created on Mar 18, 2013

@author: Gooch
'''
import unittest

from Pipeline.PipelineSampleData import SampleData 
class SampleDataTest(unittest.TestCase):
    def setUp(self):
        #might not need this, runs before each test
        pass
    def tearDown(self):
        #might not need this, runs after each test
        pass
    def testSingleManyColumns(self):
        pass
    def testSingleFewColumns(self):
        pass
    def testPairedManyColumns(self):
        pass
    def testPairedFewColumns(self):
        pass
    def testEmptyFile(self):
        pass
    def testIgnoresBlankLines(self):
        pass
    def testDuplicateEntrySingle(self):
        pass
    def testDuplicateEntryPaired(self):
        pass
    def testDuplicateEntryMixed1(self):
        pass
    def testDuplicateEntryMixed2(self):
        pass
    def testValidSingle(self):
        pass
    def testValidPaired(self):
        pass
if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    unittest.main()