#! /usr/bin/env python

import argparse, os, copy, numpy
import warnings
from py_semtools import OboParser, Ontology
import py_exp_calc.exp_calc	as pxc

def load_file(filename):
    terms = []
    with open(filename, "r") as f:
        for line in f:
            term = line.strip().split("\t")
            terms.append(term)
    return terms

############################################################################################
## OPTPARSE
############################################################################################
parser = argparse.ArgumentParser(description=f'Usage: {os.path.basename(__file__)} [options]')

parser.add_argument("-i", "--input_file", dest="input_file", default= None,
                    help="Input file with the ontology term and genes")

parser.add_argument("-C", "--disorder_class", dest="disorder_class", default= None,
                    help="Input file with the ontology terms and its respective text")

parser.add_argument("-O", "--ontology", dest="ontology", default= None, 
                    help="Path to the ontology file")

parser.add_argument("-o", "--output_file", dest="output_file", default= None, 
                    help="Path to the output file to write results")

opts = parser.parse_args()
options = vars(opts)

#################################### 
# MAIN 
####################################

def get_dis2dclass(diseases, disorder_class, ontology):
	dis_class = set(disorder_class)
	disease2disclass = {}
	dependency_map = get_dependency_map(disorder_class)
	term2ic = get_term2ic(dis_class, ontology)
	for disease in diseases:
		parents = ontology.get_ancestors(disease)
		# intersect
		parents = set(parents) & dis_class
		parents = just_child_dependencies(parents, dependency_map)
		number_classes = len(parents)
		if number_classes == 0:
			disclass = "unclasiffied"
		elif number_classes > 3:
			disclass = "multiple"
		else:
			max_term = ""
			max_ic = 0
			for parent in parents:
				ic = term2ic[parent]
				if ic > max_ic:
					max_ic = ic
					max_term = parent 
			disclass = ontology.translate_id(max_term)	
		disease2disclass[disease] = [disclass, number_classes]
	return disease2disclass

def just_child_dependencies(terms, dependency_map):
	filtered_terms = terms
	for term in terms:
		if dependency_map.get(term):
				terms2remove = dependency_map[term]
				filtered_terms = pxc.diff(filtered_terms, terms2remove)
		continue
	return filtered_terms


def get_dependency_map(terms):
	set_terms	= set(terms)
	term2dep = {}
	for term in terms:
	    parentals = ontology.get_ancestors(term)
	    dependencies = set(parentals) & set_terms
	    if dependencies:
	    		term2dep[term] = list(dependencies)
	return term2dep

def get_term2ic(terms, ontology):
	term2ic = {}
	for term in terms:
		term2ic[term] = ontology.get_IC(term)
	return	term2ic	


ontology = Ontology(file= options.get("ontology"), load_file = True)
disorder_class = load_file(options["disorder_class"])
disorder_class = [dis_class[0] for dis_class in disorder_class]

print(disorder_class)
disease_genes = load_file(options["input_file"])
diseases = list(set([disease for disease, genes in disease_genes]))
disease2disclass = get_dis2dclass(diseases, disorder_class, ontology)

with open(options["output_file"], "w") as f:
	for disease, genes in disease_genes:
		f.write(f"{disease}\t{genes}\t{disease2disclass[disease][0]}\t{disease2disclass[disease][1]}\n")


