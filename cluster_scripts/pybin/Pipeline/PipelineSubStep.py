#!/usr/bin/env python
'''
Created on Mar 18, 2013

@author: Gooch
'''
import PipelineError,PipelineUtil
class PipelineSubStep:
    def __init__(self,parent):
        self.name= None;
        self.subname= None;#used when defining multiple jobs that use same template, will be appended to name
        self.memory= None;
        self.queue= None;
        self.module= None;
        self.directory= None;
        self.status= None;#waiting,failed,done
        self.cmd=[];#list of commands if only 1 member will output in single command mode
        #following not really needed to generate new jobs, but if parsing an SJM file, it will be good to have placeholders
        self.id= None;
        self.cpu_usage= None;
        self.wallclock= None;
        self.memory_usage= None;
        self.swap_usage= None;
        #list of jobnames that this job must wait for
        self.order_after=[];
        self.parent=parent;#DONE have this be added via a subroutine in the parent class, so this automatically gets supplied
    def getFullName(self):
        if self.name is None:
            return None
        if self.subname is None:
            return self.name
        return self.name + "_" + self.subname
    def toTemplateString(self):
        tempstr="job_begin\n";
        if self.name is not None:
            tempstr+="\tname "+self.name+"\n"
        else:
            raise PipelineError("[PipelineSubStep] Attempted to produce template string with no defined name!")
        if self.memory is not None:
            tempstr+="\tmemory "+self.memory+"\n"
        if self.queue is not None:
            tempstr+="\tqueue "+self.queue+"\n"
        if self.module is not None:
            tempstr+="\tmodule "+self.module+"\n"
        if self.directory is not None:
            tempstr+="\tdirectory "+self.directory+"\n"
        if self.status is not None:
            tempstr+="\tstatus "+self.status+"\n"
        if len(self.cmd) <= 0:
            raise PipelineError("[PipelineSubStep] Attempted to produce template string with no defined commands!")
        elif len(self.cmd) == 1:
            tempstr+="\tcmd "+self.cmd[0]+"\n"
        else:
            tempstr+="\tcmd_begin "+self.cmd[0]+"\n"
            for cmd in self.cmd:
                tempstr+="\t\t"+cmd+"\n"
            tempstr+="\tcmd_end "+self.cmd[0]+"\n"
        tempstr+="job_end\n"
        if len(self.order_after) > 0:
            for prior in self.order_after:
                tempstr+="order "+self.getFullName()+" after "+prior
        return tempstr
    def toString(self,grouplbl,cumsuffix,prefix,prefix2=None):
        if self.parent.isCrossJob and prefix2 is None:
            raise PipelineError("[PipelineSubStep.toString] toString called on crossjob without prefix2 variable\n")
        return PipelineUtil.replaceVars(self.toTemplateString(),self,grouplbl,cumsuffix,prefix,prefix2)