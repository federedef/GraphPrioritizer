#! /usr/bin/env ruby
require 'optparse'
require 'npy'
require 'numo/narray'
require 'expcalc'
require 'benchmark'

class Kernels

	attr_accessor :kernels_raw, :integrated_kernel

	def initialize()
		@kernels_raw = {}
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

	def integrate(type="mean")
		general_nodes = []
		@kernels_raw.each_value do |kernel| 
			general_nodes += kernel[1]
		end
		general_nodes.uniq!


    # Save the position informatin in hash to go faster.
    hash2nodes={}
      
		@kernels_raw.each do |id, kernel|
			nodes_into_hash(hash2nodes, kernel[1], id)
		end

		general_kernel = Numo::DFloat.zeros(general_nodes.length,general_nodes.length)

		general_nodes.each_with_index do |inode, i| 
			general_nodes.each_with_index do |jnode, j|
				rows=hash2nodes[inode]
				cols=hash2nodes[jnode]
				rows_cols={}
				#Load just the pairs in both sides of the kernel matrix.
				rows.each_key do |id|
					if !cols[id].nil?
					  rows_cols[id] = [rows[id],cols[id]]
				  end
				end

				values=[]
				rows_cols.each do |id, row_col|
					values << @kernels_raw[id][0][row_col[0],row_col[1]]
				end

       if type == "mean" 
			 	general_kernel[i,j] = values.sum/@kernels_raw.keys.length.to_f
       elsif type == "integration_mean_by_presence"
       	general_kernel[i,j] = values.sum/@kernels_raw.keys.length.to_f
       end
			end
		end

		@integrated_kernel = [general_kernel, general_nodes]
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

	def nodes_into_hash(hash_nodes, node_list, id)
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

