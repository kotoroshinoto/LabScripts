"""
gtf_reader.py module
version 2013.07.24

@author: Bing
parses GTF file and stores information into exon and transcript objects

"""
import os, pickle
import transcriptstoolsVersion1 as ttools

def processGTF(input_directory, gtf_filename, transcript_list_filename, simulation_length):
    # set and initialize variables
    transcript_list = {}
    transcript_count = 1
    
    # file IO
    old_dir = os.getcwd()
    os.chdir(input_directory)
    f = open(gtf_filename,'r')
    
    for line in f:
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
        transcript_list, transcript_count = ttools.buildList(exon, transcript_list, transcript_count)
    
    # print frequency of each transcript + calculate 3' end of gene
    for key in transcript_list:
        instance = transcript_list[key]
        instance.setGeneEnd(simulation_length)
        transcript_list[key] = instance
    
    # write transcript list to file
    f.close()
    output = open(transcript_list_filename, 'wb')
    pickle.dump(transcript_list, output)
    output.close()
    print('\n\nNew transcript list is made!\n\n')
    os.chdir(old_dir)