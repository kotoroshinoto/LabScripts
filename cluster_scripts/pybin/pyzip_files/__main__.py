'''
Created on Mar 18, 2013

@author: Gooch
'''
import sys
if 'Pipeline.pyz' in sys.argv[0]:
    sys.path.append('/UCHC/HPC/Everson_HPC/cluster_scripts/pybin/Pipeline.pyz')
import Pipeline.commands.PipelineTemplateGenerator
import Pipeline.commands.PipelineGenerateSJM
def main():
    sys.stderr.write("This is currently a placeholder, it will eventually be implemented to forward commandline args to the appropriate python module\n")
    sys.stderr.write("args: '%s'" % (' '.join(sys.argv)))
    if (sys.argv[1].lower() == "maketemplate"):
        Pipeline.commands.PipelineTemplateGenerator.main(sys.argv)
    elif (sys.argv[1].lower() == "maketemplate"):
        Pipeline.commands.PipelineGenerateSJM.main(sys.argv)
    return 0
if __name__ == '__main__':
    sys.exit(main())