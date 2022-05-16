#!/usr/bin/env Rscript
library(RcppCNPy)
library(optparse)
#library("WGCNA")

cor_test <- function(rho, n, type, cut_off, binary, bonferroni = NA){
  # Obtaining t value.
  t <- (rho*sqrt(n-2))/(1-rho^2)
  # Obtaining p value.
  if ( type == "upper") {
    p_val <- (1 - pt(t,(n-2)))
  } else if ( type == "lower"){
    p_val <- pt(t,(n-2))
  } else if ( type == "both" ){
    p_val <- 2*(1 - pt(abs(t),(n-2)))
  }
  # Adjusting p-value.
  if (bonferroni == TRUE){
    p_val <- p_val * bonferroni
  }
  if (p_val <= cut_off){
    if (binary == TRUE) {
        return(1)
      } else if (binary == FALSE) {
        return(rho)
        #return(rho)
      }
  } else {
    return(0)
  }
}


######################## OPTPARSER ####################
#######################################################

option_list <- list(
  make_option(c("-i", "--input_table"), type="character",
              help="insert name of a data file"),
  make_option(c("-s","--separator"), default=",", type="character",
              help="insert the field separator of the fiel"),
  make_option(c("-o", "--output_path"), default=".", type="character",
              help="Output matrix path"),
  make_option(c("-O", "--output_name"), type="character",
              help="Output name "),
  make_option(c("-t","--test"), default = NA , type="character",
              help="upper, lower , both")
)

######################## MAIN #########################
#######################################################
# make_option(c("-b","--binarize"), action= "store_true", default = FALSE,
#             help="binarize matrix")

opt <- parse_args(OptionParser(option_list=option_list))
# Load table data opt$separator
table_data <- read.table(opt$input_table,sep="\t",header=T,check.names = F)
#print(table_data[1:10,1:20])
cor_m <- cor(table_data, use = "complete.obs")
if ( !is.na(opt$test) ) {
  print("con el test")
  alpha <- ncol(table_data) * (ncol(table_data) - 1) / 2
  cor_m <- apply(cor_m,c(1,2),cor_test,n=nrow(table_data),type="upper",cut_off=0.05,binary=FALSE, bonferroni = alpha)
} else if ( is.na(opt$test) ) {
  print("sin el test")
  cor_m <- 0.5 + 0.5*cor_m
  #print("holaaaa")
  #cor_m <- cor_m
}

# Return list of corrs
output_list <- file.path(opt$output_path, opt$output_name)
cor_pairs <- as.data.frame(as.table(cor_m))
#cor_pairs <- cor_pairs[which(cor_pairs[,3] < 0.5),]
write.table(cor_pairs,output_list,sep="\t",col.names=F,row.names=F,quote=F)