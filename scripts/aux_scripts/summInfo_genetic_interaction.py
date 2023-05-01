#!/usr/bin/env python
import argparse

def load_file(file):
	table = []
	with open(file) as f:
		for line in f:
			table.append(line.strip().split("\t"))
	return table

####################### OPTPARSE #################
##################################################

parser = argparse.ArgumentParser()
parser.add_argument("-f", "--genetic_interaction_file", dest = "genetic_interaction_file", default=None, help="The root to the genetic_interaction file")
options = parser.parse_args()

##################### MAIN #######################
##################################################

genetic_interaction_file = load_file(options.genetic_interaction_file)
total_number_of_annotations = []
transposed_genetic_interaction_file = list(map(list, zip(*genetic_interaction_file)))

for col in transposed_genetic_interaction_file:
	col.pop(0)
	number_of_annotations = len([element for element in col if element != ""])
	total_number_of_annotations.append(number_of_annotations)

for number_of_annotations in total_number_of_annotations:
	print(str(number_of_annotations))