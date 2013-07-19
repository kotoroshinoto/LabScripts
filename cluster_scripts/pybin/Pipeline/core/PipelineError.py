#!/usr/bin/env python
'''
Created on Mar 18, 2013

@author: Gooch
'''
class PipelineError(Exception):
    def __init__(self, msg=None, err=True):
        self.msg=""
        if msg is not None:
            super(PipelineError,self).__init__(msg)
            self.msg=msg
        else:
            super(PipelineError,self).__init__("[Pipeline Error]: unspecified error")
            self.msg="[Pipeline Error]: unspecified error"