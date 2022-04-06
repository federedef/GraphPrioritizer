#! /usr/bin/env ruby
require 'optparse'
require 'npy'
require 'numo/narray'

########################### FUNCTIONS #######################
#############################################################

def rank_by_seedgen(kernel_matrix, kernels_nodes, seed_gens)
  #gen_pos = seed_gens.map{|gen| kernels_nodes.find_index(gen)}
  gens_pos = []
  seed_gens.each do |gene|
    index_gene = kernels_nodes.find_index(gene)
    gens_pos.append(index_gene) if !index_gene.nil?
  end

  number_of_seed_gens = gens_pos.length
  if number_of_seed_gens > 0
    subsets_gen_values = []
    gens_pos.each do |gen_pos|
      subsets_gen_values.append(kernel_matrix[gen_pos,true])
    end

    gen_list = 1.fdiv(number_of_seed_gens) * subsets_gen_values.sum
    percentiles = (1..gen_list.length).to_a
    percentiles.map!{|percentile| percentile/percentiles.length.to_f}

    ordered_indexes = gen_list.sort_index.to_a.reverse
    ordered_gene_score = []
    ordered_indexes.each.with_index{|order_index, pos| ordered_gene_score.append([kernels_nodes[order_index], gen_list[order_index], percentiles[pos], pos])}

    return ordered_gene_score
  end
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
  opts.on("-s","-genes_seed SEED", "The name of the gene to look for backups") do |genes_seed|
    options[:genes_seed] = genes_seed.split(",")
  end

  options[:output_name] = "ranked_genes"
  opts.on("-o","-output_name NAME", "The name of the ranked file") do |output_name|
    options[:output_name] = output_name
  end

end.parse!

########################### MAIN ############################
#############################################################

matrix = Npy.load(options[:kernel_file])
kernel_nodes = lst2arr(options[:node_file])
genes_seed = options[:genes_seed]
output_name = options[:output_name]

ranked_genes = rank_by_seedgen(matrix, kernel_nodes, genes_seed)
if !ranked_genes.nil?
  File.open('%s_all_candidates' %output_name,'w') do |f|
    ranked_genes.each{|ranked_gene| f.print "%s\t%f\t%f\t%d\n" %ranked_gene}
  end
else 
  File.open('%s_non_candidates' %output_name,'w') do |f|
    f.print "No present this genes in the matrix"
  end
end







