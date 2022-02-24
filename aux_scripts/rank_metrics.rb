#! /usr/bin/env ruby
require 'optparse'
require 'expcalc'

########################### FUNCTIONS #######################
#############################################################

def search_candidates(rank_file, backups)
	seed_gene = rank_file.split("_")[0]
	known_backups = backups[seed_gene] # An array with every backup gene.
	known_backups_rank = []
	File.open(rank_file,"r").each do |line|
		line.chomp!
		possible_gene = line.split("\t")[0]
		if known_backups.include? possible_gene
			known_backups_rank.append(line.split("\t")[2].to_f)
		end
	end
	return known_backups_rank if !known_backups_rank.nil?
end

def file2hash(backup_file)
	seed2backup = {}
	File.open(backup_file,"r").each do |line|
		line.chomp!
		seed_gene, backup_genes = line.split("\t")
		seed2backup[seed_gene] = backup_genes.split(",")
	end
	return seed2backup
end

def report_stats(data)
  report_stats = []
  report_stats << ['Elements', data.size]
  report_stats << ['Max', data.max.round(3)]
  report_stats << ['Min', data.min.round(3)]
  report_stats << ['Average', data.mean.round(3)]
  report_stats << ['Standard Deviation', data.standard_deviation.round(3)]
  report_stats << ['Q1', data.get_quantiles(0.25).round(3)]
  report_stats << ['Median', data.get_quantiles(0.5).round(3)]
  report_stats << ['Q3', data.get_quantiles(0.75).round(3)]
  return report_stats
end



########################### OPTPARSE ########################
#############################################################

options = {}
OptionParser.new do  |opts|

  options[:rankings] = nil
  opts.on("-r","-rankings RANKS", "The roots to the rankings files ") do |rankings|
    options[:rankings] = rankings.split(",")
  end

  options[:backups] = nil
  opts.on("-c","-backups NODE", "The path to the backup files") do |backups|
    options[:backups] = backups
  end

end.parse!

########################### MAIN ############################
#############################################################

rankings = options[:rankings]

if !options[:backups].nil?
	backups = file2hash(options[:backups])
end

known_backups_ranks = []
rankings.each do |ranking|
	known_backups_ranks += search_candidates(ranking, backups)
end

if !known_backups_ranks.nil?
	report_stats(known_backups_ranks).each do |stat|
    	puts stat.join("\t")
 	end
end


