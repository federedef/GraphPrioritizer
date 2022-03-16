#!/usr/bin/env ruby

require 'numo/narray'
require 'npy'
require 'optparse'

####################################################################

options = {}

OptionParser.new do |opts|

  options[:dims] = [1000,1000,1000,1000]
  opts.on("-d","-kernel_dimensions KER", "Specify each kernel dimension") do |ker|
    options[:dims] = ker.split(",").map!{|v| v.to_i}
  end

  options[:names] = ["m1","m2","m3","m4"]
  opts.on("-n","-kernel_names NAMES", "The names of each kernel") do |names|
  	options[:names] = names.split(",")
  end

end.parse!

####################################################################

dimensions=options[:dims]
names=options[:names]

dimensions.each.with_index do |dim, i| 
	kernel=Numo::DFloat.new(dim,dim).rand
	node_list=(1..dim).to_a.shuffle
	name=names[i]
	
	Npy.save(name, kernel)
	File.open(name + '.lst', 'w'){|f| f.print node_list.join("\n")}
end

