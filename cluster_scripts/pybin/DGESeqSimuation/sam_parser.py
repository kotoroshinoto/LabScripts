"""
sam_parser.py script
Version 2013.07.26

@author: Bing
run location: ssh mgooch@sig2-glx.cam.uchc.edu
run command: samtools view /UCHC/Everson/umar/cluster/align_bam/RNA_Pt5/NC5R_aligned_clean.bam | python /UCHC/HPC/Everson_HPC/LabScripts/cluster_scripts/pybin/DGESeqSimuation/sam_parser.py /dev/stdin testresults.txt
or command: samtools view /UCHC/Everson/umar/Patient5A/BAM_aligned_GATK_Hg19_Galaxy_FASTQ/NF5A.4gatk.bam | python /UCHC/HPC/Everson_HPC/LabScripts/cluster_scripts/pybin/DGESeqSimuation/sam_parser.py /dev/stdin gatktestresults.txt

"""
import os, sys, pickle
import gtf_reader as greader

class SAMInstance:
    """class that holds information about each SAM read"""
    def __init__(self, line = None):
        """default constructor"""
        self.read_name = None
        self.flag = None
        self.chromosome = None
        self.start = 0 # 1-based index starting at left end of read
        self.end = 0
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
        """split SAM line and assign values to variables"""
        line = line.split('\t')
        self.read_name = line[0]
        self.flag = line[1]
        self.chromosome = line[2]
        self.start = int(line[3]) # 1-based index starting at left end of read
        self.end = int(line[3]) + 100
        #self.mapq = line[4]
        self.cigar = line[5]
        self.mate_name = line[6]
        self.mate_position = line[7]
        #self.template_length = line[8]
        #self.read_sequence = line[9]
        #self.read_quality = line[10]
        #self.program_flags = line[11]
    def compareToGTF(self, transcript_list, readcount):
        """finds and counts positions that match to gene transcripts list"""
        for key in transcript_list:
            transcript = transcript_list[key]
            if transcript.chromosome == self.chromosome:
                print('Chromosomes match!')
                if transcript.start < self.end and transcript.end > self.start:
                    transcript.expression_count += 1
                    #findcount += 1
                    #transcript.read_names.append(self.read_name)
                    #transcript.read_quality.append(self.read_quality)
                    print('Found match on line %d1' % readcount)
                    transcript_list[key] = transcript
                    break
        return transcript_list, readcount
def inputTranscriptList(gtf_filename):
    """reads existing transcript list or generates new list if needed from GTF file"""
    input_directory = os.path.join(os.path.dirname(__file__), 'Input')
    old_dir = os.getcwd()
    os.chdir(input_directory)
    if not os.path.exists('transcript_list.csv'):
        print('Building new transcript list...')
        greader.processGTF(input_directory, gtf_filename)
    else:
        print('\n######\n\nThe transcript list already exists and does not need to be created. You have just saved 3 minutes of your life! Delete the old list if you wish to build a new transcript list.\n\n######\n')
    list_file = open('transcript_list.csv', 'rb')
    print('Loading Transcript List...')
    transcript_list = pickle.load(list_file)
    os.chdir(old_dir)
    return transcript_list
def processSAMFile(sam_filename, transcript_list):
    # SAM file IO
    input = open(sam_filename,'r')
    
    # read SAM file up to limit and run comparisons to transcript list
    readcount = 0
    #readlimit = 1000
    #findcount = 0
    #findlimit = 8
    print('Reading...')
    for line in input:
        readcount += 1
        #print('Reading line %d' % readcount)
        sam = SAMInstance(line)
        transcript_list, readcount = sam.compareToGTF(transcript_list, readcount)
        #if readcount == readlimit:
        #    break
        #if findcount == findlimit:
        #    break
    input.close()
    return transcript_list
def outputMatches(output_filename, transcript_list):
    #import xlsxwriter.workbook as xlsx
    print('Writing...')
    
    old_dir = os.getcwd()
    os.chdir(os.path.join(os.path.dirname(__file__), 'Output'))
    output = open(output_filename, 'w')
    output.write('Transcript Name\tNumber of Exons\tNumber of Expressions\tTranscript Number ID\n')
    #book = xlsx.Workbook(output_filename + '.xls')
    #sheet = book.add_worksheet('Expression Levels')
    #sheet.write(0, 0, 'Transcript Name')
    #sheet.write(1, 0, 'Number of Exons')
    #sheet.write(2, 0, 'Number of Expressions')
    rowscount = 1
    try:
        rowslimit = len(transcript_list)
        ##print('Output table has %r transcripts' % rowslimit)
    except IndexError:
        print('Cannot output an empty table')
    for key in transcript_list:
        #print('Writing line %d' % rowscount)
        transcript = transcript_list[key]
        if transcript.expression_count > 0:
            #sheet.write(rowscount, 0, transcript.name)
            #sheet.write(rowscount, 1, transcript.num_exons)
            #sheet.write(rowscount, 2, transcript.expression_count)
            #output.write("%s contains %s exons and %s counts\n" % (transcript.name, transcript.num_exons, transcript.expression_count))
            output.write('%s\t%d\t%d\t%d\n' % (transcript.name, transcript.num_exons, transcript.expression_count, transcript.num_id))
        if rowscount == rowslimit:
            break
        rowscount += 1
    output.close()
    os.chdir(old_dir)
    #book.close()

# START of script
# define command line argument input
if len(sys.argv) != 3:
    sys.stderr.write("script must be given 2 arguments: input and output filenames")
input_file = sys.argv[1] # when using from samtools view: samtools view filename.bam | sam_parser.py /dev/stdin output_filename
output_file = sys.argv[2]
transcript_list = inputTranscriptList('genes.gtf')
transcript_list = processSAMFile(input_file, transcript_list)
outputMatches(output_file, transcript_list)
print('Job is Finished!')