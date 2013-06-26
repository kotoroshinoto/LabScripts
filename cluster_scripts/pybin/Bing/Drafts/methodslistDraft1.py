import numpy as np
import pandas as pd
import os

old_dir = os.getcwd()
os.chdir('/home/bing/Documents')
f = open('table.txt', 'r+')
#f.readline()
#pd.read_csv('table.txt', error_bad_lines=False)
df = pd.read_csv(f)
print df
os.chdir(old_dir)
