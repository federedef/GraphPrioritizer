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

# Load table data.
table_data <- read.table(opt$input_table,sep=opt$separator,header=T, row.names=1)
cor_m <- cor(table_data)
cor_m <- 0.5 + 0.5*cor_m

# Return npy matrix and list of nodes.
output_matrix <- file.path(opt$output_path, opt$output_name) # Return the matrix network.
npySave(output_matrix,cor_m)
write.table(colnames(cor_m), paste(output_matrix,".lst",sep="") , append = FALSE, sep = "\n", dec = ".")