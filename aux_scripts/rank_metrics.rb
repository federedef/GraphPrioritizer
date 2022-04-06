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
			known_backups_rank.append([seed_gene, possible_gene, line.split("\t")[2].to_f])
		end
	end
	return known_backups_rank if !known_backups_rank.empty?
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

def report_ranks(gene_pos_ranks)
	report_ranks = []
	gene_pos_ranks.each do |gene_pos_rank|
		report_ranks << gene_pos_rank
	end
	return report_ranks
end


#def genseed_name_from_filename(rank_file)
#	seed_gene = rank_file.split("_")[0]
#	return seed_gene
#end

def get_cdf_values(known_backups)
	known_backups.sort_by!{|known_backup| known_backup[2]}
	number_known_backups = known_backups.length
	known_backups.each_with_index do |known_backup , i|
			known_backup = known_backup.append((i+1).fdiv(number_known_backups))
	end
	return known_backups
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

  options[:execution_mode] = "stats" 
  opts.on("-e","-execution_mode MODE", "The mode of execution" ) do |mode|
  	options[:execution_mode] = mode 
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
	candidates = search_candidates(ranking, backups)
	known_backups_ranks += candidates if !candidates.nil?
end

known_backups_ranks = get_cdf_values(known_backups_ranks)

if !known_backups_ranks.empty?
	if options[:execution_mode] == "stats"
		all_ranks = known_backups_ranks.map{|rank_row| rank_row[2]}
		report_stats(all_ranks).each do |stat|
	    puts stat.join("\t")
	  end
	elsif options[:execution_mode] == "ranks"
		report_ranks(known_backups_ranks).each do |rank|
			puts rank.join("\t")
	  end
	end
end


	


