#!/usr/bin/env python
'''
Created on Mar 18, 2013

@author: Gooch
'''
import re
from Pipeline.PipelineError import PipelineError
from Pipeline.PipelineClusterJob import PipelineClusterJob
import Pipeline.PipelineUtil as PipelineUtil
import os
class PipelineTemplate:
    def __init__(self):
        #list of files this pipeline uses
        #(only need to include files produced by previous steps that you need)
        self.name=None;
        self.suffix=None;#this suffix will be appended to the accumulated suffixes for the next job's use with $ADJPREFIX 
        self.clearsuffixes=False;#if this flag is set, this step will ignore suffixes gathered from previous steps, and restart accumulation
        self.ClusterJobs=[];#list of subjobs, in order, that compose this step
        self.vars={};#convenience variables
        self.var_keys=[];
        self.isCrossJob=False;#flag for whether job cross-compares samples
    def addDependency(self,child,parent):
        parentClusterJob=None
        childClusterJob=None
        for ClusterJob in self.ClusterJobs:
            if ClusterJob.getFullName() == parent:
                if parentClusterJob is not None:
                    raise PipelineError("[PipelineTemplate.addDependency] found 2 jobs that match parent") 
                parentClusterJob=ClusterJob
            if ClusterJob.getFullName() == child:
                if childClusterJob is not None:
                    raise PipelineError("[PipelineTemplate.addDependency] found 2 jobs that match child")
                childClusterJob=ClusterJob          
        if parentClusterJob is None :
            raise PipelineError("[PipelineTemplate.addDependency] No job exists with name: $parent\n")
        if childClusterJob is None:
            raise PipelineError("[PipelineTemplate.addDependency] No job exists with name: $child\n") 
        childClusterJob.order_after.append(parent)
        #TODO: ensure that this is robust enough for use of subnames
    def getCopy(self):
        #TODO: fill in stub
        pass
    def getNewClusterJob(self):
        newClusterJob=PipelineClusterJob(self)
        self.ClusterJobs.append(newClusterJob)
        return newClusterJob
    def writeTemplate(self):
        #TODO method stub
        path2Template=os.path.join(PipelineUtil.templateDir(),self.name.upper()+".sjt")
        #TODO, file conditions, should either not exist, or be a normal file
        templateFile=open(path2Template,'w')
        for Var in self.var_keys:
            print("#&VAR:%s=%s")
        templateFile.close()
        return None;
    @staticmethod
    def readTemplate(name):
        #get path
        path2Template=os.path.join(PipelineUtil.templateDir(),name.upper()+".sjt")
        #check file exists
        if not os.path.isfile(path2Template):
            raise PipelineError("Template file does not exist!: " + path2Template)
        #read file:
        templateFile=open(path2Template,'rU')
        templateLines=templateFile.readlines()
        templateFile.close()
        #process file:
        newStep=PipelineTemplate()
        newStep.name=name.upper()
        joblines=[]
        hashMatcher=re.compile(r"^#\S+$")
        varLineMatcher=re.compile(r"^#&VAR:.+$")
        varMatcher=re.compile(r"^#&VAR:(\$.+)=(.+)$")
        suffixMatcher=re.compile(r"^#&SUFFIX:(.+)$")
        typeMatcher=re.compile(r"^#&TYPE:(.+)$")
        jobtype=None
        for line in templateLines:
            line=line.strip()
            if hashMatcher.match(line):
                if varLineMatcher.match(line):
                    varMatch=varMatcher.match(line)
                    if varMatch:
                        var=varMatch.group(1)
                        val=varMatch.group(2)
                        if var in newStep.var_keys:
                            raise PipelineError("[PipelineTemplate.readTemplate] Defined variable %s twice in one template" % var)
                        newStep.var_keys.append(var)
                        newStep.vars[var]=val
                    else:
                        raise PipelineError("[PipelineTemplate.readTemplate] improperly formed VAR line in template: \n"+line)
                    continue
                suffixMatch=suffixMatcher.match(line)
                if suffixMatch:
                    if newStep.suffix is not None:
                        raise PipelineError("[PipelineTemplate.readTemplate] Job Suffix defined twice in template")
                    newStep.suffix=suffixMatch.group(1)
                    continue
                typeMatch=typeMatcher.match(line)
                if typeMatch:
                    if jobtype is not None:
                        raise PipelineError("[PipelineTemplate.readTemplate] Job Type defined twice in template")
                    jobtype=typeMatch.group(1)
                    jobtype=jobtype.upper()
                    if jobtype == "SOLO":
                        newStep.isCrossJob=False
                    elif jobtype == "CROSS":
                        newStep.isCrossJob=True
                    else:
                        raise PipelineError("[PipelineTemplate.readTemplate] improperly formed TYPE line in template: "+ line)
                    continue
                #anything that reaches this point is treated as a comment line
            else:
                joblines.append(line)
        newStep.parseSubJobs(joblines)
        return newStep;
            
    def setAssume(self):
        for ClusterJob in self.ClusterJobs:
            ClusterJob.status='done'
    def toString(self,grouplbl,cumsuffix,prefix,prefix2=None):
        if self.isCrossJob and prefix2 is None:
            raise PipelineError("[PipelineTemplate.toString] toString called on crossjob without prefix2 variable\n")
        resstr=""
        for ClusterJob in self.ClusterJobs:
            if ClusterJob is not None:
                result=ClusterJob.toString(grouplbl,cumsuffix,prefix,prefix2)
                if result is None:
                    raise PipelineError("[Pipeline.PipelineTemplate.toString()] call to ClusterJob.tostring() returned None")
                resstr+=result
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
        for ClusterJob in self.ClusterJobs:
            tmpstr += ClusterJob.toTemplateString();        
        return tmpstr
    
    def parseSubJobs(self,lines):
        newClusterJob=None
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
        cmdMatcher=re.compile(r"^\s*cmd\s+([\S ]+)\s*$")
        logDirMatcher=re.compile(r"^\s*log_dir\s+(\S+)\s*$")
        orderMatcher=re.compile(r"^\s*order\s+(.+)\s*$")
        orderBeforeMatcher=re.compile(r"^\s*order\s*(\S+)\s*before\s*(\S+)\s*$")
        orderAfterMatcher=re.compile(r"^\s*order\s*(\S+)\s*after\s*(\S+)\s*$")
        for line in lines:
            #print (line)
            if injob:
                #print("\tin_job")
                if incmd:
                    if cmdStopMatcher.match(line):
                        incmd=False
                        cmd_done=True
                    else:
                        newClusterJob.cmd.append(line.strip())
                    continue
                else:# if in command
                    jobStartMatch=jobStartMatcher.match(line)
                    if jobStartMatch:
                        raise PipelineError("[PipelineTemplate.parseSubJobs] job_begin found after previous job_begin but not after job_end")
                    jobStopMatch=jobStopMatcher.match(line)
                    if jobStopMatch:
                        injob=False
                        #TODO: verify job is valid
                        continue
                    nameMatch=nameMatcher.match(line)
                    if nameMatch:
                        if newClusterJob.name is not None:
                            raise PipelineError("[PipelineTemplate.parseSubJobs] name defined twice in job template")
                        newClusterJob.name=nameMatch.group(1)
                        continue
                    memoryMatch=memoryMatcher.match(line)
                    if memoryMatch:
                        if newClusterJob.memory is not None:
                            raise PipelineError("[PipelineTemplate.parseSubJobs] memory defined twice in job template")
                        newClusterJob.memory=memoryMatch.group(1)
                        continue
                    queueMatch=queueMatcher.match(line)
                    if queueMatch:
                        if newClusterJob.queue is not None:
                            raise PipelineError("[PipelineTemplate.parseSubJobs] queue defined twice in job template")
                        newClusterJob.queue=queueMatch.group(1)
                        continue
                    moduleMatch=moduleMatcher.match(line)
                    if moduleMatch:
                        if newClusterJob.module is not None:
                            raise PipelineError("[PipelineTemplate.parseSubJobs] module defined twice in job template")
                        newClusterJob.module=moduleMatch.group(1)
                        continue
                    dirMatch=dirMatcher.match(line)
                    if dirMatch:
                        if newClusterJob.directory is not None:
                            raise PipelineError("[PipelineTemplate.parseSubJobs] directory defined twice in job template")
                        newClusterJob.directory=dirMatch.group(1)
                        continue
                    statusMatch=statusMatcher.match(line)
                    if statusMatch:
                        if newClusterJob.status is not None:
                            raise PipelineError("[PipelineTemplate.parseSubJobs] status defined twice in job template")
                        newClusterJob.status=statusMatch.group(1)
                        continue
                    idMatch=idMatcher.match(line)
                    if idMatch:
                        if newClusterJob.id is not None:
                            raise PipelineError("[PipelineTemplate.parseSubJobs] id defined twice in job template")
                        newClusterJob.id=idMatch.group(1)
                        continue
                    cpuUseMatch=cpuUseMatcher.match(line)
                    if cpuUseMatch:
                        if newClusterJob.cpu_usage is not None:
                            raise PipelineError("[PipelineTemplate.parseSubJobs] cpu_usage defined twice in job template")
                        newClusterJob.cpu_usage=cpuUseMatch.group(1) 
                        continue
                    clockMatch=clockMatcher.match(line)
                    if clockMatch:
                        if newClusterJob.wallclock is not None:
                            raise PipelineError("[PipelineTemplate.parseSubJobs] wallclock defined twice in job template")
                        newClusterJob.wallclock=clockMatch.group(1)
                        continue
                    memUseMatch=memUseMatcher.match(line)
                    if memUseMatch:
                        if newClusterJob.memory_usage is not None:
                            raise PipelineError("[PipelineTemplate.parseSubJobs] memory_usage defined twice in job template")
                        newClusterJob.memory_usage=memUseMatch.group(1)
                        continue
                    swapUseMatch=swapUseMatcher.match(line)
                    if swapUseMatch:
                        if newClusterJob.swap_usage is not None:
                            raise PipelineError("[PipelineTemplate.parseSubJobs] swap_usage defined twice in job template")
                        newClusterJob.swap_usage=swapUseMatch.group(1)
                        continue
                    cmdStartMatch=cmdStartMatcher.match(line)
                    if cmdStartMatch:
                        if cmd_done:
                            raise PipelineError("[PipelineTemplate.parseSubJobs] cmd_begin defined twice in job template")
                        incmd=True
                        continue
                    cmdMatch=cmdMatcher.match(line)
                    if cmdMatch:
                        if cmd_done:
                            raise PipelineError("[PipelineTemplate.parseSubJobs] cmd defined twice in job template")
                        cmd_done=True
                        newClusterJob.cmd.append(cmdMatch.group(1))
                        continue
                    raise PipelineError("[PipelineTemplate.parseSubJobs] invalid line in template: "+line)
                      
            else:#if in job
                #print("\tout_of_job")
                #TODO: fill out
                jobStopMatch=jobStopMatcher.match(line)
                if jobStopMatch:
                    raise PipelineError("[PipelineTemplate.parseSubJobs] job_end discovered before finding job_begin: " )
                logDirMatch=logDirMatcher.match(line)
                if logDirMatch:
                    raise PipelineError("[PipelineTemplate.parseSubJobs] log_dir should not be defined in a job template: " )
                jobStartMatch=jobStartMatcher.match(line)
                if jobStartMatch:
                    injob=True
                    cmd_done=False
                    newClusterJob=self.getNewClusterJob()
                    continue 
                orderMatch=orderMatcher.match(line)
                if orderMatch:
                    orderBeforeMatch=orderBeforeMatcher.match(line)
                    if orderBeforeMatch:
                        self.addDependency(orderBeforeMatch.group(1), orderBeforeMatch.group(2))
                        continue
                    orderAfterMatch=orderAfterMatcher.match(line)
                    if orderAfterMatch:
                        self.addDependency(orderAfterMatch.group(2), orderAfterMatch.group(1))
                        continue
                    raise PipelineError("[PipelineTemplate.parseSubJobs] improperly formed order line")
                raise PipelineError("[PipelineTemplate.parseSubJobs] unrecognized line in job")