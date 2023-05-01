#!/usr/bin/env python
import argparse
import os

def load_file(file):
	table = []
	with open(file, "r") as f: 
		for line in f:
			table.append(line.strip().split("\t"))
	return table


def filter_by_whitelist(table, terms2filter, column2filter, by_row=False):
	filtered_table = []
	if by_row == False:
		filtered_table = [row for row in table if row[column2filter] in terms2filter]
	else:
		transposed_table = list(map(list, zip(*table)))
		filtered_transposed_table = [row for row in transposed_table if row[column2filter] in terms2filter]
		filtered_table = list(map(list, zip(*filtered_transposed_table)))
	return filtered_table

####################### ARGPARSE #################
##################################################
parser = argparse.ArgumentParser()

parser.add_argument("-f", "--files2befiltered", default= None, type = lambda x: x.split(","), required=True, help="The root to the files that has to be filtered, separated by commas")
parser.add_argument("-c", "--columns2befiltered", default = None, type = lambda	x: [map(int,r.split(",")) for r in x.split(";")] ,help="The columns that need to be filtered for each file, separated by semicolons, with each set of columns separated by commas")
parser.add_argument("-r", "--transpose", dest= "by_row", default= False, action="store_true", help="If you want to select by rows")
parser.add_argument("-t", "--terms2befiltered", default= None, required=True, help="The PATH to the list of terms to be filtered")
parser.add_argument("-o", "--output_path", default=".", help="The name of the output path")

options = parser.parse_args()

##################### MAIN #######################
##################################################

files2befiltered = options.files2befiltered
columns2befiltered = options.columns2befiltered
files_columns2befiltered = list(zip(files2befiltered,columns2befiltered))


terms2befiltered = [term[0] for term in load_file(options.terms2befiltered)]
output_path = options.output_path

file_filteredfile = {}

for file_columns in files_columns2befiltered:
	file = file_columns[0]
	columns = file_columns[1]
	table = load_file(file)
	for column in columns:
		table = filter_by_whitelist(table, terms2befiltered, column, by_row=options.by_row)
	file_filteredfile[file] = table


for file_path, filtered_table in file_filteredfile.items():
	file_name = os.path.basename(file_path)
	with open(os.path.join(output_path,"filtered_" + file_name), "w") as f:
		for line in filtered_table:
			f.write("\t".join(line)+"\n")
