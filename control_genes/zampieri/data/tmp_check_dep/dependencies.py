#!/usr/bin/env python

from py_semtools import Ontology

ontology = Ontology(file="mondo.obo", load_file=True)
terms = []
with open("file","r") as f:
    for line in f:
        line = line.strip().split("\t")
        terms.append(line[0])
set_terms = set (terms)
term2dep = {}
for term in terms:
    parentals = ontology.get_ancestors(term)
    dependencies = set(parentals) & set_terms
    term2dep[term] = list(dependencies)

for term, deps in term2dep.items():
    term = ontology.translate_id(term)
    deps = [ontology.translate_id(dep) for dep in deps]
    print(f'{term}\t-->\t{"|".join(deps)}')


