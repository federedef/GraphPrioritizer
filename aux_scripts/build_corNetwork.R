#!/usr/bin/env Rscript
library(RcppCNPy)
library(optparse)

option_list <- list(
  make_option(c("-i", "--input_table"), type="character",
              help="insert name of a data file"),
  make_option(c("-s","--separator"), default=",", type="character",
              help="insert the field separator of the fiel"),
  make_option(c("-o", "--output_path"), default=".", type="character",
              help="Output matrix path"),
  make_option(c("-O", "--output_name"), type="character",
              help="Output name ")
)

opt <- parse_args(OptionParser(option_list=option_list))
# Load table data opt$separator
table_data <- read.table(opt$input_table,sep="\t",header=T)
cor_m <- cor(table_data)
cor_m <- 0.5 + 0.5*cor_m

# Return list of corrs
output_list <- file.path(opt$output_path, opt$output_name)
cor_pairs <- as.data.frame(as.table(cor_m))
write.table(cor_pairs,output_list,sep="\t",col.names=F,row.names=F,quote=F)