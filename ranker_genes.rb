require 'optparse'
require 'npy'
require 'numo/narray'

########################### FUNCTIONS #######################
#############################################################

def rank_by_seedgen(kernel_matrix, kernels_nodes, seed_gen)
	gen_pos = kernels_nodes.find_index(seed_gen)
	gen_list = kernel_matrix[gen_pos,true]
  ordered_indexes = gen_list.sort_index.to_a.reverse
  ordered_gene_score = []
  ordered_indexes.each{|order_index| ordered_gene_score.append([kernels_nodes[order_index], gen_list[order_index]])}
  return ordered_gene_score
end

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

OptionParser.new do  |opts|

  options[:kernel_file] = nil
  opts.on("-k","-input_kernels KER", "The roots from each kernel to integrate") do |ker|
    options[:kernel_file] = ker
  end

  options[:node_file] = nil
  opts.on("-n","-input_nodes NODE", "The list of node for each kernel in lst format") do |node_file|
    options[:node_file] = node_file
  end

  options[:genes_seed] = nil
  opts.on("-s","-genes_seed SEED", "The list of genes to look for backups") do |genes_seed|
    options[:genes_seed] = genes_seed
  end

  options[:output_filename] = "general_matrix"
  opts.on("-o","-output_matrix TYPE", "The name of the output file") do |output_filename|
  	options[:output_filename] = output_filename
  end
end.parse!

########################### MAIN ############################
#############################################################
matrix = Npy.load(options[:kernel_file])
kernel_nodes = lst2arr(options[:node_file])
genes_seed = lst2arr(options[:genes_seed])

genes_seed.each do |gene_seed|
  ranked_genes = rank_by_seedgen(matrix, kernel_nodes, gene_seed)
  #p ranked_genes
  #puts '%s' %gene_seed
  File.open('%s' %gene_seed,'w') do |f|
    ranked_genes.each{|ranked_gene| f.print "%s\t%s\n" %ranked_gene}
  end
end







