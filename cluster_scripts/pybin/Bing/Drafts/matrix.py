table = [ [0 for i in range(6)] for j in range(6)] #creates the table with multidem matricies
print table

for d1 in range(6): #places values in matrix
	for d2 in range(6):
		table[d1][d2]= d1+d2+2 
print table
