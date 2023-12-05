#!/usr/bin/env python
import argparse
import os

def load_string(string_file, separator):
    string_data = {}
    cnames = []
    with open(string_file) as f:
        for line in f:
            fields = line.strip().split(separator)
            if not cnames:
                cnames = fields[2:]
                for cname in cnames:
                    string_data[cname] = []
                continue
            for idx, cname in enumerate(cnames):
                idx_col = idx + 2
                string_data[cname].append([fields[0], fields[1], fields[idx_col]])
    return string_data

def write_string(string_data, output_path):
    for interact_type, interactions in string_data.items():
        with open(os.path.join(output_path, f"string_ppi_{interact_type}"), "w") as f:
            for interaction in interactions:
                if float(interaction[2]) > 0:
                    f.write( "\t".join(interaction) + "\n")

######## PARSING ##############
parser = argparse.ArgumentParser("to create stirng for every score")
parser.add_argument("-i", "--string_file",dest="string_file", type=str, help="Add string file with format column in tabs and: ID1-ID2-S1-...-SN-Combined_score")
parser.add_argument("-o", "--output_path", dest="output_path", type=str, help="Path to folder where files will be written")
parser.add_argument("-s","--separator",dest="separator",type=str,default="\t", help="this is to indicate the separator btwn columns")
args = parser.parse_args()
######## MAIN ##########

string_data = load_string(args.string_file, separator=args.separator)
write_string(string_data, args.output_path)