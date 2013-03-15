#!/usr/bin/env python
import BiotoolsSettings
import pyswitch
import os
import sys
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
class AnalysisPipeline:
    def __init__(self):
        #TODO: fill in stub
        self.jobtemplates={}
    def replaceVars(self):
        #TODO: fill in stub
        return None
    def requireJobDef(self):
        #TODO: fill in stub
        return None
    def templateDir(self):
        #TODO: fill in stub
        return None