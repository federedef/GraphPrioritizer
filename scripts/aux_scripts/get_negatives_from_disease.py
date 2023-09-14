#! /usr/bin/env python
import argparse
import numpy as np 

########################### FUNCTIONS #######################
#############################################################

def write_negatives(file, negatives):
	with open(file, "w") as f:
		for group, nodes in negatives.items():
			f.write(group + "\t" + ",".join(nodes) + "\n")


def get_negatives2groups(disgroup_genes):
	all_genes = set([el for row in disgroup_genes.values() for el in row])
	negatives = {}
	for k, v in disgroup_genes.items():
		smpl_negatives = list(all_genes - set(v))
		negatives[k] = smpl_negatives
	return negatives

def get_negatives2disease(diseases_disgroup, disgroup_negatives, diseases_genes, pickrandom = True):
	negatives = {}
	for disease, disgroup in diseases_disgroup.items():
		smpl_negatives = disgroup_negatives[disgroup]
		genes = diseases_genes[disease]
		if pickrandom: 
			number_of_positives = len(set(genes))
			number_of_negatives = int(np.floor(number_of_positives / 2))
			smpl_negatives = list(np.random.choice(smpl_negatives, number_of_negatives, replace=False))
		negatives[disease] = smpl_negatives
	return negatives


def load_node_groups_from_file(file, sep= ','):
	diseases = {}
	disgroup_genes = {}
	diseases_genes = {}
	with open(file) as f:
		for line in f:
			disease_name, disgroup, genes = line.strip().split("\t")
			diseases[disease_name] = disgroup
			diseases_genes[disease_name] = genes.split(sep)
			if disgroup_genes.get(disgroup) is None:
				disgroup_genes[disgroup] = genes.split(sep)
			else:
				disgroup_genes[disgroup].extend(genes.split(sep))
	return diseases, disgroup_genes, diseases_genes


########################### OPTPARSE ########################
#############################################################

parser = argparse.ArgumentParser(description='Process some integers.')

parser.add_argument('-i', '--input_positives', required=True,
					help='The roots for the positive file')

parser.add_argument('-o', '--output_name', default='negatives',
					help='The name of the ranked file')

parser.add_argument("--subset_randomly_negatives", default=True, action= "store_false", help=" Select this to choos all background as negatives")

options = parser.parse_args()

########################### MAIN ############################
#############################################################

positive_file = options.input_positives
output_name = options.output_name

diseases_disgroup, disgroup_genes, diseases_genes = load_node_groups_from_file(positive_file)
disgroup_negatives = get_negatives2groups(disgroup_genes)
diseases_negatives = get_negatives2disease(diseases_disgroup, disgroup_negatives, diseases_genes)

if diseases_negatives is not None:
	write_negatives(output_name, diseases_negatives)