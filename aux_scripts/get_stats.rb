#!/usr/bin/env ruby

require 'expcalc'
require 'optparse'

def get_stats(data)
      stats = Hash.new(0)
      stats[:average] = data.sum().fdiv(data.size)
      sum_devs = data.sum{|element| (element - stats[:avg]) ** 2}
      stats[:variance] = sum_devs.fdiv(data.size)
      stats[:standardDeviation] = stats[:variance] ** 0.5
      stats[:max] = data.max
      stats[:min] = data.min

      stats[:count] = data.size
      data.each do |value|
        stats[:countNonZero] += 1 if value != 0
      end

      stats[:q1] = data.get_quantiles(0.25)
      stats[:median] = data.get_quantiles(0.5)
      stats[:q3] = data.get_quantiles(0.75)
      return stats
end


def report_stats(stats)
  report_stats = []
  report_stats << ['Elements', stats[:count]]
  report_stats << ['Elements Non Zero', stats[:countNonZero]]
  report_stats << ['Non Zero Density', stats[:countNonZero].fdiv(stats[:count])]
  report_stats << ['Max', stats[:max]]
  report_stats << ['Min', stats[:min]]
  report_stats << ['Average', stats[:average]]
  report_stats << ['Variance', stats[:variance]]
  report_stats << ['Standard Deviation', stats[:standardDeviation]]
  report_stats << ['Q1', stats[:q1]]
  report_stats << ['Median', stats[:median]]
  report_stats << ['Q3', stats[:q3]]
  return report_stats
end

def extract_data(lst_file)
    data = []

    File.open(lst_file,"r").each do |line|
    line.chomp!
    data.append(line.to_f)
    end

    return data
end


########################### OPTPARSE ########################
#############################################################

options = {}

OptionParser.new do |opts|

  options[:data_file] = nil
  opts.on("-d","-data_file DATA", "The path to the DATA file") do |data_file|
    options[:data_file] = data_file
  end
  
end.parse!


####################################################################

path2data=options[:data_file]

data = extract_data(path2data)
stats = get_stats(data)
report_stats(stats).each do |stat|
    puts stat.join("\t")
end




