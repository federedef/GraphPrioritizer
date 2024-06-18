#! /usr/bin/env python

import argparse, os, copy, numpy
import warnings
from py_semtools import OboParser, Ontology
import py_exp_calc.exp_calc	as pxc

def load_pairs_file(filename):
    dict_disease_to_hp = {}
    with open(filename, "r") as f:
        for line in f:
            mondo, hpo = line.strip().split("\t")
            query = dict_disease_to_hp.get(mondo)
            if query is None:
                dict_disease_to_hp[mondo] = [hpo]
            else:
                dict_disease_to_hp[mondo].append(hpo)
    return dict_disease_to_hp

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
    ds_cls_terms = disorder_class.keys()
    dis_class = set(ds_cls_terms)
    disease2disclass = {}
    dependency_map = get_dependency_map(ds_cls_terms)
    term2ic = get_term2ic(dis_class, ontology)
    for disease in diseases:
        parents = ontology.get_ancestors(disease)
        # intersect
        #if "MONDO:0021147" in parents or "MONDO:0005071" in parents: continue
        # Syndromics terms: "MONDO:0002254" Multiple
        # direct classify: "MONDO:0045024" Cancer
        # exclusive clasify: "MONDO:0005071" System nervious

        # syndromic indicator
        nmax = 3
        if "MONDO:0002254" in parents: 
            nmax = 2
        # Direct or not classifier
        if "MONDO:0045024" in parents: # One way terms (e.g. cancer)
            parents = ["MONDO:0045024"]
        else:
            parents = set(parents) & dis_class
            parents = just_child_dependencies(parents, dependency_map)
        # Exlusive term
        if "MONDO:0005071" in parents:
                nmax = 1
        number_classes = len(parents)
        if number_classes == 0:
            disclass = "unclasiffied"
        elif number_classes > nmax:
            disclass = "multiple"
        else:
            max_term = ""
            max_ic = 0
            for parent in parents:
                ic = term2ic[parent]
                if ic > max_ic:
                    max_ic = ic
                    max_term = parent 
            disclass = disorder_class[max_term][0]
            disclass = disorder_class[max_term][0]
        disease2disclass[disease] = [disclass, number_classes]
    return disease2disclass

def just_child_dependencies(terms, dependency_map):
    filtered_terms = terms
    for term in terms:
        if dependency_map.get(term):
                terms2remove = dependency_map[term]
                filtered_terms = filtered_terms - terms2remove
        continue
    return filtered_terms

def get_dependency_map(terms):
    set_terms   = set(terms)
    term2dep = {}
    for term in terms:
        parentals = ontology.get_ancestors(term)
        dependencies = set(parentals) & set_terms
        if dependencies:
                term2dep[term] = dependencies
    return term2dep

def get_term2ic(terms, ontology):
    term2ic = {}
    for term in terms:
        term2ic[term] = ontology.get_IC(term)
    return  term2ic 


ontology = Ontology(file= options.get("ontology"), load_file = True)
disorder_class = load_pairs_file(options["disorder_class"])

disease_genes = load_file(options["input_file"])
diseases = list(set([disease for disease, genes in disease_genes]))
disease2disclass = get_dis2dclass(diseases, disorder_class, ontology)

with open(options["output_file"], "w") as f:
	for disease, genes in disease_genes:
		if disease2disclass.get(disease):
				f.write(f"{ontology.translate_id(disease)}\t{genes}\t{disease2disclass[disease][0]}\t{disease2disclass[disease][1]}\n")
				#f.write(f"{disease}\t{genes}\t{disease2disclass[disease][0]}\t{disease2disclass[disease][1]}\n")


