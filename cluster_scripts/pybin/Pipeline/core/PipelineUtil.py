'''
Created on Mar 26, 2013

@author: mgooch
'''
import re,sys,os
import BiotoolsSettings
from Pipeline.core.PipelineError import PipelineError

def replaceVars(instr,subjob,grouplbl,cumsuffix,prefix,prefix2=None):
    #TODO: fill in stub
    errors=[]
    if instr is None:
        errors.append("instr is None")
    if subjob is None:
        errors.append("subjob is None")
    if grouplbl is None:
        errors.append("grouplbl is None")
    if cumsuffix is None:
        errors.append("cumsuffix is None")
    if prefix is None:
        errors.append("prefix is None")
    if subjob.parent.isCrossJob and (prefix2 is None):
        errors.append("prefix2 is None for crossjob")
    if len(errors) != 0:
        raise PipelineError("[Pipeline.PipelineUtil.replaceVars] " + (", ".join(errors)))
    retstr=instr
    for var in subjob.parent.vars:
        search=var
        replace=subjob.parent.vars[var]
        search=re.sub(r'\$','\\\$',search)
        #print ("replacing %s with %s" %(search,replace))
        retstr=re.sub(search,replace,retstr)
#replace ADJPREFIX with $PREFIX$CUMSUFFIX - totally for convenience, 
#can still use $CUMSUFFIX directly, for input files that need it
    if not subjob.parent.clearsuffixes:
        retstr=re.sub('\$ADJPREFIX','$PREFIX$CUMSUFFIX',retstr)
    else:
        retstr=re.sub('\$ADJPREFIX','$PREFIX',retstr)
    retstr=re.sub('\$CUMSUFFIX',cumsuffix,retstr)
    retstr=re.sub('\$SUFFIX',subjob.parent.suffix,retstr);
    for key in BiotoolsSettings.getKeyList():
        search='\$'+key
        replace=BiotoolsSettings.getValue(key)
        #TODO: this is for testing
        if sys.platform == 'win32':
            replace=re.sub("\\\\","\\\\\\\\",replace)
        #print("replacing %s with %s" % (search,replace))
        retstr=re.sub(search,replace,retstr);
    retstr=re.sub('\$GROUPLBL',grouplbl,retstr);
    retstr=re.sub('\$CUMSUFFIX',cumsuffix,retstr);
    retstr=re.sub('\$PREFIX',prefix,retstr);
    if subjob.parent.isCrossJob:
        retstr=re.sub('\$PREFIX2',prefix2,retstr);
    return retstr


def templateDir():
    #return os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))),"jobtemplates")#get path to this script, get directory name, and go up one level, then append template dir name
    return BiotoolsSettings.getValue("SJM_TEMPLATE_DIR")