#! /usr/bin/env python
import argparse, os, copy, numpy
import warnings
from py_semtools import OboParser, Ontology
from py_semtools.sim_handler import *

############################################################################################
## METHODS
############################################################################################

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
            term = line.strip()
            terms.append(term)
    return terms

def filter_out_non_leafs_nodes(mondo_terms, ontology):
    filtered = []
    for term in mondo_terms:
        childs = ontology.get_descendants(term)
        if not childs or len(childs) == 0:
            filtered.append(term)
    return filtered

def get_parent_and_childs_nodes_dict(mondo_terms, ontology):
    parent_to_childs_dict = {}
    for term in mondo_terms:
        parents = ontology.get_direct_related(term, relation="ancestor")
        for parent in parents:
            query = parent_to_childs_dict.get(parent)
            if query is None:
                parent_to_childs_dict[parent] = [term]
            else:
                parent_to_childs_dict[parent].append(term)
    
    parent_to_childs_dict = {parent: childs for parent, childs in parent_to_childs_dict.items() if len(childs) > 1}
    return parent_to_childs_dict

def get_txt_to_txt_similarities(parent_to_childs_txt):
    similarities = {}
    for parent, txts in parent_to_childs_txt.items():
        if len(txts) > 1: similarities[parent] = similitude_network(txts, charsToRemove = options.get("rm_char"))
    return similarities

def get_thresholded_childs_to_parents_dict(similarities, threshold, ontology, txt_to_term = None, uniq_parent = False):
    terms_to_collapse = {}

    for parent, childs in similarities.items():
        for child1, other_childs in childs.items():
            for child2, similarity in other_childs.items():     
                # Watch out: This is selecting for childs with at least one similarity beyond the threshold.  
                if similarity >= threshold:
                    # Just neccesary the parent id. translated_parent = ontology.translate_name(parent)
                    if txt_to_term:
                        child1_term = txt_to_term[child1]
                        child2_term = txt_to_term[child2]

                    if terms_to_collapse.get(child1_term) == None: 
                        terms_to_collapse[child1_term] = [parent]
                    else:
                        terms_to_collapse[child1_term].append(parent)
                
                    if terms_to_collapse.get(child2_term) == None: 
                        terms_to_collapse[child2_term] = [parent]
                    else:
                        terms_to_collapse[child2_term].append(parent)
    if uniq_parent: 
        terms_to_collapse = get_collapsed_with_unique_parents(ontology, terms_to_collapse, txt_to_term, term_to_txt)
    else:
        terms_to_collapse = { child: list(set(parents)) for child, parents in terms_to_collapse.items() }

    return terms_to_collapse


def get_collapsed_with_unique_parents(ontology, terms_to_collapse):
    collapsed_with_unique_parents = {}
    for child, parents in terms_to_collapse.items():
        parents = list(set(parents))
        parents_depth = [ontology.term_paths[parent]["largest_path"] for parent in parents]
        max_depth_indexes = [i for i, x in enumerate(parents_depth) if x == max(parents_depth)]
        if len(max_depth_indexes) == 1:
            collapsed_with_unique_parents[child] = [parents[max_depth_indexes[0]]]
        else:
            deepest_parents = [parents[i] for i in max_depth_indexes]
            translated_child = ontology.translate_id(child)
            translated_parents = [ontology.translate_id(parent) for parent in deepest_parents]
            similarities = similitude_network([translated_child] + translated_parents, charsToRemove = options.get("rm_char"))
            collapsed_with_unique_parents[child] = [ontology.translate_name(max(similarities[translated_child].items(), key=lambda x: x[1])[0])]
    return collapsed_with_unique_parents

############################################################################################
## OPTPARSE
############################################################################################
parser = argparse.ArgumentParser(description=f'Usage: {os.path.basename(__file__)} [options]')

parser.add_argument("-i", "--input_file", dest="input_file", default= None,
                    help="Input file with the ontology terms")

parser.add_argument("-n", "--terms2text", dest="terms2text", default= None,
                    help="Input file with the ontology terms and its respective text")

parser.add_argument("--with_annotation", dest="with_annotations", default= False, action ="store_true",
                    help="If your input files cotains annotations in a tabulated format of two columns: term | annotation")

parser.add_argument("-O", "--ontology", dest="ontology", default= None, 
                    help="Path to the ontology file")

parser.add_argument("-o", "--output_file", dest="output_file", default= None, 
                    help="Path to the output file to write results")

parser.add_argument("-r", "--remove_chars", dest="rm_char", default="", 
                    help="Chars to be excluded from comparissons.")

parser.add_argument("-t", "--threshold", dest="threshold", default=0.00, type=float,
                    help="Threshold to consider a pair of terms similar")

parser.add_argument("-u","--uniq_parent", dest="uniq_parent", default= False, action = "store_true",
                    help="Just add the uniq most representative parent")

opts = parser.parse_args()
options = vars(opts)

############################################################################################
## MAIN
############################################################################################

ontology = Ontology(file= options.get("ontology"), load_file = True)
if options["with_annotations"]:
    terms_to_annot = load_pairs_file(options["input_file"])
    terms = list(set(terms_to_annot.keys()))
else:
    terms = load_file(options.get("input_file")) 

# TODO: If a txt 2 tal file, then, we use the names on the ontology.
if options["terms2text"]:
    term_to_txt = load_pairs_file(options.get("terms2text"))
    term_to_txt = {key: value[0] for key, value in term_to_txt.items()}
else: 
    term_to_txt = {term: ontology.translate_id(term) for term in terms}

# Selecting just when we got the txt associated
terms = [term for term in terms if term in term_to_txt.keys()]

txt_to_term = {value: key for key, value in term_to_txt.items()}
# Optional?
#leaf_terms = filter_out_non_leafs_nodes(list(set(terms)), ontology)
leaf_terms = list(set(terms))

# Neccesary
parent_to_childs_terms = get_parent_and_childs_nodes_dict(leaf_terms, ontology)
parent_to_childs_txt = {parent: [term_to_txt[child] for child in childs] for parent, childs in parent_to_childs_terms.items()}
similarities = get_txt_to_txt_similarities(parent_to_childs_txt)
terms_to_collapse = get_thresholded_childs_to_parents_dict(similarities, threshold = options.get("threshold"), ontology=ontology, txt_to_term = txt_to_term, uniq_parent = options["uniq_parent"])

with open(options["output_file"], "w") as f:
    # Wath out: This is implying that all term which are not leafs would be added!
    for term in terms:
        term_id = ""
        if terms_to_collapse.get(term) is not None:
            parents = terms_to_collapse[term]
        else:
            parents = [term]
        for parent in parents:
            if options["with_annotations"]:
                for annot in terms_to_annot[term]:
                    f.write(f"{parent}\t{term}\t{annot}\n")
            else:
                f.write(f"{parent}\t{term}\n")