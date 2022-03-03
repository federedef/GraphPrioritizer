#!/usr/bin/env Rscript
library(RcppCNPy)
library(optparse)



option_list <- list(
	make_option(c("-d", "--data_files"), type="character",
		help="comma-sepparated string, indicating the paths to the input files. Path patterns all also allowed"),
	
	make_option(c("-m", "--method"), type="character", default="pearson",
		help="Correlation method. Method available are 'pearson', 'spearman' and 'kendall'"),
	
	make_option(c("-D", "--clean_diagonal"), type="logical", default=FALSE, action = "store_true",
    		help="Clean diagonal"),
	
	make_option(c("-o", "--output"), type="character", default="output",
		help="Output figure path"),

	make_option(c("-O", "--output_file"), type="character", default="matrices_correlation",
                help="Output figure names (without '.png' extension"),
	make_option(c("-W", "--width"), type="integer", default=10,
                help="Set the plot width"),
	make_option(c("-H", "--height"), type="integer", default=10,
                help="Set the plot height"),
	make_option(c("-n", "--names"), type="character", default = NULL,
                help="comma-sepparated string, indicating the names to the input matrices at the same order as input matrices.")
	
	
)
opt <- parse_args(OptionParser(option_list=option_list))
file_list <- unlist(strsplit(opt$data_files, split=","))

if (length(file_list) == 1)
file_list <- Sys.glob(paths = file_list)
all_matrices <- lapply(file_list, npyLoad) 
if (!is.null(opt$names)){
	matrices_names <- unlist(strsplit(opt$names, split=","))
} else {
	matrices_names <- unlist(lapply(file_list, basename))
}

names(all_matrices) <- matrices_names
if (opt$clean_diagonal) {
	for (matrix_name in names(all_matrices)) {
		matrix_to_clean <- all_matrices[[matrix_name]]
		diag(matrix_to_clean) <- NA
		all_matrices[[matrix_name]] <- matrix_to_clean  
	}
}


all_matrices <- lapply(all_matrices, function(matrix_to_transform){
	vect_matrix <- as.vector(matrix_to_transform)
	vect_matrix <- vect_matrix[!is.na(vect_matrix)]
	return(vect_matrix)	
})

if (length(unique(unlist(lapply(all_matrices, length)))) > 1) stop("Matrices have diferent sizes")
all_matrices <- as.data.frame(t(do.call(rbind, all_matrices)))
output_file <- file.path(opt$output, paste0(opt$output_file, ".png"))

png(output_file, width = opt$width, height = opt$height, units = "cm", res = 500)
	PerformanceAnalytics::chart.Correlation(as.data.frame(all_matrices), histogram=TRUE, pch=19, log="xy", method = opt$method)
dev.off()
