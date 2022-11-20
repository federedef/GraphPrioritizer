#!/usr/bin/env Rscript
library(RcppCNPy)
library(optparse)
library(WGCNA) # For bicor
library(stats)

#get_individual_cor <- function(x,y,method) {
#
#  if ( method %in% c("pearson", "kendall", "spearman")) {
#    cor_xy <- cor(x,y, use = "complete.obs", method = method)
#  } else if ( method == "bicor" ) {
#    cor_xy <- bicor(x,y, use = "pairwise.complete.obs")
#  }
#
#  return(cor_xy)
#
#}

#get_individual_pval <- function(x,y,){
#
#  if ( method %in% c("pearson", "kendall", "spearman")) {
#    cor_xy <- cor.test(x,y, use = "complete.obs", method = method)
#  } else if ( method == "bicor" ) {
#    # alternatives -> c("two.sided", "less", "greater")
#    cor_xy <- bicorAndPvalue(x,y, use = "pairwise.complete.obs", alternative=)
#  }
#}

get_cor_mat <- function(table_data, method) {
  ## https://stackoverflow.com/questions/9917242/create-a-matrix-from-a-function-and-two-numeric-data-frames
  ## Vincent's solution    
  #cor_mat <- outer(
  #  colnames(table_data), 
  #  colnames(table_data), 
  #  r <- Vectorize(function(i,j) get_individual_cor(table_data[,i],table_data[,j], method)
  #)

  if ( opt$method %in% c("pearson", "kendall", "spearman")) {
    cor_m <- cor(table_data, use = "complete.obs", method = opt$method)
  } else if ( opt$method == "bicor" ) {
    cor_m <- bicor(table_data, use = "pairwise.complete.obs")
  }

}

get_pval_mat <- function(table_data,method,type) {

  #pval_mat <- outer(
  #  colnames(table_data), 
  #  colnames(table_data), 
  #  r <- Vectorize(function(i,j) get_individual_pval(table_data[,i],table_data[,j], method, type))
  #)

  if ( method %in% c("pearson", "kendall", "spearman")) {
    # alternative = c("two.sided", "less", "greater")
    # method = c("pearson", "kendall", "spearman")
    # alternative = c("two.sided", "less", "greater")
    pval_mat <- corAndPvalue(table_data, use = "pairwise.complete.obs", method = method, alternative = type)$p
  } else if ( method == "bicor" ) {
    # alternatives -> c("two.sided", "less", "greater")
    pval_mat <- bicorAndPvalue(table_data, use = "pairwise.complete.obs", alternative= type)$p
  }

  #if ( method %in% c("pearson", "kendall", "spearman")) {
  #  cor_xy <- cor.test(table_data, use = "complete.obs", method = method)
  #} else if ( method == "bicor" ) {
  #  # alternatives -> c("two.sided", "less", "greater")
  #  cor_xy <- bicorAndPvalue(table_data, use = "pairwise.complete.obs", alternative=)
  #}

  return(pval_mat)
}

#get_individual_pval <- function(x,y,method, type){
#
#  if ( method %in% c("pearson", "kendall", "spearman")) {
#    # alternative = c("two.sided", "less", "greater")
#    # method = c("pearson", "kendall", "spearman")
#    cor_xy <- cor.test(x,y, use = "complete.obs", method = method, alternative = type)$p.value
#  } else if ( method == "bicor" ) {
#    # alternatives -> c("two.sided", "less", "greater")
#    cor_xy <- bicorAndPvalue(x,y, use = "pairwise.complete.obs", alternative= type)
#  }
#
#  return(cor_xy)
#}

# Poner función para el pvalor ajustado.
# Poner función para filtrado por cutoff y binarizado.

transform_pval <- function(){
  # https://stat.ethz.ch/R-manual/R-devel/library/stats/html/p.adjust.html
}


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
  if (!is.na(bonferroni)){
    p_val <- p_val * bonferroni
  }
  if (p_val <= cut_off){
    if (binary == TRUE) {
        return(1)
      } else if (binary == FALSE) {
        return(rho)
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
  make_option(c("-m", "--method"), default="pearson", type = "character", 
              help="The correlation method desired"),
  make_option(c("-s","--separator"), default=",", type="character",
              help="insert the field separator of the fiel"),
  make_option(c("-o", "--output_path"), default=".", type="character",
              help="Output matrix path"),
  make_option(c("-O", "--output_name"), type="character",
              help="Output name "),
  make_option(c("-t","--test"), default = "two.sided" , type="character",
              help="type of hypotesis testing two.sided, less, greater"),
  make_option(c("-b", "--binarize"), action="store_true", default=FALSE,
        help="Binarize the matrix"),
  make_option(c("-f","--bonferroni"), action="store_true", default=FALSE,
        help="apply bonferroni correction")
)

######################## MAIN #########################
#######################################################

opt <- parse_args(OptionParser(option_list=option_list))
# Load table data opt$separator
table_data <- read.table(opt$input_table,sep="\t",header=T,check.names = F)

cor_m <- get_cor_mat(table_data, opt$method)

#if ( opt$method %in% c("pearson", "kendall", "spearman")) {
#  cor_m <- cor(table_data, use = "complete.obs", method = opt$method)
#} else if ( opt$method == "bicor" ) {
#  cor_m <- bicor(x, y = NULL, use = "complete.obs")
#}

if ( !is.na(opt$test) ) {
  print("con el test")
  alpha <- NA
  # Step-1. Getting raw p-values matrix.
  pval_mat <- get_pval_mat(table_data,opt$method,type=opt$test)
  # Step-2(TODO). Getting adjusted p-value.
  # Step-3. Select by alpha cut-off.
  cut_off <- 0.05
  pval_mat <- (pval_mat <= cut_off)*1
  cor_m <- cor_m * pval_mat
  # Step-4 (OPTIONAL). Getting binarized cor_mat.
  if (opt$binarize == TRUE) {
    cor_m <- (cor_m > 0)*1
  } 

} else if ( is.na(opt$test) ) {
  print("sin el test")
  cor_m <- 0.5 + 0.5*cor_m
}

#if ( !is.na(opt$test) ) {
#  print("con el test")
#  alpha <- NA
#  if (opt$bonferroni == TRUE) {
#    print("aplicando bonferroni")
#    alpha <- ncol(table_data) * (ncol(table_data) - 1) / 2
#  }
#  cor_m <- apply(cor_m,c(1,2),cor_test,n=nrow(table_data),type="upper",cut_off=0.05,binary=opt$binarize, bonferroni = alpha)
#} else if ( is.na(opt$test) ) {
#  print("sin el test")
#  cor_m <- 0.5 + 0.5*cor_m
#}

# Return list of corrs
output_list <- file.path(opt$output_path, opt$output_name)
cor_pairs <- as.data.frame(as.table(cor_m))
cor_pairs <- cor_pairs[which(cor_pairs[,3] != 0),]
write.table(cor_pairs,output_list,sep="\t",col.names=F,row.names=F,quote=F)