"""
gtf_reader.py module
Version 2013.07.23

@author: Bing

"""
import os
import transcriptstools as ttools

def processGTF(input_directory, filename):
    # set and initialize variables
    ##input_directory = os.path.join(os.path.dirname(__file__), 'Input')
    ##filename = 'test.gtf'
    transcript_list = {}
    gtf_table = []

    # file IO
    old_dir = os.getcwd()
    os.chdir(input_directory)
    f = open(filename,'r')

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
        
        # store transcript information in object
        transcript = ttools.Transcript()
        id_index = 10
        if line[id_index] == 'transcript_id':
            transcript.confirmation = True
            transcript.name = line[id_index + 1]
            transcript.chromosome = line[0]
            transcript.direction = line[6]
            if transcript.direction == '+':
                transcript.start.append(line[3])
                transcript.end.append(line[4])
            elif transcript.direction == '-':
                transcript.start.append(line[4])
                transcript.end.append(line[3])
            else:
                raise SyntaxError('Data incorrectly states whether transcript is foward/reverse read\n')
        else:
            raise IOError('transcript_id is not in the correct column\n')
        
        # add transcript to hash list
        transcript_list = ttools.buildList(transcript, transcript_list)
        
        # store lines in table
        gtf_table.append(line)
    
    # print frequency of each transcript + calculate 3' end of gene
    for key in transcript_list:
        instance = transcript_list[key]
        instance.setGeneEnd()
        transcript_list[key] = instance
        ##print('%s contains %s exons and ends at %s on %s' % (instance.name, instance.num_exons, instance.threeprimeloc, instance.chromosome))
        
    # reset file IO
    f.close()
    os.chdir(old_dir)
    print('\n\n\nTranscript is made!\n\n\n')
    return transcript_list