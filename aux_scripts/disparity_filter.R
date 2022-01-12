#!/usr/bin/env Rscript
library(RcppCNPy)
library(disparityfilter)
library(igraph)
library(optparse)

option_list <- list(
  make_option(c("-i", "--input_matrix"), type="character",
              help="insert name of a npy file"),
  make_option(c("-o", "--output_path"), default=".", type="character",
              help="Output matrix path"),
  make_option(c("-O", "--output_name"), type="character",
              help="Output name ")
)

opt <- parse_args(OptionParser(option_list=option_list))

# Load npy adjacency matrix and create graph object.
sem_m <- npyLoad(opt$input_matrix)
sem_g <- graph_from_adjacency_matrix(sem_m, mode="undirected",diag=TRUE,weighted = TRUE)

# Extract graph backbone.
bb_graph <- backbone(sem_g) # Warning: Removing diagonal values, not great issue (?)

sem_m = matrix(0,nrow=nrow(sem_m),ncol=ncol(sem_m))
for(i in 1:nrow(bb_graph)){
  sem_m[bb_graph$from[i],bb_graph$to[i]] <- bb_graph$weight[i]
}

output_matrix <- file.path(opt$output_path, opt$output_name) # Return the matrix network.
npySave(output_matrix,sem_m)
