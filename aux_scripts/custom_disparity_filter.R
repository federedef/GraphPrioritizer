#!/usr/bin/env Rscript
library(RcppCNPy)
library(optparse)

# Disparity filter by Alessandro Vespignani, mathematical fundations in: 
# Paper: https://doi.org/10.1073/pnas.0808904106
##---------------------------------------------------##
# Code manipulated from Menche-Lab github repository
# Repo: https://github.com/menchelab/MultiOme/blob/main/functions/sim_mat_functions.R
# Paper: https://doi.org/10.1038/s41467-021-26674-1

########################## FUNCTIONS ##################
#######################################################

backbone_cal = function(weighted_adj_mat){
  pval_mat = weighted_adj_mat
  W = colSums(weighted_adj_mat, na.rm = T)
  k = apply(weighted_adj_mat, 2, function(x) sum(!is.na(x)))
  for(i in 1:ncol(pval_mat)){
     pval_mat[,i] = (1-(weighted_adj_mat[,i]/W[i]))^(k[i]-1)
  }
  return(pval_mat)
}

# Create edge list from that p value matrix
adj_mat_from_pvalmat = function(pvalmat, threshold, weighted_adj_mat, binarize = FALSE){
  result_mat = pvalmat < threshold
  # adjacency matrix, obtained when both p[i,j] and p[j,i] match the criteria
  new_adj = t(result_mat)*result_mat
  new_adj[is.na(new_adj)] = 0
  # remove genes with no significance
  k = apply(new_adj, 2, sum)
  if(binarize == TRUE) {
    final_adj_mat = new_adj[,k>0]
    final_adj_mat = final_adj_mat[k>0,]
  } else {
    final_adj_mat = weighted_adj_mat[,k>0]
    final_adj_mat = final_adj_mat[k>0,]
  }
  return(final_adj_mat)
}

###################### OPTPARSE ####################
####################################################

option_list <- list(
  make_option(c("-i", "--input_matrix"), type="character",
              help="insert name of a npy file"),
  make_option(c("-o", "--output_path"), default=".", type="character",
              help="Output matrix path"),
  make_option(c("-O", "--output_name"), type="character",
              help="Output name "),
  make_option(c("-n","--node_names"), default=NA, type="character",
              help="list of node names"),
  make_option(c("-b", "--binarize"), action="store_true", default=FALSE,
                help="Binarize the output matrix")
)

##################### MAIN #########################
####################################################


opt <- parse_args(OptionParser(option_list=option_list))

print(opt$binarize)

# Load npy adjacency matrix and create graph object.
sem_m <- npyLoad(opt$input_matrix)
sem_nodes <- read.table(opt$node_names, header=F, check.names = F)
sem_nodes <- sem_nodes[,1] # To vector object
colnames(sem_m) <- sem_nodes
rownames(sem_m) <- sem_nodes

# Execute the disparity filter.
# obtaining the p-values
pval_matrix <- backbone_cal(sem_m)
# selecting the nodes weight < 0.05
sem_m <- adj_mat_from_pvalmat(pval_matrix, 0.1, sem_m, opt$binarize)

# Preparing output path
output_matrix <- file.path(opt$output_path, opt$output_name) # Return the matrix network.
# Saving matrix
npySave(output_matrix,sem_m)
# Saving node list
write.table(colnames(sem_m),paste(output_matrix,".lst",sep=""),row.names=FALSE,col.names=FALSE,quote=FALSE)
