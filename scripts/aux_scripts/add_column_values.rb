#!/usr/bin/env ruby
require 'optparse'

def extract_data(file)
    data = []

    File.open(file,"r").each do |line|
    line.chomp!
    data.append(line.split("\t"))
    end

    return data
end

def create_hash(table, keys_index, val_index)
	# Here we create our hash.
	columns2add_values={}
	table.each do |line|
		key = keys_index.map{|i| line[i]}
		columns2add_values[key] = line[val_index]
	end
	return columns2add_values
end

def add_column(table, columnids2values, keys_index, add_index)
	# Here we merge the two tables in one.
	new_table=[]
	table.each do |line|
		key = keys_index.map{|i| line[i]}
		new_val = columnids2values[key]
		new_table.append(line.insert(add_index,new_val))
	end
	return new_table
end


########################### OPTPARSE ########################
#############################################################

options = {}
OptionParser.new do  |opts|

  options[:reference_table] = nil
  opts.on("-r","-reference_table REFTAB", "The path to the table used as reference") do |reference_table|
    options[:reference_table] = reference_table
  end

  options[:key_columns] = [0,1]
  opts.on("-k","-key_columns KEY", "The index to each column that will be the keys") do |keys|
    options[:key_columns] = keys.split(",").map{|s| s.to_i}
  end

  options[:value_column] = 2
  opts.on("-v","-value_column VAL", "The index of the value column") do |value_col|
    options[:value_column] = value_col.to_i
  end

  options[:input_table2modify] = nil
  opts.on("-i","-input_table2modify INTAB", "The path to the table that will be modified") do |input_table2modify|
    options[:input_table2modify] = input_table2modify
  end

  options[:query_columns] = [0,1]
  opts.on("-q","-query_columns QUERY", "The column indexes to use as query") do |query_columns|
    options[:query_columns] = query_columns.split(",").map{|s| s.to_i}
  end

  options[:add_index_column] = 2
  opts.on("-a","-add_index_column ADCOL", "The name of the column to be added") do |add_column|
    options[:add_index_column] = add_column.to_i
  end

end.parse!

########################### MAIN ##########################
###########################################################

reference_table = extract_data(options[:reference_table])
table2modify = extract_data(options[:input_table2modify])

columnids2values = create_hash(reference_table, options[:key_columns], options[:value_column])
modified_table = add_column(table2modify, columnids2values, options[:query_columns], options[:add_index_column])

modified_table.each do |line|
  puts line.join("\t")
end

