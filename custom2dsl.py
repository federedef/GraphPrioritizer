#!/usr/bin/env python
import argparse

########################### FUNCTIONS #######################
#############################################################


def get_custom_from_file(file):
	parsed_file = []
	options = {}
	fields = []
	with open(file) as f:
		i = 0
		for line in f:
			if i == 0: 
				fields = line.strip().split("\t")
				i+=1
			configs = line.strip().split("\t")
			for j, config in enumerate(configs):
				options[fields[j]] = [config]
	return parsed_file

def unpack_commands(commands):
	unppacked_command = []
	for command in commands.split(";"):
		parameters = command.replace(","," ")
		unppacked_command.append(parameters)

	return unppacked_command


def add2dsl(key_function, parameters, dsl):
	dsl += f"{key_function} {parameters} \n"
	return dsl

########################### OPTPARSE ########################
#############################################################

parser = argparse.ArgumentParser()

parser.add_argument("-i", "--input_file", default=None, help="The root to the file with the custom configuration")
parser.add_argument("-o", "--output_name", default="added_tags", help="The of the dsl file")

options = parser.parse_args()

######################### MAIN #########################
########################################################
dsl = ""

custom_options = get_custom_from_file(options.input_file)

if custom_options.get("Adjacency"):
	key_function = "generate_adjacency_matrix"
	parameters_list = unpack_commands(custom_options["Adjacency"])
	for parameters in parameters_list:
		add2dsl(key_function, parameters, dsl)

if custom_options.get("Sim"):
	key_function = "get_similarity"
	parameters_list = unpack_commands(custom_options["Sim"])
	for parameters in parameters_list:
		add2dsl(key_function, parameters, dsl)

if custom_options.get("Projection"):
	key_function = "get_association_values"
	parameters_list = unpack_commands(custom_options["Projection"])
	for parameters in parameters_list:
		add2dsl(key_function, parameters, dsl)

if custom_options.get("Comb_mat"):
	key_function = "get_association_values"
	parameters_list = unpack_commands(custom_options["Comb_mat"])
	for parameters in parameters_list:
		add2dsl(key_function, parameters, dsl)

if custom_options.get("Write_mat"):
	key_function = "write_mat"
	parameters_list = unpack_commands(custom_options["Write_mat"])
	for parameters in parameters_list:
		add2dsl(key_function, parameters, dsl)
	key_function = "get_stats_from_matrix"
	parameters_list = unpack_commands(custom_options["Write_mat"])
	for parameters in parameters_list:
		add2dsl(key_function, parameters.split(" ")[0], dsl) # gettinh the correct keys mat

if custom_options.get("Filter"):
	# Get filter
	key_function = "get_filter"
	parameters_list = unpack_commands(custom_options["Filter"])
	for parameters in parameters_list:
		add2dsl(key_function, parameters, dsl)
	# Extract adjacency
	key_function = "write_subgraph"
	for parameters in parameters_list:
		add2dsl(key_function, parameters.split(" ")[0]+' '+"output_filename='similarity_matrics'", dsl)
	
	key_function = "get_stats_from_matrix"
	for parameters in parameters_list:
		add2dsl(key_function, parameters.split(" ")[0], dsl)


if custom_options.get("Binarize"):
	# Get filter
	key_function = "binarize_mat"
	parameters_list = unpack_commands(custom_options["Binarize"])
	for parameters in parameters_list:
		add2dsl(key_function, parameters, dsl)
	# Extract adjacency
	key_function = "write_mat"
	parameters_list = unpack_commands(custom_options["Binarize"])
	for parameters in parameters_list:
		add2dsl(key_function, parameters+' '+"output_filename='similarity_matrics'", dsl)
	
	key_function = "get_stats_from_matrix"
	for parameters in parameters_list:
		add2dsl(key_function, parameters.split(" ")[0], dsl)

with open(options.output_name, "w") as f:
		f.write(dsl)
