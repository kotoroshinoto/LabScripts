#!/usr/bin/env python
import sys
import os
import re
import inspect
import BiotoolsSettings
BiotoolsSettings.AssertPaths()

#to write test modules:
#http://docs.python.org/3.3/library/unittest.html
#SJM creating functions:
#sub GET_SJM_START {
#    my $str="";
#    my $JOBNAME=shift;
#    my $JOBRAM=shift;
#    $str.=q(job_begin)."\n";
#    $str.=q(name ${GROUPLBL}_).$JOBNAME."\n";
#    $str.=q(memory ).$JOBRAM."\n";
#    $str.=q(module EversonLabBiotools/1.0)."\n";
#    $str.=q(queue all.q)."\n";
#    $str.=q(directory ${CURDIR})."\n";
#}
#sub SJM_MULTILINE_JOB_START {
#    my $str=GET_SJM_START @_;
#    $str.=q(cmd_begin)."\n";
#    return $str;
#}
#sub SJM_MULTILINE_JOB_CMD {
#    my $str=join(" ",@_);
#    return $str."\n";
#}
#sub SJM_MULTILINE_JOB_END {
#    return "cmd_end\n";
#}
#sub SJM_JOB {
#    my $str=GET_SJM_START @_;
#    $str.=q(cmd $HANDLER_SCRIPT ).join(" ",@_)."\n";
#    $str.=q(job_end)."\n";
#    print "str:\n".$str."\n";
#    return $str;
#}
#sub SJM_JOB_AFTER {return  q(order ${GROUPLBL}_).$_[0].q( after ${GROUPLBL}_).$_[1];}
class PipelineError(Exception):
    def __init__(self, msg=None, err=True):
        if msg is not None:
            self.msg=msg
        else:
            self.msg="[Pipeline Error]: unspecified error"

class PipelineUtil:
    @staticmethod
    def printDict(Dict):
        if type(Dict) != type(dict()):
            return
        for key in Dict:
            print ("key: %s\n\tValue: %s" % (key,Dict[key]))
    @staticmethod
    def printList(List):
        if type(List) != type(list()):
            return
        for item in List:
            print (item)
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
        return AnalysisPipeline.replaceVars(self.toTemplateString(),self,grouplbl,cumsuffix,prefix,prefix2)
class PipelineStep:
    def __init__(self):
        #list of files this pipeline uses
        #(only need to include files produced by previous steps that you need)
        self.suffix=None;#this suffix will be appended to the accumulated suffixes for the next job's use with $ADJPREFIX 
        self.clearsuffixes=False;#if this flag is set, this step will ignore suffixes gathered from previous steps, and restart accumulation
        self.substeps=[];#list of subjobs, in order, that compose this step
        self.vars={};#convenience variables
        self.var_keys=[];
        self.isCrossJob=False;#flag for whether job cross-compares samples
    def addDependency(self,child,parent):
        parentsubstep=None
        childsubstep=None
        for substep in self.substeps:
            if substep.getFullName() == parent:
                if parentsubstep is not None:
                    raise PipelineError("[PipelineStep.addDependency] found 2 jobs that match parent") 
                parentsubstep=substep
            if substep.getFullName() == child:
                if childsubstep is not None:
                    raise PipelineError("[PipelineStep.addDependency] found 2 jobs that match child")
                childsubstep=substep          
        if parentsubstep is None :
            raise PipelineError("[PipelineStep.addDependency] No job exists with name: $parent\n")
        if childsubstep is None:
            raise PipelineError("[PipelineStep.addDependency] No job exists with name: $child\n") 
        childsubstep.order_after.append(parent)
        #TODO: ensure that this is robust enough for use of subnames
    def getCopy(self):
        #TODO: fill in stub
        pass
    def getNewSubStep(self):
        newsubstep=PipelineSubStep(self)
        self.substeps.append(newsubstep)
        return newsubstep
    @staticmethod
    def readTemplate(lines):
        newStep=PipelineStep()
        joblines=[]
        hashMatcher=re.compile(r"^#\S+$")
        varLineMatcher=re.compile(r"^#&VAR:.+$")
        varMatcher=re.compile(r"^#&VAR:(\$.+)=(.+)$")
        suffixMatcher=re.compile(r"^#&SUFFIX:(.+)$")
        typeMatcher=re.compile(r"^#&TYPE:(.+)$")
        jobtype=None
        for line in lines:
            if hashMatcher.match(line):
                if varLineMatcher.match(line):
                    varMatch=varMatcher.match(line)
                    if varMatch:
                        var=varMatch.group(1)
                        val=varMatch.group(2)
                        if var in newStep.var_keys:
                            raise PipelineError("[PipelineStep.readTemplate] Defined variable %s twice in one template" % var)
                        newStep.var_keys.append(var)
                        newStep.vars[var]=val
                    else:
                        raise PipelineError("[PipelineStep.readTemplate] improperly formed VAR line in template: \n"+line)
                    continue
                suffixMatch=suffixMatcher.match(line)
                if suffixMatch:
                    if newStep.suffix is not None:
                        raise PipelineError("[PipelineStep.readTemplate] Job Suffix defined twice in template")
                    newStep.suffix=suffixMatch.group(1)
                    continue
                typeMatch=typeMatcher.match(line)
                if typeMatch:
                    if jobtype is not None:
                        raise PipelineError("[PipelineStep.readTemplate] Job Type defined twice in template")
                    jobtype=typeMatch.group(1)
                    jobtype=jobtype.upper()
                    if jobtype == "SOLO":
                        newStep.isCrossJob=False
                    elif jobtype == "CROSS":
                        newStep.isCrossJob=True
                    else:
                        raise PipelineError("[PipelineStep.readTemplate] improperly formed TYPE line in template: "+ line)
                    continue
                #anything that reaches this point is treated as a comment line
            else:
                joblines.append(line)
        newStep.parseSubJobs(joblines)
            
    def setAssume(self):
        for substep in self.substeps:
            substep.status='done'
    def toString(self,grouplbl,cumsuffix,prefix,prefix2=None):
        if self.isCrossJob and prefix2 is None:
            raise PipelineError("[PipelineStep.toString] toString called on crossjob without prefix2 variable\n")
        resstr=""
        for substep in self.substeps:
            resstr+=substep.toString(grouplbl,cumsuffix,prefix,prefix2)
        return resstr
    def toTemplateString(self):
        tmpstr=""
        for var in self.var_keys:
            tmpstr +=("#&VAR:%s=%s\n" % (var,self.vars[var]))
        tmpstr +=("#&SUFFIX:%s\n" % (self.suffix))
        if self.isCrossJob:
            tmpstr +="#&TYPE:CROSS\n"        
        else:
            tmpstr +="#&TYPE:SOLO\n"
        for substep in self.substeps:
            tmpstr += substep.toTemplateString();        
        return tmpstr
    
    def parseSubJobs(self,lines):
        newSubStep=None
        injob=False
        incmd=False
        cmd_done=False
        #precompile regexes for efficiency
        jobStartMatcher=re.compile(r"^\s*job_begin\s*$")
        jobStopMatcher=re.compile(r"^\s*job_end\s*$")
        cmdStartMatcher=re.compile(r"^\s*cmd_begin\s*$")
        cmdStopMatcher=re.compile(r"^\s*cmd_end\s*$")
        nameMatcher=re.compile(r"^\s*name\s+(\S+)\s*$")
        memoryMatcher=re.compile(r"^\s*memory\s+(\S+)\s*$")
        queueMatcher=re.compile(r"^\s*queue\s+(\S+)\s*$")
        moduleMatcher=re.compile(r"^\s*module\s+(\S+)\s*$")
        dirMatcher=re.compile(r"^\s*directory\s+(\S+)\s*$")
        statusMatcher=re.compile(r"^\s*status\s+(\S+)\s*$")
        idMatcher=re.compile(r"^\s*id\s+(\S+)\s*$")
        cpuUseMatcher=re.compile(r"^\s*cpu_usage\s+(\S+)\s*$")
        clockMatcher=re.compile(r"^\s*wallclock\s+(\S+)\s*$")
        memUseMatcher=re.compile(r"^\s*memory_usage\s+(\S+)\s*$")
        swapUseMatcher=re.compile(r"^\s*swap_usage\s+(\S+)\s*$")
        cmdMatcher=re.compile(r"^\s*cmd\s+(\S+)\s*$")
        for line in lines:
            if injob:
                if incmd:
                    if cmdStopMatcher.match(line):
                        incmd=False
                        cmd_done=True
                    else:
                        newSubStep.cmd.append(line.strip())
                    continue
                else:
                    jobStartMatch=jobStartMatcher.match(line)
                    if jobStartMatch:
                        raise PipelineError("[PipelineStep.parseSubJobs] job_begin found after previous job_begin but not after job_end")
                    jobStopMatch=jobStopMatcher.match(line)
                    if jobStopMatch:
                        injob=False
                        #TODO: verify job is valid
                        continue
                    nameMatch=nameMatcher.match(line)
                    if nameMatch:
                        if newSubStep.name is not None:
                            raise PipelineError("[PipelineStep.parseSubJobs] name defined twice in job template")
                        newSubStep.name=nameMatch.group(1)
                        continue
                    memoryMatch=memoryMatcher.match(line)
                    if memoryMatch:
                        if newSubStep.memory is not None:
                            raise PipelineError("[PipelineStep.parseSubJobs] memory defined twice in job template")
                        newSubStep.memory=memoryMatch.group(1)
                        continue
                    queueMatch=queueMatcher.match(line)
                    if queueMatch:
                        if newSubStep.queue is not None:
                            raise PipelineError("[PipelineStep.parseSubJobs] queue defined twice in job template")
                        newSubStep.queue=queueMatch.group(1)
                        continue
                    moduleMatch=moduleMatcher.match(line)
                    if moduleMatch:
                        if newSubStep.module is not None:
                            raise PipelineError("[PipelineStep.parseSubJobs] module defined twice in job template")
                        newSubStep.module=moduleMatch.group(1)
                        continue
                    dirMatch=dirMatcher.match(line)
                    if dirMatch:
                        if newSubStep.directory is not None:
                            raise PipelineError("[PipelineStep.parseSubJobs] directory defined twice in job template")
                        newSubStep.directory=dirMatch.group(1)
                        continue
                    statusMatch=statusMatcher.match(line)
                    if statusMatch:
                        if newSubStep.status is not None:
                            raise PipelineError("[PipelineStep.parseSubJobs] status defined twice in job template")
                        newSubStep.status=statusMatch.group(1)
                        continue
                    idMatch=idMatcher.match(line)
                    if idMatch:
                        if newSubStep.id is not None:
                            raise PipelineError("[PipelineStep.parseSubJobs] id defined twice in job template")
                        newSubStep.id=idMatch.group(1)
                        continue
                    cpuUseMatch=cpuUseMatcher.match(line)
                    if cpuUseMatch:
                        if newSubStep.cpu_usage is not None:
                            raise PipelineError("[PipelineStep.parseSubJobs] cpu_usage defined twice in job template")
                        newSubStep.cpu_usage=cpuUseMatch.group(1) 
                        continue
                    clockMatch=clockMatcher.match(line)
                    if clockMatch:
                        if newSubStep.wallclock is not None:
                            raise PipelineError("[PipelineStep.parseSubJobs] wallclock defined twice in job template")
                        newSubStep.wallclock=clockMatch.group(1)
                        continue
                    memUseMatch=memUseMatcher.match(line)
                    if memUseMatch:
                        if newSubStep.memory_usage is not None:
                            raise PipelineError("[PipelineStep.parseSubJobs] memory_usage defined twice in job template")
                        newSubStep.memory_usage=memUseMatch.group(1)
                        continue
                    swapUseMatch=swapUseMatcher.match(line)
                    if swapUseMatch:
                        if newSubStep.swap_usage is not None:
                            raise PipelineError("[PipelineStep.parseSubJobs] swap_usage defined twice in job template")
                        newSubStep.swap_usage=swapUseMatch.group(1)
                        continue
                    cmdStartMatch=cmdStartMatcher.match(line)
                    if cmdStartMatch:
                        if cmd_done:
                            raise PipelineError("[PipelineStep.parseSubJobs] cmd_begin defined twice in job template")
                        incmd=True
                        continue
                    cmdMatch=cmdMatcher.match(line)
                    if cmdMatch:
                        if cmd_done:
                            raise PipelineError("[PipelineStep.parseSubJobs] cmd defined twice in job template")
                        cmd_done=True
                        newSubStep.cmd.append(cmdMatch.group(1))
                        continue
                    raise PipelineError("[PipelineStep.parseSubJobs] invalid line in template: "+line)
                      
            else:
                pass
class AnalysisPipeline:
    def __init__(self):
        #TODO: fill in stub
        self.jobtemplates={}
    @staticmethod
    def replaceVars():
        #TODO: fill in stub
        return None
    def requireJobDef(self):
        #TODO: fill in stub
        return None
    @staticmethod
    def templateDir():
        return os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))),"jobtemplates")
    def loadTemplate(self):
        #TODO: fill in stub
        return None