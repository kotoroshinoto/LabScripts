"""
gtf_reader.py module
Version 2013.07.24

@author: Bing

"""
import os
import transcriptstools as ttools

def processGTF(input_directory, filename):
    # set and initialize variables
    ##input_directory = os.path.join(os.path.dirname(__file__), 'Input')
    ##filename = 'test.gtf'
    transcript_list = {}

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
        
        # store exon information in object
        exon = ttools.Exon(line)
        # add exon to hash list
        transcript_list = ttools.buildList(exon, transcript_list)
    
    # print frequency of each transcript + calculate 3' end of gene
    for key in transcript_list:
        instance = transcript_list[key]
        instance.setGeneEnd()
        transcript_list[key] = instance
        ##print('%s contains %s exons and ends at %s on %s' % (instance.name, instance.num_exons, instance.threeprimeloc, instance.chromosome))
    
    # reset file IO
    f.close()
    
    g = open('transcript_list.txt', 'w')
    g.write(transcript_list)
    print('\n\n\nNew transcript list is made!\n\n\n')
    os.chdir(old_dir)