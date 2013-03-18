#!/usr/bin/env python
import sys
import os
import re
import inspect
import BiotoolsSettings
import PipelineError
BiotoolsSettings.AssertPaths()
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
def printDict(Dict):
    if type(Dict) != type(dict()):
        return
    for key in Dict:
        print ("key: %s\n\tValue: %s" % (key,Dict[key]))
def printList(List):
    if type(List) != type(list()):
        return
    for item in List:
        print (item)

def templateDir():
    #return os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))),"jobtemplates")#get path to this script, get directory name, and go up one level, then append template dir name
    return BiotoolsSettings.SettingsList.get("SJM_TEMPLATE_DIR")

def replaceVars():
    #TODO: fill in stub
    return None