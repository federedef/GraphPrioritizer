#! /usr/bin/env ruby
require 'optparse'
require 'npy'
require 'numo/narray'

########################### FUNCTIONS #######################
#############################################################

def write_negatives(file, negatives)
  File.open(file ,'w') do |f|
    negatives.each do |group, nodes|
      f.puts "#{group}" + "\t" + nodes.join(",")
    end
  end
end

def get_negatives(positives)
  all_nodes = positives.values.flatten.uniq
  negatives = {}
  positives.each_key do |k|
    negatives[k] =  all_nodes - positives[k]
  end
  return negatives
end


def load_node_groups_from_file(file, sep: ',')
   group_nodes = {}
   File.open(file).each do |line|
     set_name, nodes = line.chomp.split("\t")
     group_nodes[set_name] = nodes.split(sep)
   end
   return group_nodes
 end


########################### OPTPARSE ########################
#############################################################

options = {}
OptionParser.new do  |opts|

  options[:positive_file] = nil
  opts.on("-p","-input_positives POS", "The roots for the positive file") do |item|
    options[:positive_file] = item
  end

  options[:output_name] = "negatives"
  opts.on("-o","-output_name NAME", "The name of the ranked file") do |output_name|
    options[:output_name] = output_name
  end

end.parse!

########################### MAIN ############################
#############################################################

positives = load_node_groups_from_file(options[:positive_file])
negatives = get_negatives(positives)
write_negatives(options[:output_name],negatives) if !negatives.nil?

