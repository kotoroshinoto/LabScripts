'''
Created on Mar 18, 2013

@author: Gooch
'''
import unittest
from PipelineErrorTest import PipelineErrorTest
from PipelineSampleDataTest import SampleDataTest  
from PipelineSubStepTest import PipelineSubStepTest  
from PipelineStepTest import PipelineStepTest 
from AnalysisPipelineTest import AnalysisPipelineTest  

if __name__ == "__main__":
    #import sys;sys.argv = ['', 'Test.testName']
    Tests=unittest.TestSuite()
    testlist=[]
    testlist.append(unittest.TestLoader().loadTestsFromTestCase(PipelineErrorTest))
    testlist.append(unittest.TestLoader().loadTestsFromTestCase(SampleDataTest))
    testlist.append(unittest.TestLoader().loadTestsFromTestCase(PipelineSubStepTest))
    testlist.append(unittest.TestLoader().loadTestsFromTestCase(PipelineStepTest))
    testlist.append(unittest.TestLoader().loadTestsFromTestCase(AnalysisPipelineTest))
    Tests.addTests(testlist)
    unittest.TextTestRunner(verbosity=2).run(Tests)