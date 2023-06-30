#!/usr/bin/env python
import argparse
import json 

def load_json(json_path):
	with open(json_path,"r") as f:
		json_dic = json.load(f)
	return json_dic

argparse = argparse.ArgumentParser(description="Pass from customizes parameter json for the different layers to table of key-values")
argparse.add_argument("--net_id", dest = "net_id", help = "the name id of the network layer request")
argparse.add_argument("--json_path", dest = "json_path", help = "the path to the json file")
options =argparse.parse_args()

dic_for_netID = load_json(options.json_path)[options.net_id]
for key, value in dic_for_netID.items():
	if type(value) == list:
		for val in value:
			print(key + "\t" + str(val))
	else:
		print(key + "\t" + str(value))

