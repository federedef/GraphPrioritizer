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


def filter_by_whitelist(table, terms2filter, column2filter, by_row=false)
	filtered_table = []
	filtered_table = table.select{|row| terms2filter.include?(row[column2filter])} if by_row == false
	filtered_table = table.transpose.select{|row| terms2filter.include?(row[column2filter])}.transpose if by_row == true
	return filtered_table
end

####################### OPTPARSE #################
##################################################
options = {}

OptionParser.new do |opts|

  options[:files2befiltered] = nil
  opts.on("-f","--files2befiltered FILES", "The root to the files that has to be filtered") do |paths|
    options[:files2befiltered] = paths.split(",")
  end

  options[:columns2befiltered] = nil
  opts.on("-c","--columns2befiltered COLS", "The columns that need to be filtered for each file") do |columns_by_file|
    options[:columns2befiltered] = columns_by_file.split(";").map{|cols| cols.split(",").map{|col| col.to_i}}
  end

  options[:by_row] = false 
  opts.on("-r","--transpose", "If you want to select by rows") do
  	options[:by_row] = true
  end

  options[:terms2befiltered] = nil
  opts.on("-t","--terms2befiltered TERMS", "The PATH to the list of terms to be filtered") do |terms_file|
    options[:terms2befiltered] = terms_file
  end

  options[:output_path] = "."
  opts.on("-o","--output_path OUTPATH", "The name of the output path") do |output_path|
  	options[:output_path] = output_path
  end

end.parse!

##################### MAIN #######################
##################################################

files2befiltered = options[:files2befiltered]
columns2befiltered = options[:columns2befiltered]
files_columns2befiltered = files2befiltered.zip(columns2befiltered)

#puts options[:terms2befiltered]
terms2befiltered = load_file(options[:terms2befiltered]).map{|term| term[0]}
output_path = options[:output_path]

file_filteredfile = {}

files_columns2befiltered.each do |file_columns|
	print file_columns
	file = file_columns[0]
	columns = file_columns[1]
	table = load_file(file)
	columns.each do |column|
		table = filter_by_whitelist(table, terms2befiltered, column, by_row=options[:by_row])
	end

	file_filteredfile[file] = table
end


file_filteredfile.each do |file_path, filtered_table|
	file_name = File.basename(file_path)
	File.open(File.join(output_path,"filtered_" + file_name), "w") do |f|
		filtered_table.each do |line|
			f.puts line.join("\t")
		end
	end
end