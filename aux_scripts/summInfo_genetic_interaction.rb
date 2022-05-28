#!/usr/bin/env ruby
require 'optparse'

def load_file(file)
	table = []
	File.open(file, "r").each do |line|
		line.chomp!
		table << line.split("\t")
	end
	return table
end

####################### OPTPARSE #################
##################################################
options = {}

OptionParser.new do |opts|

  options[:genetic_interaction_file] = nil
  opts.on("-f","--genetic_interaction_file FILE", "The root to the genetic_interaction file") do |genetic_interaction_file|
    options[:genetic_interaction_file] = genetic_interaction_file
  end

end.parse!

##################### MAIN #######################
##################################################

genetic_interaction_file = load_file(options[:genetic_interaction_file])
total_number_of_annotations = []
genetic_interaction_file.transpose.each do |col|
	col.shift
	number_of_annotations = col.select{|element| element != ""}.count
	total_number_of_annotations << number_of_annotations
end

total_number_of_annotations.each do |number_of_annotations|
	puts number_of_annotations
end


