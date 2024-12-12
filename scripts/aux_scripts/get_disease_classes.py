#! /usr/bin/env python
import sys

def load_disease_data(file):
    disease_classes = {}
    with open(file, 'r') as f:
        lines = f.readlines()
        for i, line in enumerate(lines):
            if i == 0: continue
            line = line.strip()
            fields = line.split('\t')
            dis_class = fields[2]
            genes = fields[1].split(",")
            if dis_class not in disease_classes:
                disease_classes[dis_class] = set(genes)
            else:
                disease_classes[dis_class].update(genes)
    return disease_classes


input_file = sys.argv[1]
min_genes = int(sys.argv[2])

disease_classes = load_disease_data(input_file)

filtered_disease_classes = {
	dis_class: genes
	for dis_class, genes in disease_classes.items()
	if len(genes) >= min_genes and dis_class != 'Unclassified'
}

for dis_class, genes in filtered_disease_classes.items():
	print(f"{dis_class}\t{','.join(genes)}")