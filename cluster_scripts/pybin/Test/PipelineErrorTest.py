'''
Created on Mar 18, 2013

@author: Gooch
'''
import unittest

from Pipeline.PipelineError import PipelineError 
class PipelineErrorTest(unittest.TestCase):
    def testErrorBlank(self):
        try:
            raise PipelineError()
        except PipelineError as error:
            self.assertEqual(error.msg,"[Pipeline Error]: unspecified error")
    def testErrorMsg(self):
        try:
            raise PipelineError("TEST MESSAGE")
        except PipelineError as error:
            self.assertEqual(error.msg,"TEST MESSAGE")
if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testErrorBlank']
    unittest.main()