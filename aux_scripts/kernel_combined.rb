#! /usr/bin/env ruby
require 'optparse'
require 'numo/narray'
require 'expcalc'
require 'benchmark'

class Kernels

	attr_accessor :kernels_raw, :integrated_kernel, :general_nodes

	def initialize()
		@kernels_raw = []
		@local_indexes = []
		@integrated_kernel = []
		@general_nodes = []
		@kernels_position_index = {}
	end

	def load_kernels_by_bin_matrixes(input_matrix, input_nodes, kernels_names)
		kernels_names.each.with_index do |kernel_name, pos|
			@kernels_raw << Numo::NArray.load(input_matrix[pos], type='npy')
			@local_indexes << build_matrix_index(lst2arr(input_nodes[pos]))
	  end
	end

	def create_general_index
		@general_nodes = []
		@local_indexes.each do |index| 
			@general_nodes += index.keys
		end
		@general_nodes.uniq!
		@general_nodes.each do |node|
			@kernels_position_index[node] = @local_indexes.map{|ind| ind[node]}
		end
		@local_indexes = []
	end

	def integrate
		general_nodes = @general_nodes.clone
		nodes_dimension = general_nodes.length
		#print nodes_dimension
		general_kernel = Numo::DFloat.zeros(nodes_dimension,nodes_dimension)
		n_kernel = @kernels_raw.length
		i = 0
		while general_nodes.length > 1
			node_A = general_nodes.pop
			ind = general_nodes.length - 1
			general_nodes.reverse_each do |node_B|
				#x = nodes_dimension - i
				#print x 
				j = ind
				values = get_values(node_A, node_B)
				if !values.empty?
					result = yield(values, n_kernel)
					reversed_i = nodes_dimension -1 - i
					general_kernel[reversed_i, j] = result
					general_kernel[j, reversed_i] = result
				end
				ind -= 1
			end
			i += 1
		end

		# general_nodes.each_with_index do |inode, i| 
		# 	general_nodes.each_with_index do |jnode, j|
		# 		values = get_values(inode, jnode, hash2nodes)
		# 	 	general_kernel[i,j] = yield(values, n_kernel)
		# 	end
		# end

		@integrated_kernel = [general_kernel, @general_nodes]
	end

	def get_values(node_A, node_B)
		rows = @kernels_position_index[node_A]
		cols = @kernels_position_index[node_B]
		values = []
		rows.each_with_index do |r_ind, i| #Load just the pairs in both sides of the kernel matrix
			if !r_ind.nil? 
				c_ind = cols[i]
				if !c_ind.nil?
					values << @kernels_raw[i][r_ind, c_ind]
			  end
		  end
		end
		return values
	end

	def integrate_matrix(method)
		integrate do |values, n_kernel|
       if method == "mean" 
			 	values.sum.fdiv(n_kernel)
       elsif method == "integration_mean_by_presence"
       	values.mean
       end
		end
	end

	## AUXILIAR METHODS
	##############################
	private

	def lst2arr(lst_file)
		nodes = []
		File.open(lst_file,"r").each do |line|
			nodes << line.chomp
		end
		return nodes
	end

	def build_matrix_index(node_list)
			hash_nodes = {}
			node_list.each_with_index do |node, i|
				hash_nodes[node] = i
			end
			return hash_nodes
	end
	
end


########################### OPTPARSE ########################
#############################################################

options = {}

OptionParser.new do |opts|

  options[:kernel_files] = nil
  opts.on("-t","--input_kernels STRING", "The roots from each kernel to integrate") do |ker|
    options[:kernel_files] = ker.split()
  end

  options[:node_files] = nil
  opts.on("-n","--input_nodes NODE", "The list of node for each kernel in lst format") do |node_files|
    options[:node_files] = node_files.split()
  end

  options[:kernel_ids] = nil
  opts.on("-I","--kernel_ids KERNELS", "The names of each kernel") do |ker_ids|
    options[:kernel_ids] = ker_ids.split(";")
  end

  options[:input_format] = "bin"
  opts.on("-f","--format_kernel FORMAT", "The format of the kernels to integrate") do |format_inp|
  	options[:input_format] = format_inp
  end

  options[:integration_type] = nil
  opts.on("-i","--integration_type TYPE", "It specifies how to integrate the kernels") do |integration_type|
  	options[:integration_type] = integration_type
  end

  options[:output_matrix_file] = "general_matrix"
  opts.on("-o","--output_matrix TYPE", "The name of the matrix output") do |output_matrix_file|
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
options[:kernel_ids].map!{|id| id.to_sym}

#if options[:input_format] == "bin"
#	kernels.load_kernels_by_bin_matrixes(options[:kernel_files], options[:node_files], options[:kernel_ids])
#	kernels.create_general_index
#end
#
#
#if !options[:integration_type].nil?
#	kernels.integrate_matrix(options[:integration_type])
#end
#
#if !options[:output_matrix_file].nil?
#	kernel, names = kernels.integrated_kernel
#	kernel.save(
#		options[:output_matrix_file], 
#		x_axis_names = names, 
#		x_axis_file = options[:output_matrix_file] +'.lst')
#end

Benchmark.bm do |x|
  x.report("load binary matrixes: ") { 
  	kernels.load_kernels_by_bin_matrixes(options[:kernel_files], options[:node_files], options[:kernel_ids]) 
  	kernels.create_general_index
  }
  x.report("Final integration") { kernels.integrate_matrix(options[:integration_type]) }
  x.report("Save numpy matrix") {  
  kernel, names = kernels.integrated_kernel
	kernel.save(
		options[:output_matrix_file], 
		x_axis_names = names, 
		x_axis_file = options[:output_matrix_file] +'.lst')
  }
end

