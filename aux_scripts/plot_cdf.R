#!/usr/bin/env Rscript
library(optparse)
library(ggplot2)

option_list <- list(
  make_option(c("-d", "--data_file"), type="character",
              help="insert name of the data file"),
  make_option(c("-f", "--column_first_separator"), type="integer", default=2,
              help="the type of annotation to select"),
  make_option(c("-s", "--column_second_separator"), type="integer", default=3 ,
              help="number of the column for values"),
  make_option(c("-c", "--column_values"), type="integer", default=6 ,
              help="number of the column for values"),
  make_option(c("-o", "--output_name"), type="character",
              help="Output name"),
  make_option(c("-O", "--output"), type="character",
              help="Output path to the file"),
  make_option(c("-H", "--header"), action="store_false", default=FALSE,
                help="The input table not have header line"),
  make_option(c("-w", "--width"), type="integer", default=10,
                help="Set the plot width"),
  make_option(c("-g", "--height"), type="integer", default=10,
                help="Set the plot height")
)

opt <- parse_args(OptionParser(option_list=option_list))
data_table <- read.table(opt$data_file, header=opt$header, sep="\t")
  
# Basic ECDF plot using ggplot package
names(data_table)[opt$column_values] <- "values"
names(data_table)[opt$column_first_separator] <- "first_separator"
names(data_table)[opt$column_second_separator] <- "second_separator"

cdf_plot <- ggplot(data_table, aes(x=values,group=second_separator,col=second_separator)) + stat_ecdf() +
  labs(x="percentile",y="CDF",colour = "ker", title = "CDF plots") + theme_minimal() + facet_wrap(~ first_separator)

output_file <- file.path(opt$output, paste0(opt$output_name, ".png"))
png(output_file, width = opt$width, height = opt$height, units = "cm", res = 200)
        cdf_plot
dev.off()