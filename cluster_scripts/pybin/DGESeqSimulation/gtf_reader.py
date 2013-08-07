"""
gtf_reader.py script
version 2013.08.06

@author: Bing
parses GTF file and stores information into exon and transcript objects

"""
import os, sys, pickle
import transcriptstools as ttools

def processGTF(gtf_filename, transcriptlist_filename, simulation_length):
    """parses GTF file stores information into transcript list"""
    # set and initialize variables
    transcript_dictionary = {}
    transcript_count = 1
    
    # file IO
    input_file = open(input_filename,'r')
    for line in input_file:
        # parse and format GTF lines of text
        line = line.split('\t')
        if line[8].endswith(';\n'): # remove ';\n' from end of every line
            line[8] = line[8][:-2]
        elif line[8].endswith(';'): # last line does not have \n
            line[8] = line[8][:-1]
        
        # further split last column + adds all new columns to original list
        line[8] = line[8].replace('"', '').strip() # removes double quotes from certain values
        last_col = line[8].split('; ')
        new_col = []
        for x in range(0, len(last_col)):
            parts = last_col[x].split(' ')
            new_col.append(parts[0])
            new_col.append(parts[1])
        last_col = new_col
        line.pop()
        line.extend(last_col)
        
        # store exon information in object
        exon = ttools.Exon(line)
        # add exon to hash list
        transcript_dictionary, transcript_count = ttools.buildTranscriptDictionary(exon, transcript_dictionary, transcript_count)
    
    # print frequency of each transcript + calculate 3' end of gene
    for key in transcript_dictionary:
        instance = transcript_dictionary[key]
        instance.setGeneEnd(simulation_length)
        transcript_dictionary[key] = instance
    
    # store transcripts in dictionary with chromosome as key
    transcript_List = ttools.buildTranscriptList(transcript_dictionary)
    
    # write transcript list to file
    input_file.close()
    output_file = open(output_filename, 'wb')
    pickle.dump(transcript_List, output_file)
    output_file.close()
    print('\n\nNew transcript list is made!\n\n')
    os.chdir(old_dir)
def checkListExistance(gtf_filename, transcriptlist_filename, simulation_length):
    """checks if transcript list already exists"""
    if os.path.exists(transcriptlist_filename):
        print('\n######\n\nThe transcript list already exists and does not need to be created. You have just saved 3 minutes of your life! Delete the old list if you wish to build a new transcript list.\n\n######\n')
        return True
    else:
        print('Building new transcript list...')
        return False

# START OF SCRIPT
# define argument input
# example: gtf_reader.py genes.gtf 200
if len(sys.argv) != 3:
    sys.stderr.write("\nScript must be given 2 arguments: input gtf filename and simulation sequence length")
input_filename = sys.argv[1]
output_filename = 'transcripts_simlength' + sys.argv[2] + '.csv'
simulation_length = int(sys.argv[2])

# file IO
old_dir = os.getcwd()
os.chdir(input_directory = os.path.join(os.path.dirname(__file__), 'Input'))
isListExistant = checkListExistance(input_filename, output_filename, simulation_length)
if not isListExistant:
    processGTF(input_filename, output_filename, simulation_length)