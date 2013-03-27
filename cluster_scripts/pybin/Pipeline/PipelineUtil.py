'''
Created on Mar 26, 2013

@author: mgooch
'''
import BiotoolsSettings
def replaceVars():
    #TODO: fill in stub
    return None


def templateDir():
    #return os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(inspect.getfile(inspect.currentframe())))),"jobtemplates")#get path to this script, get directory name, and go up one level, then append template dir name
    return BiotoolsSettings.getValue("SJM_TEMPLATE_DIR")