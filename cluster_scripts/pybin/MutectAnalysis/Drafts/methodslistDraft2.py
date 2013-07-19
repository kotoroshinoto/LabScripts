#2013.06.06 V2
#C:\\Python27\python C:\\Users\Bing\Videos\read2.py
#cd C:\\Users\Bing\Videos
import os

#Set directory
old_dir = os.getcwd()
#os.chdir('/home/bing/Documents')
os.chdir('C:\\Users\Bing\Videos')

#Read data from input file and place in table
f = open('test.txt', 'r')
f.readline() #reads and ignores the first line
doc = f.read()
table = [s.strip().split('\t') for s in doc.splitlines()]

'''
#Error check
	print '\nError Check 1'
	print 'The table is'
	print table
'''

#Find table size
rows = len(table)
print 'There are %r sample reads' % rows #rows should = 15
cols = len(table[0])
print 'There are %r categories' % cols #cols should = 69

'''
#Error Check
	print '\nError Check 2'
	print 'Column 14 is'
	for x in range(0,rows):
		print table[x][15]
'''

#Write data in new file
output = open('output.txt', 'w')
output.truncate()
for x in range(0, rows):
	for y in range(0, cols):
		#print table[x][y] #debug
		output.write('%r\t' % table[x][y])
	output.write('\n')
output.close()

#Make table of only KEEP
#print '\nTest Table Search' 
table_keeps = []
for x in range (0, rows):
	#print '\n table_keeps1 is %r' % table_keeps
	if table[x][68] == 'KEEP': #look only at column 69, which is KEEP or REJECT
		table_keeps.append(table[x])

keeps_rows = len(table_keeps)
print 'There are %r rows with cited mutations' % keeps_rows
output = open('output_keeps.txt', 'w')
output.truncate()
for x in range(0, keeps_rows):
	for y in range(0, cols):
		#print table[x][y] #debug
		output.write('%r\t' % table_keeps[x][y])
	output.write('\n')
output.close()

os.chdir(old_dir)