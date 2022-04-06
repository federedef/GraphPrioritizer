#!/usr/bin/env ruby
require 'optparse'

def create_translator(translator_file)
	translator={}
	File.open(translator_file, "r").each do |line|
		line.chomp!
		ids=line.split("\t")
		translator[ids[0]] = ids[1]
	end
	return translator
end

def load_file(file, separator)
	lines=[]
	File.open(file, "r").each do |line|
		line.chomp!
		fields=line.split(separator)
		lines.append(fields)
	end
	return lines
end

def subset_by_translator(array2translate,translator,columns2translate)
	translated_array=[]
	array2translate.each do |row|
		valid_row = true
		columns2translate.each do |col|
			 translated_value = translator[row[col]]
			 if !translated_value.nil?
         row[col]= translator[row[col]]
       else
       	 valid_row = false
       end
		end
	  translated_array.append(row) if valid_row
	end
	return translated_array
end


########################### OPTPARSE ########################
#############################################################

options = {}

OptionParser.new do |opts|

  options[:translator_file] = nil
  opts.on("-t","-translator_file TRANS", "The file with the translation: column 1 id_initial; column2 id_final") do |translator_file|
    options[:translator_file] = translator_file
  end

  options[:file2translate] = nil
  opts.on("-f","-file2translate NODE", "The file with the data to be translated") do |file2translate|
    options[:file2translate] = file2translate
  end

  options[:columns2translate] = nil
  opts.on("-c","-columns2translate COLS", "The number of each column to be translated, starting with 0") do |columns2translate|
    options[:columns2translate] = columns2translate.split(",").map!{|v| v.to_i}
  end

  options[:separator_file2translate] = " "
  opts.on("-s","-separator_file2translate SEP", "The type of separator in the file") do |separator_file2translate|
    options[:separator_file2translate] = separator_file2translate
  end

end.parse!

######################### MAIN ##############################
#############################################################

translator=create_translator(options[:translator_file]) if !options[:translator_file].nil?
data2translate=load_file(options[:file2translate], options[:separator_file2translate]) if !options[:file2translate].nil?
if !options[:columns2translate].nil?
	translated_data=subset_by_translator(data2translate,translator,options[:columns2translate]) if !options[:columns2translate].nil?
	translated_data.each do |line|
		puts line.join("\t")
	end
end

