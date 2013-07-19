'''
methodslist.py module
version 2013.06.26

@author: Bing
list of methods used to manipulate data
new: ported to python 3.3

'''
# Takes data from file and makes a table
def importTable(input_file_name, a_directory, lines_skip):
	import os
	
	# Set directory
	old_dir = os.getcwd()
	os.chdir(a_directory)
	
	# Read data from input file and place in table
	f = open(input_file_name, 'r')
	# BACKUP f = open('test.txt', 'r')
	f.readline() # reads and ignores the first line
	for x in range(0, lines_skip):
		f.readline()
	doc = f.read()
	table = [s.strip().split('\t') for s in doc.splitlines()]
	
	# Find table size
	rows = len(table)
	print('Input table has %r positions' % rows)
	cols = len(table[0])
	# print('Table has %r categories' % cols)
	
	os.chdir(old_dir)
	return table

# Writes the table to a text file
def outputTable(a_book, a_table, sheet_name, output_directory):
	from xlsxwriter.workbook import Workbook
	
	book = a_book
	sheet = book.add_worksheet(sheet_name)
	try:
		cols = len(a_table[0])
	except IndexError:
		print('Cannot output an empty table')
	rows = len(a_table)
	print('Output table has %r positions' % rows)
	for x in range(0, rows):
		for y in range(0, cols):
			sheet.write(x, y, a_table[x][y])

# Calculates and writes condordance to table
def calcCondordance(first_cols, second_cols, shared_cols):
	# Calculate condordance
	first_num = len(first_cols)-1.0
	second_num = len(second_cols)-1.0
	shared_num = len(shared_cols)-1.0
	total_num = first_num + second_num + shared_num
	
	first_percent = first_num/total_num
	second_percent = second_num/total_num
	shared_percent = shared_num/total_num
	
	# Write concordance to table
	table = [['Concordance', '', '', ''], ['', 'FFPE', 'Both', 'Cryo']]
	table.append(['', second_num, shared_num, first_num])
	table.append(['', second_percent, shared_percent, first_percent])
	return table
	
# Saves rows based on a category value (such as KEEP under judgment)
def saveByValue(a_table, a_category, a_value):
	rows = len(a_table)
	cols = len(a_table[0])
	table_new = []
	table_new.append(a_table[0]) # keep the categories
	for x in range (0, cols):
		if a_table[0][x] == a_category: # find the category's col number
			category_col_num = x
	for x in range (0, rows):
		if a_table[x][category_col_num] == a_value: # compare value at col
			table_new.append(a_table[x])
	return table_new

# Compares position of two tables
def compareTables(first_table, second_table):
	rows_first_table = len(first_table)
	rows_second_table = len(second_table)
	print('Comparing %r to %r positions' % (rows_first_table, rows_second_table))
	same_first_table = []
	same_second_table = []
	diff_first_table = []
	diff_first_table.append(first_table[0]) # keep the categories
	diff_second_table = []
	diff_second_table.append(second_table[0]) # keep the categories
	hash_table_first = {} # avoid writing the same rows repeatedly in table
	hash_table_first[first_table[0][1]] = first_table[0]
	hash_table_second = {}
	hash_table_second[second_table[0][1]] = second_table[0]
	for x in range(0, rows_first_table):
		for y in range(0, rows_second_table):
			if (first_table[x][0] == second_table[y][0] and
				first_table[x][1] == second_table[y][1] and
				first_table[x][3] == second_table[y][3] and
				first_table[x][4] == second_table[y][4]):
				same_first_table.append(first_table[x])
				same_second_table.append(second_table[y])
				hash_table_first[first_table[x][1]] = first_table[x]
				hash_table_second[second_table[y][1]] = second_table[y]
	for x in range(0, rows_first_table):
		for y in range(0, rows_second_table):
			in_first_hash_table = first_table[x][1] in hash_table_first
			if in_first_hash_table is False:
				diff_first_table.append(first_table[x])
				hash_table_first[first_table[x][1]] = first_table[x]
			in_second_hash_table = second_table[y][1] in hash_table_second
			if in_second_hash_table is False:
				diff_second_table.append(second_table[y])
				hash_table_second[second_table[y][1]] = second_table[y]
	compact_result = [same_first_table, same_second_table, diff_first_table, diff_second_table]
	return compact_result

#Saves columns by category
def saveByCategory(a_table): #cannot choose categories
	rows = len(a_table)
	cols = len(a_table[0])
	new_table = []
	selected_cols = [0, 1, 2, 3, 4, 5, 6, 8, 9, 18, 19, 23, 26, 28, 29, 36, 37, 38, 46, 47, 67, 68]
	for x in range(0, rows):
		new_row = []
		for y in selected_cols:
			new_row.append(a_table[x][y])
		new_table.append(new_row)
	return new_table

#End