#!/usr/bin/env python
# coding: utf-8
import argparse
import os

def get_PS_genes(file):
        f = open(file, 'r')
        part_body_table = False
        genes = []
        PS=None
        for line in f:
                row = line.strip("\n")

                if row.startswith("Phenotypic Series"):
                        PS= row.split("-")[1].strip()

                if row == '':
                        part_body_table=False
                
                if part_body_table == True:
                        gene=row.split("\t")[5].split(",")[0].strip()
                        if gene != "":
                                genes.append(gene)

                if row.startswith("Location"):
                        part_body_table=True

        f.close()

        return PS,list(set(genes))


if __name__=="__main__":
        parser = argparse.ArgumentParser(description="Add the adcacency matrix and the output name for the embbeded matrix")
        parser.add_argument("-i", "--input", dest="input",
                help="Input Path to the folder with all the PS files")
        parser.add_argument("-o", "--output", required=False,dest="output", default="ps_genes.txt",
                help="Output file")
        options = parser.parse_args()

basepath = os.path.abspath(options.input)

all_PS_files=os.listdir(options.input)

ps2genes = {}
for ps_file in all_PS_files:
        ps, genes = get_PS_genes(os.path.join(basepath, ps_file))
        if genes != []:
                ps2genes[ps] = genes

with open(options.output, 'w') as f:
        for PS, genes in ps2genes.items():
                f.write(str(PS) + "\t" + ",".join(genes) + "\n")
