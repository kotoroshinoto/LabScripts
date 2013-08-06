"""
sam_parser.py script
version 2013.08.05

@author: Bing
takes input from gene list file and sequence alignment map file and compares sequence reads to calculated stable regions of transcripts

run location: ssh mgooch@sig2-glx.cam.uchc.edu
sample command: python /UCHC/HPC/Everson_HPC/LabScripts/cluster_scripts/pybin/DGESeqSimulation/sam_parser.py /UCHC/Everson/Projects/Bladder/Pt5/RNA/TSRNA091711TCBL5_TOPHAT/accepted_hits.bam pysam_Pt5_TC_results.txt 200

"""
import os, sys, pickle, datetime
import gtf_reader as greader
import pysam

is_debug = False

def inputTranscriptList(gtf_filename, transcript_list_filename, simulation_length):
    """reads existing transcript list or generates new list if needed from GTF file"""
    input_directory = os.path.join(os.path.dirname(__file__), 'Input')
    old_dir = os.getcwd()
    os.chdir(input_directory)
    if not os.path.exists(transcript_list_filename):
        print('Building new transcript list...')
        greader.processGTF(input_directory, gtf_filename, transcript_list_filename, simulation_length)
    else:
        print('\n######\n\nThe transcript list already exists and does not need to be created. You have just saved 3 minutes of your life! Delete the old list if you wish to build a new transcript list.\n\n######\n')
    list_file = open(transcript_list_filename, 'rb')
    print('Loading transcript list...')
    gtf_list = pickle.load(list_file)
    os.chdir(old_dir)
    return gtf_list
def processSAMFile(sam_filename, gtf_list):
    # SAM file IO
    seqinput = pysam.Samfile(sam_filename)#automatically checks for 'rb' and then 'r' modes
    # read SAM file up to limit and run comparisons to transcript list
    readcount = 0
    if is_debug:
        readlimit = 10000 # debugging
    print('Reading...')
    for seqread in seqinput.fetch(until_eof=True):
        readcount += 1
        transcripts_at_chromosome = gtf_list[seqinput.getrname(seqread.tid)]
        for transcript in transcripts_at_chromosome:
            '''
            TODO:
            could possibly iterate over transcripts and use 
            pysam.Samfile.count(reference="chr#',start=#,end=#) > 0
            
            or
            
            could potentially fetch once per reference sequence (chromosome) 
            and only compare reads agaisnt transcripts from same chromosome
            would only benefit if pysam reads entire samfile ahead of time 
            or on first fetch (and then retains it for later use)
            '''
            read_end = seqread.pos+(seqread.qend-seqread.qstart)
            if transcript.start <= read_end and transcript.end >= seqread.pos:
                transcript.expression_count += 1
                #if is_debug is True:
                    #print('Found match on line %d for %r' % (readcount, transcript.name)) #debugging
        if readcount % 100000 == 0:
            print('Processed %d reads @ %s' % (readcount,datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")))
        if is_debug:
            if readcount == readlimit:
                break
    seqinput.close()
def outputMatches(output_filename, gtf_list):
    print('Writing...')
    
    old_dir = os.getcwd()
    os.chdir(os.path.join(os.path.dirname(__file__), 'Output'))
    output = open(output_filename, 'w')
    output.write('Transcript Name\tNumber of Exons\tNumber of Expressions\tTranscript Number ID\n')
    for chromosome in gtf_list:
        transcripts_at_chromosome = gtf_list[chromosome]
        for transcript in transcripts_at_chromosome:
            if transcript.expression_count > 0:
                output_string = '%s\t%d\t%d\t%d' % (transcript.name, transcript.num_exons, transcript.expression_count, transcript.num_id)
                if is_debug:
                    output.write(output_string + '\n')
                print(output_string)
    output.close()
    os.chdir(old_dir)

# START of script
# define command line argument input
if len(sys.argv) != 4:
    sys.stderr.write("\nScript must be given 3 arguments: input filename, output filename, and simulation sequence length")
input_file = sys.argv[1]
output_file = sys.argv[2]
simulation_length = int(sys.argv[3])

print('\nStarting the script...')
gtf_list = inputTranscriptList('genes.gtf', output_file[:-11] + 'simlength' + str(simulation_length) + '_transcripts.csv', simulation_length)
processSAMFile(input_file, gtf_list)
outputMatches(output_file, gtf_list)
print('Job is Finished!')