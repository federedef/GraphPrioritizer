#! /usr/bin/env ruby
require 'optparse'

########################### FUNCTIONS #######################
#############################################################

def write_negatives(file, negatives)
  File.open(file ,'w') do |f|
    negatives.each do |group, nodes|
      f.puts "#{group}" + "\t" + nodes.join(",")
    end
  end
end

def get_negatives2groups(disgroup_genes)
  all_genes = disgroup_genes.values.flatten.uniq
  negatives = {}
  disgroup_genes.each_key do |k|
    negatives[k] =  all_genes - disgroup_genes[k].uniq
  end
  return negatives
end

def get_negatives2disease(diseases_disgroup,disgroup_negatives)
  negatives = {}
  diseases_disgroup.each do |disease, disgroup|
    negatives[disease] = disgroup_negatives[disgroup]
  end
  return negatives
end


def load_node_groups_from_file(file, sep: ',')
   diseases = {}
   disgroup_genes = {}
   File.open(file).each do |line|
     disease_name, disgroup, genes = line.chomp.split("\t")
     diseases[disease_name] = disgroup
     if disgroup_genes[disgroup].nil?
       disgroup_genes[disgroup] = genes.split(sep)
     else
       disgroup_genes[disgroup] += genes.split(sep)
     end
   end

   return diseases, disgroup_genes
 end


########################### OPTPARSE ########################
#############################################################

options = {}
OptionParser.new do  |opts|

  options[:positive_file] = nil
  opts.on("-i","-input_positives POS", "The roots for the positive file") do |item|
    options[:positive_file] = item
  end

  options[:output_name] = "negatives"
  opts.on("-o","-output_name NAME", "The name of the ranked file") do |output_name|
    options[:output_name] = output_name
  end

end.parse!

########################### MAIN ############################
#############################################################

diseases_disgroup, disgroup_genes = load_node_groups_from_file(options[:positive_file])
disgroup_negatives = get_negatives2groups(disgroup_genes)
diseases_negatives = get_negatives2disease(diseases_disgroup,disgroup_negatives)
write_negatives(options[:output_name],diseases_negatives) if !diseases_negatives.nil?

