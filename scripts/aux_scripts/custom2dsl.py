#!/usr/bin/env python
import argparse

########################### FUNCTIONS #######################
#############################################################

def get_custom_from_file(file):
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
				options[fields[j]] = config
	return options

def unpack_commands(commands):
	unppacked_command = []
	print(commands)
	for command in commands.split("/"):
		parameters = command.replace(";"," ")
		unppacked_command.append(parameters)

	print(unppacked_command)

	return unppacked_command


def as_dsl_format(key_function, parameters):
	dsl = f"{key_function} {parameters} \n"
	return dsl

def add_dsl(key_function, commands, mod_parameters = lambda x: x):
	dsl = ""
	parameters_list = unpack_commands(commands)
	for parameters in parameters_list:
		dsl += as_dsl_format(key_function, mod_parameters(parameters))
	return dsl

def parameters2dic(parameters):
	parameters_dic = {key: value for key, value in parameters.split()}

########################### OPTPARSE ########################
#############################################################

parser = argparse.ArgumentParser()

parser.add_argument("-i", "--input_file", default=None, help="The root to the file with the custom configuration")
parser.add_argument("-o", "--output_name", default="added_tags", help="The of the dsl file")

options = parser.parse_args()

######################### MAIN #########################
########################################################
dsl = ""

# TODO: 
custom_options = get_custom_from_file(options.input_file)

if custom_options.get("Adjacency") != "-" and custom_options.get("Adjacency") is not None :
	dsl += add_dsl("generate_adjacency_matrix", custom_options["Adjacency"])

if custom_options.get("Sim") != "-" and custom_options.get("Sim") is not None :
	dsl += add_dsl("get_similarity", custom_options["Sim"])

if custom_options.get("Projection") != "-" and custom_options.get("Projection") is not None :
	dsl += add_dsl("get_association_values", custom_options["Projection"])

if custom_options.get("Comb_mat") != "-" and custom_options.get("Comb_mat") is not None :
	dsl += add_dsl("mat_vs_mat_operation", custom_options["Comb_mat"])

if custom_options.get("Write_mat") != "-" and custom_options.get("Write_mat") is not None :
	dsl += add_dsl("write_matrix", custom_options["Write_mat"])
	# Now we prepare the parameters needed.
	dsl += add_dsl("write_stats_from_matrix", custom_options["Write_mat"], mod_parameters = lambda x: x.split(" ")[0])

if custom_options.get("Filter") != "-" and custom_options.get("Filter") is not None :
	# Get filter
	dsl += add_dsl("filter_matrix", custom_options["Filter"])
	# Extract adjacency
	dsl += add_dsl("write_matrix", "mat_keys=('modified_mats',('gene','gene'),'filtered');output_filename='similarity_matrix_bin'")
	# Get statistics
	dsl += add_dsl("write_stats_from_matrix", "mat_keys=('modified_mats',('gene','gene'),'filtered');output_filename='stats_from_matrix'")

with open(options.output_name, "w") as f:
	f.write(dsl)