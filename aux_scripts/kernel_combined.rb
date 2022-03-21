#! /usr/bin/env ruby
require 'optparse'
require 'npy'
require 'numo/narray'
require 'expcalc'
require 'benchmark'

class Kernels

	attr_accessor :kernels_raw, :integrated_kernel, :general_nodes

	def initialize()
		@kernels_raw = {} #[]
		@local_indexes = []
		@integrated_kernel = []
		@general_nodes = []
	end

	def load_kernels_by_bin_matrixes(input_matrix, input_nodes, kernels_names)

		kernels_names.map!{|id| id.to_sym}

		kernels_names.each.with_index do |kernel_name, pos|
			kernel = Npy.load(input_matrix[pos])
			node = lst2arr(input_nodes[pos])
			@kernels_raw[kernel_name] = [kernel, node]
	  end
	end

	def create_general_index
		@general_nodes = []
		@kernels_raw.each_value do |kernel| 
			@general_nodes += kernel[1]
		end
		@general_nodes.uniq!
	end

	def integrate
		general_nodes = @general_nodes.clone
    hash2nodes={}     
		@kernels_raw.each do |id, kernel|
			build_matrix_index(hash2nodes, kernel[1], id)
		end
		general_kernel = Numo::DFloat.zeros(general_nodes.length,general_nodes.length)
		n_kernel = @kernels_raw.keys.length
		i = 0
		while general_nodes.length > 1
			node_A = general_nodes.pop
			general_nodes.each_with_index do |node_B, ind|
				j = i + 1 + ind
				values = get_values(node_A, node_B, hash2nodes)
				if !values.empty?
				result = yield(values, n_kernel)
				general_kernel[i,j] = result
				general_kernel[j,i] = result
				end
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

	def get_values(node_A, node_B, hash2nodes)
		rows=hash2nodes[node_A]
		# rows = @local_indexes.map{|idx| idx[node_A]}
		cols=hash2nodes[node_B]
		rows_cols={}
		#Load just the pairs in both sides of the kernel matrix.
		rows.each_key do |mat_id|
			if !cols[mat_id].nil?
			  rows_cols[mat_id] = [rows[mat_id],cols[mat_id]]
		  end
		end
		values=[]
		rows_cols.each do |mat_id, row_col|
			values << @kernels_raw[mat_id][0][row_col[0],row_col[1]]
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
		line.chomp!
		nodes.append(line)
		end

		return nodes
	end

	def build_matrix_index(hash_nodes, node_list, id)
		node_list.each_with_index do |node, i|
			query=hash_nodes[node]
			if query.nil?
				hash_nodes[node]={id => i}
			else
				query[id] = i
			end
		end
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


if options[:input_format] == "bin"
	kernels.load_kernels_by_bin_matrixes(options[:kernel_files], options[:node_files], options[:kernel_ids])
	kernels.create_general_index
end


if !options[:integration_type].nil?
	kernels.integrate_matrix(options[:integration_type])
end

if !options[:output_matrix_file].nil?
	Npy.save(options[:output_matrix_file], kernels.integrated_kernel[0])
	File.open(options[:output_matrix_file] +'.lst', 'w'){|f| f.print kernels.integrated_kernel[1].join("\n")}
end

#Benchmark.bm do |x|
#  x.report("load binary matrixes: ") { 
#  	kernels.load_kernels_by_bin_matrixes(options[:kernel_files], options[:node_files], options[:kernel_ids]) 
#  	kernels.create_general_index
#  	print kernels.general_nodes
#  }
#  x.report("Final integration") { kernels.integrate_matrix(options[:integration_type]) }
#  x.report("Save numpy matrix") {  Npy.save(options[:output_matrix_file], kernels.integrated_kernel[0]) }
#  x.report("Write node list") { File.open(options[:output_matrix_file] +'.lst', 'w'){|f| f.print kernels.integrated_kernel[1].join("\n") }}
#end

