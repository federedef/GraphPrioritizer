#!/usr/bin/env Rscript
library(umap)
library(optparse)

dist2sim <- function(d){
  sim <- 1/(1+d)
  return(sim)
}

euclidean_dist <- function(x,y) {
	dist <- sqrt(sum((x-y)^2))
	return(dist)
}

build_sim_list <- function(embbeded_data, names_data) {
	number_of_points <- nrow(embbeded_data)
	sim_list <- data.frame()
    for(row in seq(1,number_of_points)){
        for(col in seq(row,number_of_points)){
        	x <- embbeded_data[row,]
        	y <- embbeded_data[col,]
        	x_name <- names_data[row]
        	y_name <- names_data[col]
        	sim_xy <- dist2sim(euclidean_dist(x,y))
            sim_list <- rbind(sim_list,c(x_name,y_name,sim_xy))
        }
    }
    return(sim_list)
}

#build_sim_matrix <- function(embbeded_data) {
#	number_of_points <- nrow(embbeded_data)
#	sim_mat <- matrix(0,row=number_of_points,col=number_of_points)
#    for(row in seq(1,number_of_points)){
#        for(col in seq(row,number_of_points)){
#        	x <- embbeded_data[row,]
#        	y <- embbeded_data[col,]
#            sim_mat[row,col] <-  dist2sim(euclidean_dist(x,y))
#            if (row != col) {
#            	sim_mat[col,row] <- dist2sim(euclidean_dist(x,y))
#            }
#        }
#    }
#    return(sim_mat)
#}

######################## OPTPARSER ####################
#######################################################

option_list <- list(
  make_option(c("-i", "--input_table"), type="character",
              help="insert name of a data file"),
  make_option(c("-t","--transpose"),action="store_true",default=FALSE,
  	          help="transpose the table data"),
   make_option(c("-f", "--field_for_subjects"), type="integer", default=1 ,
              help="number of the column for values"),
  make_option(c("-o", "--output_path"), default=".", type="character",
              help="Output matrix path"),
  make_option(c("-O", "--output_name"), type="character",
              help="Output name ")
)

######################## MAIN #########################
#######################################################

opt <- parse_args(OptionParser(option_list=option_list))
# Load table data.
table <- read.table(opt$input_table,sep="\t",header=F,check.names = F)

if (opt$transpose) {
	print("transposed")
	table <- t(table)
}

names <- table[,opt$field_for_subjects]
data <- table[,-opt$field_for_subjects]

data_umap = umap(data)
data_umap = data_umap$layout
sim_list = build_sim_list(data_umap,names)

# Return list of similarities
output_list <- file.path(opt$output_path, opt$output_name)
write.table(sim_list,output_list,sep="\t",col.names=F,row.names=F,quote=F)