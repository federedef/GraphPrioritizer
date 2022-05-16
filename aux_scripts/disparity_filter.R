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
              help="Output name "),
  make_option(c("-n","--node_names"), default=NA, type="character",
              help="list of node names")
)

opt <- parse_args(OptionParser(option_list=option_list))

# Load npy adjacency matrix and create graph object.
sem_m <- npyLoad(opt$input_matrix)
sem_nodes <- read.table(opt$node_names, header=F, check.names = F)
sem_nodes <- sem_nodes[,1] # To vector object
print("Load graph")
system.time(sem_g <- graph_from_adjacency_matrix(sem_m, mode="undirected",diag=TRUE,weighted = TRUE))
# Extract graph backbone.
print("backbone filtering")
system.time(bb_graph <- backbone(sem_g)) # Warning: Removing diagonal values, not great issue (?)

sem_m = matrix(0,nrow=nrow(sem_m),ncol=ncol(sem_m))
print("New matrix fill")
system.time({
  for(i in 1:nrow(bb_graph)){
    sem_m[bb_graph$from[i],bb_graph$to[i]] <- bb_graph$weight[i]
    sem_m[bb_graph$to[i],bb_graph$from[i]] <- bb_graph$weight[i]
  }
})

#Load list of nodes.
colnames(sem_m) <- sem_nodes
rownames(sem_m) <- sem_nodes
# Remove files 
notNullRows <- apply(sem_m, 1, function(x) !all(x==0))
sem_m <- sem_m[notNullRows,notNullRows] # Remind it's a symmetric matrix.

output_matrix <- file.path(opt$output_path, opt$output_name) # Return the matrix network.
npySave(output_matrix,sem_m)
write.table(colnames(sem_m),paste(output_matrix,".lst",sep=""),row.names=FALSE,col.names=FALSE,quote=FALSE)
