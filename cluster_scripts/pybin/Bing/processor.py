#processor.py
#version 2013.06.10

def processFiles(first_file, second_file , input_directory, output_file, output_directory):
	import methodslist as ml
	import xlwt
	import os
	
	# Set directory
	old_dir = os.getcwd()
	os.chdir(output_directory)
	
	print '\nStarting at %r' % input_directory

	#Import text to tables
	table1 = ml.importTable(first_file, input_directory)
	table2 = ml.importTable(second_file, input_directory)

	#Save rows with detected mutations
	keeps1 = ml.saveByValue(table1, 'judgement', 'KEEP')
	keeps2 = ml.saveByValue(table2, 'judgement', 'KEEP')

	#Find mutated rows with that are matched and unmatched
	total_comparison = ml.compareTables(keeps1, keeps2)
	'''
	0 is same_first_table
	1 is same_second_table
	2 is diff_first_table
	3 is diff_second_table

	'''
	matched_keeps1 = total_comparison[0]
	matched_keeps2 = total_comparison[1]
	unmatched_keeps1 = total_comparison[2]
	unmatched_keeps2 = total_comparison[3]
	
	#Save rows with no detected mutations
	rejects1 = ml.saveByValue(table1, 'judgement', 'REJECT')
	rejects2 = ml.saveByValue(table2, 'judgement', 'REJECT')

	#Compare unmatched KEEP rows of one table to REJECT rows of other table
	total_compare_reject2_unmatched1 = ml.compareTables(unmatched_keeps1, rejects2)
	matched_reject2_unmatched1 = total_compare_reject2_unmatched1[1] #1 is the second table
	total_compare_reject1_unmatched2 = ml.compareTables(unmatched_keeps2, rejects1)
	matched_reject1_unmatched2 = total_compare_reject1_unmatched2[1]

	#Select only certain categories
	keeps1 = ml.saveByCategory(keeps1)
	keeps2 = ml.saveByCategory(keeps2)
	matched_reject2_unmatched1 = ml.saveByCategory(matched_reject2_unmatched1)
	matched_reject1_unmatched2 = ml.saveByCategory(matched_reject1_unmatched2)

	#Write tables to text files
	book = xlwt.Workbook()
	ml.outputTable(book, keeps1, 'NC TC KEEP', output_directory)
	ml.outputTable(book, keeps2, 'NF TF KEEP', output_directory)
	ml.outputTable(book, matched_reject2_unmatched1, 'NF TF Matched REJECTS', output_directory)
	ml.outputTable(book, matched_reject1_unmatched2, 'NC TC Matched REJECTS', output_directory)

	#Calculate concordance between NC TC and NF TF
	rejects1_unmatched_num = len(unmatched_keeps1)-1.0
	rejects2_unmatched_num = len(unmatched_keeps2)-1.0
	keeps_num = len(keeps1)-1.0
	total_num = rejects1_unmatched_num + rejects2_unmatched_num + keeps_num
	rejects1_unmatched_percent = rejects1_unmatched_num/total_num * 100 
	rejects2_unmatched_percent = rejects2_unmatched_num/total_num * 100
	keeps_percent = keeps_num/total_num * 100
	'''
	print '\nConcordance:'
	print '%.2f percent is Concordant' % keeps_percent
	print '%.2f percent is only NC TC' % rejects1_unmatched_percent
	print '%.2f percent is only NF TF' % rejects2_unmatched_percent
	print '\n'
	'''
	summary_table = [['Concordance', '', '', ''], ['', 'FFPE', 'Both', 'Cryo']]
	summary_table.append(['', rejects2_unmatched_num, keeps_num, rejects1_unmatched_num])
	summary_table.append(['', rejects2_unmatched_percent, keeps_percent, rejects1_unmatched_percent])
	ml.outputTable(book, summary_table, 'Concordance Summary', output_directory)
	
	book.save(output_file)
	os.chdir(old_dir)
	print 'Finished'