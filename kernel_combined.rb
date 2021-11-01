require 'optparse'
require 'npy'
require 'numo/narray'

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
			@kernels_raw[kernel_name.to_sym] = [kernel, node]
	  end
	end

	def minmax_normalize
		@kernels_raw.each do |kern, value|
			matrix = value[0]
			diag_max = (1/matrix.max(1)).diag
			normalize_matrix = diag_max.dot(matrix)
			@kernels_raw[kern][0] = normalize_matrix 
		end
	end

	#def minmax_normalize(kernel)
	#	matrix = kernel
	#	diag_max = (1/matrix.max(1)).diag
	#	normalize_matrix = diag_max.dot(matrix)
	#  return normalize_matrix
	#end

	def kernels2generalMatrix

		general_nodes = []
		@kernels_raw.each_value do |kernel| 
			general_nodes += kernel[1]
		end
		general_nodes.uniq!

		@kernels_raw.each do |kernel, value|
			general_kernel = Numo::DFloat.zeros(general_nodes.length,general_nodes.length)

			value[1].each.with_index do |row_node, i|
				value[1].each.with_index do |column_node, j|
					pos_row = general_nodes.find_index(row_node)
					pos_col = general_nodes.find_index(column_node)
					general_kernel[pos_row,pos_col] = value[0][i,j]
				end
			end

			@kernels_in_genmatrix[kernel] = [general_kernel, general_nodes]
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
		matrixes = []

		@kernels_in_genmatrix.each do |key, kernel|
			matrixes.append(kernel[0])
			general_nodes = kernel[1] if general_nodes.empty?
		end

		matrix = matrixes.sum()
		integrated_gen_mat = (1/matrixes.length.to_f) * matrix
		

		@integrated_kernel = [integrated_gen_mat, general_nodes]
	end

	def integrate_mean_by_presence
		general_nodes = []
		matrixes = []

		@kernels_in_genmatrix.each do |key, kernel|
			matrixes.append(kernel[0])
			general_nodes = kernel[1] if general_nodes.empty?
		end

		integrated_general_matrix = Numo::DFloat.zeros(general_nodes.length,general_nodes.length)
		kernel_values = []
		(0..general_nodes.length-1).each do |i|
			(0..general_nodes.length-1).each do |j|
				matrixes.each do |matrix|
					kernel_values.append(matrix[i,j])
				end
				number_present_in_kernel = kernel_values.length - kernel_values.count(0)
				integrated_general_matrix[i,j] = kernel_values.sum()/number_present_in_kernel
				kernel_values=[]
			end
		end

		@integrated_kernel = [integrated_general_matrix, general_nodes]
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

  #options[:normalization] = "min_max"
  #opts.on("-z","-norma_type NORMA", "The type of normalization") do |norma_type|
  #	options[:normalization] = norma_type
  #end

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
end


kernels.minmax_normalize

kernels.kernels2generalMatrix

if !options[:integration_type].nil?
	kernels.kernels2generalMatrix
	kernels.integrate(options[:integration_type])
end

if !options[:output_matrix_file].nil?
	Npy.save("prueba", kernels.kernels_in_genmatrix[options[:kernel_ids][1]][0])
	Npy.save(options[:output_matrix_file], kernels.integrated_kernel[0] )
	File.open(options[:output_matrix_file] +'.lst', 'w'){|f| f.print kernels.integrated_kernel[1].join("\n")}
end