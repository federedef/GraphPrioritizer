#!/usr/bin/env Rscript
library(umap)
library(optparse)
library(RcppCNPy)
# Based on paper -> https://doi.org/10.1038/s41467-020-15351-4 

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

build_sim_matrix <- function(embbeded_data){
  dot_M <- embbeded_data %*% t(embbeded_data)
  one_M <- matrix(1,nrow(dot_M),ncol(dot_M))
  diag_vec <- diag(dot_M)
  I <- diag(nrow(dot_M))
  unit_vec <- matrix(1,nrow = nrow(dot_M))
  
  D <- I * (unit_vec %*% t(diag_vec))
  #D_extend <- D %*% one_M
  D_extend <- matrix(0,nrow(dot_M),ncol(dot_M))
  for(row in 1:nrow(dot_M)){
    D_extend[row,] <- diag_vec[row] 
  }
  # Formula (Alg lineal): ||u-v||^2 = ||u||^2 + ||v||^2 - 2|u,v|
  distance_M <- sqrt(D_extend + t(D_extend) - 2*dot_M)
  sim_M <- 1/(1+distance_M)
}

matrix2list <- function(sim_mat, names_data) {
  number_of_points <- nrow(sim_mat)
  sim_list <- data.frame()
    for(row in seq(1,number_of_points)){
        for(col in seq(row,number_of_points)){
          x_name <- names_data[row]
          y_name <- names_data[col]
          sim_xy <- sim_mat[row,col]
          sim_list <- rbind(sim_list,c(x_name,y_name,sim_xy))
        }
    }
    return(sim_list)
}

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

#table <- table[1:100,1:300] # <- just for trying

names <- table[,opt$field_for_subjects]
data <- table[,-opt$field_for_subjects]
data <- as.data.frame(apply(data, 2, as.numeric))
print(any(is.na(data)))
print(dim(data))
data <- data[ , apply(data, 2, function(x) !any(is.na(x)))]
print(any(is.na(data)))
print(dim(data))

data_umap = umap(data)
print("ya esta listo el umap")
data_umap = data_umap$layout
#sim_list = build_sim_list(data_umap,names)
print("Building matrix similarity")
sim_mat <- build_sim_matrix(data_umap)
#print("Distancitas calculadas, pasando ahora de matriz a lista")
#n <- matrix2list(sim_mat, names)
#print("pasando a poner el output")

# Return list of similarities
output_list <- file.path(opt$output_path, opt$output_name)

#write.table(sim_list,output_list,sep="\t",col.names=F,row.names=F,quote=F)

# Preparing output path
output_matrix <- file.path(opt$output_path, opt$output_name) # Return the matrix network.
# Saving matrix
npySave(output_matrix,sim_mat)
# Saving node list
write.table(names,paste(output_matrix,".lst",sep=""),row.names=FALSE,col.names=FALSE,quote=FALSE)
