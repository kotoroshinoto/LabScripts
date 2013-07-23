"""
sam_parser.py script
Version 2013.07.23

@author: Bing
run command: samtools view /UCHC/Everson/umar/cluster/align_bam/RNA_Pt5/NC5R_aligned_clean.bam | python /UCHC/HPC/Everson_HPC/LabScripts/cluster_scripts/pybin/DGESeqSimuation/sam_parser.py /dev/stdin testresults.txt

"""
import os, sys
import gtf_reader as greader

class SAMInstance:
    """class that holds information about each SAM read"""
    def __init__(self,line = None):
        """default constructor"""
        self.read_name = None
        self.flag = None
        self.chromosome = None
        self.position = 0 # 1-based index starting at left end of read
        self.mapq = None
        self.cigar = None
        self.mate_name = None
        self.mate_position = None
        self.template_length = None
        self.read_sequence = None
        self.read_quality = None
        self.program_flags = None
        if line is not None:
            self.__parseSAMLine(line)
    def __parseSAMLine(self, line):
        """split line and assign values to variables"""
        line = line.split('\t')
        self.read_name = line[0]
        self.flag = line[1]
        self.chromosome = line[2]
        self.position = int(line[3]) + 100 # 1-based index starting at left end of read
        ##^ need to test
        #self.mapq = line[4]
        self.cigar = line[5]
        self.mate_name = line[6]
        self.mate_position = line[7]
        #self.template_length = line[8]
        #self.read_sequence = line[9]
        #self.read_quality = line[10]
        #self.program_flags = line[11]
    def compareToGTF(self, transcript_list):
        """finds and counts positions that match to gene transcripts list"""
        for key in transcript_list:
            instance = transcript_list[key]
            if instance.chromosome == self.chromosome:
                if instance.threeprimeloc == self.position:
                    instance.count += 1
                    instance.expression_positions.extend(self.position)
                    print('Found match!')
                transcript_list[key] = instance
        return transcript_list

# START of script
# define command line argument input
if len(sys.argv) != 3:
    sys.stderr.write("script must be given 2 arguments: input and output filenames")
input_file = sys.argv[1] # when using from samtools view: samtools view filename.bam | sam_parser.py /dev/stdin output_filename
output_file = sys.argv[2]

# read GTF file + generate transcript list
input_directory = os.path.join(os.path.dirname(__file__), 'Input')
filename = 'genes.gtf'
transcript_list = greader.processGTF(input_directory, filename)

# SAM file IO
input = open(input_file,'r')
output = open(output_file, 'w')

# read SAM file up to limit and run comparisons to transcript list
readcount = 0
readlimit = 5000
for line in input:
    readcount += 1
    sam = SAMInstance(line)
    transcript_list = sam.compareToGTF(transcript_list) ## figure out how input transcript list
    if readcount == readlimit:
        break
writecount = 0
writelimit = 10
for key in transcript_list:
    writecount += 1
    print('Writing line {0}'.format(writecount))
    instance = transcript_list[key]
    #if instance.count > 0:
    output.write("%s contains %s exons and %s counts\n" % (instance.name, instance.num_exons, instance.count))
    #output.write('Instance name is %s\n' % instance.name)
    #output.write('Number of exons is %s\n' % instance.num_exons)
    #output.write('Expression number is %s\n' % instance.count)
    if writecount == writelimit:
        break
input.close()
output.close()
print('Job is Finished!')