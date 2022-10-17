#! /usr/bin/env ruby
require 'optparse'
require 'expcalc'

########################### FUNCTIONS #######################
#############################################################

def open_rank_file(rank_file)
	known_ranks = []
	File.open(rank_file,"r").each do |line|
		line.chomp!
		line = line.split("\t")
		group_name = line.last
		candidate_gene = line[0]
		percentage_score = line[2]
		known_ranks.append([candidate_gene, percentage_score, group_name])
	end
	return known_ranks
end

def report_stats(data)
  report_stats = []
  report_stats << ['Elements', data.size]
  report_stats << ['Max', data.max.round(3)]
  report_stats << ['Min', data.min.round(3)]
  report_stats << ['Average', data.mean.round(3)]
  report_stats << ['Standard_Deviation', data.standard_deviation.round(3)]
  report_stats << ['Q1', data.get_quantiles(0.25).round(3)]
  report_stats << ['Median', data.get_quantiles(0.5).round(3)]
  report_stats << ['Q3', data.get_quantiles(0.75).round(3)]
  return report_stats
end

def report_ranks(gene_pos_ranks)
	report_ranks = []
	gene_pos_ranks.each do |gene_pos_rank|
		report_ranks << gene_pos_rank
	end
	return report_ranks
end

def get_cdf_values(known_ranks)
	known_ranks.sort_by!{|known_rank| known_rank[1].to_f}
	number_known_ranks = known_ranks.length
	known_ranks.each_with_index do |known_rank , i|
			known_rank = known_rank.insert(2,(i+1).fdiv(number_known_ranks))
	end
	return known_ranks
end


########################### OPTPARSE ########################
#############################################################

options = {}
OptionParser.new do  |opts|

  options[:rankings] = nil
  opts.on("-r","-rankings RANKS", "The roots to the rankings file") do |rankings|
    options[:rankings] = rankings
  end

  options[:execution_mode] = "stats" 
  opts.on("-e","-execution_mode MODE", "The mode of execution" ) do |mode|
  	options[:execution_mode] = mode 
  end

end.parse!

########################### MAIN ############################
#############################################################

rankings = options[:rankings]

known_ranks = open_rank_file(options[:rankings])
known_ranks = get_cdf_values(known_ranks)

if !known_ranks.empty?
	if options[:execution_mode] == "stats"
		all_ranks = known_ranks.map{|rank_row| rank_row[1].to_f}
		report_stats(all_ranks).each do |stat|
	    puts stat.join("\t")
	  end
	elsif options[:execution_mode] == "ranks"
		report_ranks(known_ranks).each do |rank|
			puts rank.join("\t")
	  end
	end
end


	


