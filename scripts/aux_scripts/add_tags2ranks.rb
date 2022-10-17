#!/usr/bin/env ruby
require 'optparse'

########################### FUNCTIONS #######################
#############################################################

def write_file(output_name, data)
  File.open(output_name ,'w') do |f|
    data.each do |row|
      f.puts row.join("\t")
    end
  end
end

def add_tags(file2tag, tags, group_column=0, cases_column=1)
  tagged_file=[]
  file2tag.map do |row|
    group = row[group_column]
    case_for_group = row[cases_column]
    if !tags[group].nil?
      row << tags[group][case_for_group] if !tags[group][case_for_group].nil?
      tagged_file << row
    end
  end
  return tagged_file
end

def load_file(file)
   parsed_file = []
   File.open(file).each do |line|
     fields = line.chomp.split("\t")
     parsed_file << fields
   end
   return parsed_file
 end

 def tagfile2hash(file)
  tags = {}
  file.each do |row|
    group = row[0]
    case_for_group = row[1]
    tag = row[2]
    tags[group] = {} if tags[group].nil?
    tags[group][case_for_group] = tag.to_i
  end
  return tags
end


########################### OPTPARSE ########################
#############################################################

options = {}
OptionParser.new do  |opts|

  options[:input_file] = nil
  opts.on("-i","-input_file FILE", "The root to the file to add the tags") do |item|
    options[:input_file] = item
  end

  options[:group_column] = 0
  opts.on("-g","-group_column COL", "The index to column of groups") do |item|
    options[:group_column] = item.to_i 
  end

  options[:cases_column] = 1
  opts.on("-c","-case_column CASE", "The index to the column of cases") do |item|
    options[:cases_column]=item.to_i
  end

  options[:tag_file] = nil
  opts.on("-t","-tag_file FILE","The root to the file to add the tags") do |item|
    options[:tag_file] = item
  end

  options[:output_name] = "added_tags"
  opts.on("-o","-output_name NAME", "The name of the ranked file") do |output_name|
    options[:output_name] = output_name
  end

end.parse!

########################### MAIN ############################
#############################################################

file2tag = load_file(options[:input_file])
tags_file = load_file(options[:tag_file])
tags = tagfile2hash(tags_file)
file_with_tags = add_tags(file2tag, tags, options[:group_column], options[:cases_column])
write_file(options[:output_name],file_with_tags) if !file_with_tags.nil?
