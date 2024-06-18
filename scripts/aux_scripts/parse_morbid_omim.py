#!/usr/bin/env python
import sys
import re

def parse_morbid_omim(file):
	# OMIM txt, OMIM code, Genes
	parsed_morbid = []
	with open(file, "r") as f:
		for line in f:
			line = line.strip().split("\t")
			if line[0][0] == "#" or not re.findall("\(3\)",line[0]) or re.findall("\[|\?|\{", line[0]): continue
			omim = line[0]
			genes = line[1].split(",")[0].strip()
			omim = omim.split(',')
			omim_code = omim[-1]
			omim_code = re.findall("[0-9]{6}",omim_code)
			if not omim_code: continue
			omim_code = "OMIM:" + omim_code[0]
			if len(omim.pop()) > 3: omim = omim[0:3]
			omim_txt = ",".join(omim)
			parsed_morbid.append([omim_txt, omim_code, genes])
	return parsed_morbid

parsed_morbid = parse_morbid_omim(sys.argv[1])

for row in parsed_morbid:
	print("\t".join(row))
