"""
aligntables.py script
version 2013.08.09

@author: Bing
takes data from two spreadsheets and aligns the independent variables

"""
import os, sys

input_dir = os.path.join(os.path.dirname(__file__), 'Output')
old_dir = os.getcwd()
os.chdir(input_dir)
'''
if len(sys.argv) != 3:
    sys.stderr.write('\nScript must be given 2 input files')
filename1 = sys.argv[1]
filename2 = sys.argv[2]
'''
def aligntables(filename1, filename2):
    f1 = open(filename1, 'r')
    f2 = open(filename2, 'r')
    f3 = open('Matched_SeqSim_Pt4_' + filename1[11:14] + filename2[11:14] + 'comparison.txt', 'w')
    f4 = open('Unmatched_SeqSim_Pt4_' + filename1[11:14] + filename2[11:14] + 'comparison.txt', 'w')
    
    f1_transcripts = {}
    f2_transcripts = {}
    
    for line1 in f1:
        line1 = line1.split('\t')
        f1_transcripts[line1[0]] = [line1[0], line1[2]]
    for line2 in f2:
        line2 = line2.split('\t')
        f2_transcripts[line2[0]] = [line2[0], line2[2]]
        if not line2[0] in f1_transcripts:
            f1_transcripts[line2[0]] = [line2[0], '0']
    for keys in f1_transcripts:
    
    '''
    f1_table = []
    f2_table = []
    
    for line1 in f1:
        for line2 in f2:
            line2 = line2.split('\t')
            f2_table.append(line2)
        linesplit1 = line1.split('\t')
        for x in range(0, len(f2_table)):
            if linesplit1[0] == f2_table[x][0]:
                f3.write(line1)
            else:
                f4.write(line1)
        f1_table.append(line1 + '\n')
    '''
    f1.close()
    f2.close()
    f3.close()
    f4.close()

aligntables('SeqSim_Pt4_NC_results.txt', 'SeqSim_Pt4_TC_results.txt')
aligntables('SeqSim_Pt4_NF_results.txt', 'SeqSim_Pt4_TF_results.txt')
aligntables('SeqSim_Pt5_NC_results.txt', 'SeqSim_Pt5_TC_results.txt')
aligntables('SeqSim_Pt5_NF_results.txt', 'SeqSim_Pt5_TF_results.txt')