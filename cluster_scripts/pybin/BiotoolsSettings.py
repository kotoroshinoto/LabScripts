#!/usr/bin/env python
import sys
import os
def printDict(Dict):
    if type(Dict) != type(dict()):
        return
    for key in Dict:
        print ("key: %s\n\tValue:%s" % key,Dict[key])
def printList(List):
    if type(List) != type(list()):
        return
    for item in List:
        print (item)
pythonpathSTR=os.environ.get('PYTHONPATH')
pythonpath=''
if pythonpathSTR is not None:
    pythonpath=pythonpathSTR.split(os.pathsep)
print sys.platform
printList(pythonpath)
printList(sys.path)