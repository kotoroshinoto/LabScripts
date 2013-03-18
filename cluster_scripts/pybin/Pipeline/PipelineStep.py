#!/usr/bin/env python
'''
Created on Mar 18, 2013

@author: Gooch
'''
import re
import PipelineError,PipelineSubStep
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