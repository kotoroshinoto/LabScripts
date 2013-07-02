'''
Created on Mar 18, 2013

@author: Gooch
'''
import BiotoolsSettings
import re
import os
from Pipeline.PipelineTemplate import PipelineTemplate
import Pipeline.PipelineUtil as PipelineUtil
class AnalysisPipeline:
    def __init__(self):
        #TODO: fill in stub
        self.jobtemplates={}

    @staticmethod
    def splitJobname(jobspec):
        #TODO: name format is TemplateName[SubName]
        _jobspec=jobspec.strip();
        match=re.match("^(\S*)\[(\S*)\]$",_jobspec)
        if match:
            result=[]
            for item in match.group(1,2):
                result.append(item)
            if result[0] == "":
                #TODO: change this indication to an exception
                return []
            if result[1] == "":
                del result[1]
            return result
        else:
            numstart=_jobspec.count('[')
            numend=_jobspec.count(']')
            if numstart == 0 and numend == 0:
                result=[]
                result.append(_jobspec)
                return result
            if not(numstart == 1 and numend == 1):
                #indicate error
                #TODO: change this indication to an exception
                return []
            startpos=_jobspec.find('[')
            endpos=_jobspec.find(']')
            if endpos < startpos:
                #indicate error
                #TODO: change this indication to an exception
                return []
    def loadTemplate(self,jobspec):
        template=None
        #TODO: fill in stub
        splitName=AnalysisPipeline.splitJobname(jobspec)
        if len(splitName) == 0:
            return False
        #check if step template is already loaded
        if splitName[0] in self.jobtemplates:
            #if loaded, no more work to do
            return True;
        #if not found, check if template exists
        path2Template=os.path.join(PipelineUtil.templateDir(),splitName[0].upper()+".sjt")
        #print(path2Template)
        if os.path.isfile(path2Template):
            #if template exists
            templateFile=open(path2Template,'rU')
            templateLines=templateFile.readlines()
            templateFile.close()
            template=PipelineTemplate.readTemplate(templateLines)
            self.jobtemplates[splitName[0].upper()]=template
            return True
        else:
            #if template doesn't exist, signal error
            return False
    def TemplateIsLoaded(self,jobspec):
        splitName=AnalysisPipeline.splitJobname(jobspec)
        return (splitName[0] in self.jobtemplates)
    def getTemplate(self,jobspec):
        if not self.TemplateIsLoaded(jobspec):
            self.loadTemplate(jobspec)
            if not self.TemplateIsLoaded(jobspec):
                return None
        else:
            splitName=AnalysisPipeline.splitJobname(jobspec)
            return self.jobtemplates.get(splitName[0])
#apl=AnalysisPipeline()
#worked=apl.loadTemplate("BWA_ALIGN_PAIRED")
#print (apl.TemplateIsLoaded("BWA_ALIGN_PAIRED"))
#print (apl.getTemplate("BWA_ALIGN_PAIRED").toTemplateString())
#print (apl.getTemplate("BWA_ALIGN_PAIRED").toString('grouplbl','.cumsuffix','prefix'))