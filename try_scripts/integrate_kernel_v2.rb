require 'optparse'
require 'npy'

class Kern

	attr_accessor :matrix, :nodes 

	def initialize(matrix, nodes)
		@matrix = Numo::DFloat.zeros(1,1)
		@nodes = []
	end

	def load_kernel_by_bin_matrix(input_matrix,input_nodes)
		@nodes = lst2arr(input_nodes)
		@matrix = Npy.load(input_matrix)
	end


	def minmax_normalize
		normalize_matrix = (1.to_f/(matrix.max-matrix.min)) * matrix 
		@matrix = normalize_matrix
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

end

def generate_kernel_node_list(kernel_files, node_files)
	kernels_nodes = kernel_files.zip(node_files)
	kernels = []

	kernels_nodes.each do |kernel_node|
		kern = Kern.new
		kern.load_kernel_by_bin_matrix(kernel_node[0],kernel_node[1])
		kernels.append(kern)
	end
	
	return kernels
end

def kernels2generalMatrix(kernels)
	general_nodes = []
	kernels.each.nodes do |node| 
		general_nodes += node
	end
	general_nodes.uniq!

	general_kernels = []
	kernels.each do |kernel|
		general_kernel = Numo::DFloat.zeros(general_nodes.length,general_nodes.length)

		kernel.nodes.each.with_index do |row_node, i|
			kernel.nodes.each.with_index do |column_node, j|
				pos_row = general_nodes.find_index(row_node)
				pos_col = general_nodes.find_index(column_node)
				general_kernel[pos_row,pos_col] = kernel.matrix[i,j]
			end
		end

		general_kernels.append(Kern.new(general_kernel, general_nodes))
	end

	return general_kernels
end

def integrate_mean(kernels)
	matrixes = kernels.map{|kern| kern.matrix}
	gen_mat = matrixes.sum() * (1/matrixes.length.to_f)
	gen_nodes = kernels.first.nodes
	gen_kern = Kern.new(gen_mat, gen_nodes)
	return gen_kern
end



########################### OPTPARSE ########################
#############################################################

options = {}

OptionParser.new do |opts|

  options[:kernel_files] = "jjj"
  opts.on("-k","-input_kernels KER", "The roots from each kernel to integrate") do |ker|
    options[:kernel_files] = ker.split()
  end

  options[:node_files] = nil
  opts.on("-n","-input_nodes NODE", "The list of node for each kernel in lst format") do |node_files|
    options[:node_files] = node_files.split()
  end

  options[:input_format] = "bin"
  opts.on("-f","-format_kernel FORMAT", "The format of the kernels to integrate") do |format_inp|
  	options[:input_format] = format_inp
  end

  options[:integration_type] = "mean"
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


if options[:input_format] == "bin"
	kernels_nodes = generate_kernel_node_list(options[:kernel_files],options[:node_files])

	if options[:normalization] == "min_max"
		kernels_nodes.each{|kern| kern.minmax_normalize}
	end

	genmatrix_kernels = kernels2generalMatrix(kernels_nodes)
	genmatrix_integrated = []

    
	if options[:integration_type] == "mean"
		genmatrix_integrated = integrate_mean(genmatrix_kernels)
		Npy.save(options[:output_matrix_file], genmatrix_integrated.matrix)
		File.open(options[:output_matrix_file]+'.lst', 'w'){|f| f.print genmatrix_integrated.nodes.join("\n")}
  elsif options[:integration_type] == "ponder_mean"
		
else
	raise("ERROR: The format is not defined")
end


