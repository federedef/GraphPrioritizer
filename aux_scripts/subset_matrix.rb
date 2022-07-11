#! /usr/bin/env ruby
require 'optparse'
require 'npy'
require 'numo/narray'


def lst2arr(lst_file)
	nodes = []

	File.open(lst_file,"r").each do |line|
	line.chomp!
	nodes.append(line)
	end

	return nodes
end

########################### OPTPARSE ########################
#############################################################

options = {}

OptionParser.new do |opts|

  options[:matrix] = nil
  opts.on("-m","-matrix MAT", "The matrix you want to subset") do |mat|
    options[:matrix] = mat
  end

  options[:node_list] = nil
  opts.on("-n","-node_list NODE", "The list of node in lst format") do |node_list|
    options[:node_list] = node_list
  end

  options[:subset_length] = nil
  opts.on("-l","-subset_length LENGTH", "The length of the subset") do |subset_length|
    options[:subset_length] = subset_length.to_i
  end

  options[:output_matrix_file] = "subset_matrix"
  opts.on("-o","-output_matrix TYPE", "The name of the matrix output") do |output_matrix_file|
  	options[:output_matrix_file] = output_matrix_file
  end
end.parse!


########################### MAIN ############################
#############################################################

original_matrix=Npy.load(options[:matrix])
original_nodes=lst2arr(options[:node_list])


subset_indexes=(0..options[:subset_length]-1)
subset_nodes=original_nodes[subset_indexes]
subset_matrix=original_matrix[subset_indexes,subset_indexes]

Npy.save(options[:output_matrix_file], subset_matrix)
File.open(options[:output_matrix_file] +'.lst', 'w'){|f| f.print subset_nodes.join("\n")}
