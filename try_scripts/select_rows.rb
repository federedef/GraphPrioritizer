#! /usr/bin/env ruby
require 'optparse'
require 'npy'
require 'numo/narray'

def read_table(table)
	fastas = {}
	id = ""
	File.open(table,"r").each.with_index do |line, row|
		line.chomp!

		if line =~ /^>/
		  id = line[1..-1]
		  fastas[id] = ""
		else
		  fastas[id] = fastas[id] + line
	    end
	end
	return fastas
end
########################### OPTPARSE ########################
#############################################################

options = {}

OptionParser.new do |opts|

  options[:tables] = nil
  opts.on("-t","-tables_data TBL", "The roots for each of the tables") do |tbl|
    options[:table] = tbl.split(";")
  end

  options[:select_factors] = nil
  opts.on("-s","-select_factors SELFAC", "An array with every pattern we want to select") do |select_factors|
    options[:select_factors] = select_factors.split(";")
  end

  options[:output_path] = nil
  opts.on("-o","-output_path OUTPATH", "The name of the output path") do |output_path|
  	options[:output_path] = output_path
  end

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

#kernels.normalize("max_by_column")

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
