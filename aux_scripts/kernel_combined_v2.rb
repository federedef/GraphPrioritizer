#! /usr/bin/env ruby
require 'optparse'
require 'npy'
require 'numo/narray'
require 'expcalc'
require 'benchmark'

class Kernels

	attr_accessor :kernels_raw, :kernels_in_genmatrix, :integrated_kernel

	def initialize()
		@kernels_raw = {}
		@kernels_in_genmatrix = {}
		@integrated_kernel = []
	end

	def load_kernels_by_bin_matrixes(input_matrix, input_nodes, kernels_names)

		kernels_names.map!{|id| id.to_sym}

		kernels_names.each.with_index do |kernel_name, pos|
			kernel = Npy.load(input_matrix[pos])
			node = lst2arr(input_nodes[pos])
			@kernels_raw[kernel_name] = [kernel, node]
	  end
	end

	def integrate(integration_type = "mean")
		if integration_type == "mean"
			integrate_mean()
		elsif integration_type == "integration_mean_by_presence"
			integrate_mean_by_presence()
		end
	end

	## AUXILIAR METHODS
	##############################
	private

	def integrate_mean
		general_nodes = []
		@kernels_raw.each_value do |kernel| 
			general_nodes += kernel[1]
		end
		general_nodes.uniq!
		general_kernel = Numo::DFloat.zeros(general_nodes.length,general_nodes.length)

		general_nodes.each.with_index do |inode, i| 
			general_nodes.each.with_index do |jnode, j|
				
				values = []
				@kernels_raw.each_value do |kernel| 
					pos_row = kernel[1].find_index(inode)
				  pos_col = kernel[1].find_index(jnode)
			   if !pos_row.nil? && !pos_col.nil?
			   	values << kernel[0][pos_row,pos_col]
			   else
			   	values << [0]
			   end
			  end

			 general_kernel[i,j] = values.mean
			end
		end

		@integrated_kernel = [general_kernel, general_nodes]
	end


	def integrate_mean_by_presence
		general_nodes = []
		@kernels_raw.each_value do |kernel| 
			general_nodes += kernel[1]
		end
		general_nodes.uniq!
		general_kernel = Numo::DFloat.zeros(general_nodes.length,general_nodes.length)

		general_nodes.each.with_index do |inode, i| 
			general_nodes.each.with_index do |jnode, j|
				
				values = []
				representation_number = 0
				@kernels_raw.each_value do |kernel| 
					pos_row = kernel[1].find_index(inode)
				  pos_col = kernel[1].find_index(jnode)
			   if !pos_row.nil? && !pos_col.nil?
			   	values << kernel[0][pos_row,pos_col]
			   	representation_number += 1
			   else
			   	values << [0]
			   end
			  end

			 general_kernel[i,j] = values.sum/representation_number.to_f
			end
		end

		@integrated_kernel = [general_kernel, general_nodes]
	end

	def lst2arr(lst_file)
		nodes = []

		File.open(lst_file,"r").each do |line|
		line.chomp!
		nodes.append(line)
		end

		return nodes
	end
	
end


########################### OPTPARSE ########################
#############################################################

options = {}

OptionParser.new do |opts|

  options[:kernel_files] = nil
  opts.on("-t","-input_kernels KER", "The roots from each kernel to integrate") do |ker|
    options[:kernel_files] = ker.split()
  end

  options[:node_files] = nil
  opts.on("-n","-input_nodes NODE", "The list of node for each kernel in lst format") do |node_files|
    options[:node_files] = node_files.split()
  end

  options[:kernel_ids] = nil
  opts.on("-I","-kernel_ids KERNELS", "The names of each kernel") do |ker_ids|
    options[:kernel_ids] = ker_ids.split(";")
  end

  options[:input_format] = "bin"
  opts.on("-f","-format_kernel FORMAT", "The format of the kernels to integrate") do |format_inp|
  	options[:input_format] = format_inp
  end

  options[:integration_type] = nil
  opts.on("-i","-integration_type TYPE", "It specifies how to integrate the kernels") do |integration_type|
  	options[:integration_type] = integration_type
  end

  options[:output_matrix_file] = "general_matrix"
  opts.on("-o","-output_matrix TYPE", "The name of the matrix output") do |output_matrix_file|
  	options[:output_matrix_file] = output_matrix_file
  end
end.parse!

########################### MAIN ############################
#############################################################
kernels = Kernels.new()

if options[:kernel_ids].nil?
	options[:kernel_ids] = (0..options[:kernel_files].length-1).to_a
	options[:kernel_ids].map!{|k| k.to_s}
end


#if options[:input_format] == "bin"
#	kernels.load_kernels_by_bin_matrixes(options[:kernel_files], options[:node_files], options[:kernel_ids])
#end
#
#
#if !options[:integration_type].nil?
#	kernels.integrate(options[:integration_type])
#end

#if !options[:output_matrix_file].nil?
#	Npy.save(options[:output_matrix_file], kernels.integrated_kernel[0])
#	File.open(options[:output_matrix_file] +'.lst', 'w'){|f| f.print kernels.integrated_kernel[1].join("\n")}
#end

Benchmark.bm do |x|
  x.report("load binary matrixes: ") { kernels.load_kernels_by_bin_matrixes(options[:kernel_files], options[:node_files], options[:kernel_ids]) }
  x.report("Final integration") { kernels.integrate(options[:integration_type]) }
  x.report("Save numpy matrix") {  Npy.save(options[:output_matrix_file], kernels.integrated_kernel[0]) }
  x.report("Write node list") { File.open(options[:output_matrix_file] +'.lst', 'w'){|f| f.print kernels.integrated_kernel[1].join("\n") }}
end

