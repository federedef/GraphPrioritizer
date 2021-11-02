require 'optparse'
require 'npy'

########################### FUNCTIONS #######################
#############################################################

def generate_kernel_node_list(kernel_files, node_files)
	kernels_nodes = kernel_files.zip(node_files)

	kernels_nodes.map! do |kernel_node|
		kernel = Npy.load(kernel_node[0])
		node = lst2arr(kernel_node[1])
		[kernel, node]
	end
	
	return kernels_nodes
end

def kernels2generalMatrix(kernels_with_nodes)
	general_nodes = []
	kernels_with_nodes.each do |kernel_node| 
		general_nodes += kernel_node[1]
	end
	general_nodes.uniq!

	general_kernels = []
	kernels_with_nodes.each do |kernel_node|
		general_kernel = Numo::DFloat.zeros(general_nodes.length,general_nodes.length)

		kernel_node[1].each.with_index do |row_node, i|
			kernel_node[1].each.with_index do |column_node, j|
				pos_row = general_nodes.find_index(row_node)
				pos_col = general_nodes.find_index(column_node)
				general_kernel[pos_row,pos_col] = kernel_node[0][i,j]
			end
		end

		general_kernels.append(general_kernel)
	end

	return [general_kernels, general_nodes]
end

def minmax_normalization(kernel)
	minmax_gen_mat = Numo::DFloat.zeros(kernel.shape[0],kernel.shape[1])
	

end

def integrate_mean(matrixes)
	gen_mat = matrixes.sum() * (1/matrixes.length.to_f)
	return gen_mat
end


########################### AUXILIAR FUNCTIONS ##############
#############################################################

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
	kernels_in_genmatrix = kernels2generalMatrix(kernels_nodes)

	if options[:normalization] == "min_max"
		kernels_in_genmatrix = minmax_normalization(kernels_in_genmatrix)
	end



	if options[:integration_type] == "mean"
		general_kernel_combine = integrate_mean(kernels_in_genmatrix)
		Npy.save(options[:output_matrix_file], general_kernel_combine)
		File.open(options[:output_matrix_file]+'.lst', 'w'){|f| f.print kernels_in_genmatrix[1].join("\n")}
  elsif options[:integration_type] == "ponder_mean"
		
else
	raise("ERROR: The format is not defined")
end
