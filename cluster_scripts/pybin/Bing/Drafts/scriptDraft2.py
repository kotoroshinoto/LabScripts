#script.py
#version 2013.06.07

'''
Options
	#Type in cmd.exe
	C:\\Python27\python C:\\Users\Bing\Videos\script.py
	
	#Use in linux
	/home/bing/Documents
	
	#Use in windows
	C:\\Users\Bing\Videos
	
'''
import methodslist as ml
import xlwt

#Import text to tables
#table1 = ml.importTable('mutect_call_stats.downsample.NC_TC.txt', 'C:\\Users\Bing\Videos')
#table2 = ml.importTable('mutect_call_stats.downsample.NF_TF.txt', 'C:\\Users\Bing\Videos')
table1 = ml.importTable('mutect_call_stats.purity.NC_TC.txt', 'C:\\Users\Bing\Videos')
table2 = ml.importTable('mutect_call_stats.purity.NF_TF.txt', 'C:\\Users\Bing\Videos')

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
unmatched_keeps1 = total_comparison[2] ##
unmatched_keeps2 = total_comparison[3] ##

#Save rows with no detected mutations
rejects1 = ml.saveByValue(table1, 'judgement', 'REJECT')
rejects2 = ml.saveByValue(table2, 'judgement', 'REJECT')

#Compare unmatched KEEP rows of one table to REJECT rows of other table
total_compare_reject2_unmatched1 = ml.compareTables(unmatched_keeps1, rejects2)
matched_reject2_unmatched1 = total_compare_reject2_unmatched1[1] #1 is the second table

total_compare_reject1_unmatched2 = ml.compareTables(unmatched_keeps2, rejects1)
matched_reject1_unmatched2 = total_compare_reject1_unmatched2[1]
'''
#Debug
	ml.outputTable('rejects_NC_TC.txt', rejects1)
	ml.outputTable('rejects_NF_TF.txt', rejects2)

	ml.outputTable('unmatched_NC_TC.txt', unmatched_keeps1)
	ml.outputTable('unmatched_NF_TF.txt', unmatched_keeps2)
	
'''
#Select only certain categories
keeps1 = ml.saveByCategory(keeps1)
keeps2 = ml.saveByCategory(keeps2)
matched_reject1_unmatched2 = ml.saveByCategory(matched_reject1_unmatched2)
matched_reject2_unmatched1 = ml.saveByCategory(matched_reject2_unmatched1)

#Write tables to text files
'''
ml.outputTable(keeps1, 'NC TC KEEP', 'output_keeps.NC_TC.xls')
ml.outputTable(keeps2, 'NF TF KEEP', 'output_keeps.NF_TF.xls')
ml.outputTable(matched_reject1_unmatched2, 'NC TC Matched REJECTS', 'output_reject of unmatched.NC_TC.xls')
ml.outputTable(matched_reject2_unmatched1, 'NF TF Matched REJECTS','output_reject of unmatched.NF_TF.xls')
'''

book = xlwt.Workbook()
sheet1 = book.add_sheet('NC TC KEEP')
sheet2 = book.add_sheet('NF TF KEEP')
sheet3 = book.add_sheet('NC TC Matched REJECTS')
sheet4 = book.add_sheet('NF TF Matched REJECTS')
ml.outputTable(book, keeps1, sheet1, 'output_Pt3A.xls')
ml.outputTable(book, keeps2, sheet2, 'output_Pt3A.xls')
ml.outputTable(book, matched_reject1_unmatched2, sheet3, 'output_Pt3A.xls')
ml.outputTable(book, matched_reject2_unmatched1, sheet4, 'output_Pt3A.xls')
'''
sheet1 = []
sheet2 = []
sheet3 = []
sheet4 = []
ml.outputTable(keeps1, sheet1, 'NC TC KEEP', 'output_Pt3A.xls')
ml.outputTable(keeps2, sheet2, 'NF TF KEEP', 'output_Pt3A.xls')
ml.outputTable(matched_reject1_unmatched2, sheet3, 'NC TC Matched REJECTS', 'output_Pt3A.xls')
ml.outputTable(matched_reject2_unmatched1, sheet4, 'NF TF Matched REJECTS','output_Pt3A.xls')
'''
print 'Finished'