#! /usr/bin/env Rscript

#' @author refactored by Fernando Moreno Jabato <jabato(at)uma(dot)es>. Original author Pedro Seoane Zonjic
#' @import optparse, ROCR


################################################################
##                           CONFIGURE                        ##
################################################################

# Load necessary packages
# suppressPackageStartupMessages(library(pROC))
suppressPackageStartupMessages(library(ROCR))
suppressPackageStartupMessages(library(optparse))
suppressPackageStartupMessages(library(zoo))

# Load necessary functions
full.fpath <- tryCatch(normalizePath(parent.frame(2)$ofile),  # works when using source
                       error=function(e) # works when using R CMD
                         normalizePath(unlist(strsplit(commandArgs()[grep('^--file=', commandArgs())], '='))[2]))
bname <- dirname(full.fpath)

# Import functions
if(is.null(bname)){
  source_files <- list.files(path = paste("ROCanalysis",.Platform$file.sep,sep=""), pattern = "\\.R$", full.names = T)
}else{
  source_files <- list.files(path = paste(bname,"ROCanalysis",sep=.Platform$file.sep), pattern = "\\.R$",full.names = T)
}
invisible(lapply(source_files, source))
to_remove <- c("to_remove","bname","source_files","script.name","script.path","initial.options")
rm(list = ls()[which(ls() %in% to_remove)])



# Prepare INPUT parser
option_list <- list(
	make_option(c("-i", "--input"), type="character",
		dest="input_file",help="Input file with table format.Several files can be specified ussing colons (:)"),
	make_option(c("-s", "--series"), type="character",
		dest="column_series",help="Prediction series stored as columns. Several series can be specified using colons (:). Indexes can be numbers or Column names"),
  make_option(c("-S", "--series_names"), type="character", default = NULL,
    dest="names_series",help="[OPTIONAL]Prediction series names to be plotted. Several series can be specified using colons (:)"),
    make_option(c("-t", "--column_tags"), type="character",
        dest="column_tags",help="Prediction succes value stored as columns. Several series can be specified using colons (:). Indexes can be numbers or Column names"),
    make_option(c("-o", "--output_file"), type="character", default="ROC",
        help="Output path. Extension will be added automatically. [Default output = '%default.pdf']"),
  	make_option(c("-m", "--method"), type="character", default="ROC",
  		help="[OPTIONAL] Graph method to be plotted. Available methods are: ROC (ROC), Precission Recall (prec_rec) and cuttoff curver (cut). [Default = '%default']"),
    make_option(c("-f", "--format"), type="character", default="pdf",
        help="[OPTIONAL] Output format. Available formats are: PDF (pdf) or PNG (png) [Default = '%default']"),
    make_option(c("-r", "--rate"), type="character", default="acc",
        help="[OPTIONAL] Measure to be plotted (only used for cutoff method). Available measures list in ROCR::performance method documentation. [Default = %default]"),
    make_option(c("-x", "--xlimit"), type="character", default="0.0:1.0",
        help="[OPTIONAL] X-axis range separated by colons (:). [Default = '%default']"),
    make_option(c("-y", "--ylimit"), type="character", default="0.0:1.0",
        help="[OPTIONAL] Y-axis range separated by colons (:). [Default = '%default']"),
    make_option(c("-", "--legendposition"), type="character", default=NULL,
        help="[OPTIONAL] Legend position. Position by default have been selected for each curve type. Allowed: bottomright, bottomleft, topright, topleft"),
    make_option(c("-T", "--tag_order"), type="character", default=NULL,
        help="[OPTIONAL] Negative and Positive tag values used in TAG_COLUMNS can be specified using 'NEG_tag:POS_tag' format. Default R comparing system will be used to set NEG < POS tag values. You MUST provide as many tuples as series given and separate all by semicolons"),
    make_option(c("-L", "--no_legend"), action="store_true", default=FALSE,
        help="[FLAG] Remove legend"),
    make_option(c("-C", "--no_compact"), action="store_false", default=TRUE,
        help="[FLAG] Generate a plot for each data serie"),
    make_option(c("-e", "--export"), action="store_true", default=FALSE,
        help="[FLAG] Export graph measures into a plain text file"),
    make_option(c("-c", "--clusters"), type="character", default=NULL,
        help="[OPTIONAL] Tags to be assigned to each serie separated by colons (:)")
)


################################################################
##                        LOAD & PARSE                        ##
################################################################

# Handle input
opt <- parse_args(OptionParser(option_list=option_list))

units_sep <- ":"
tuples_sep <- ";"

# Parse complex inputs
series <- lapply(unlist(strsplit(opt$column_series,units_sep)), function(col_index){ifelse(suppressWarnings(!is.na(as.numeric(col_index))),as.numeric(col_index),col_index)})
if(is.null(opt$names_series)){
  s_names <- series
}else{
  s_names <- unlist(strsplit(opt$names_series,units_sep))
}
tags   <- lapply(unlist(strsplit(opt$column_tags,units_sep)), function(col_index){ifelse(suppressWarnings(!is.na(as.numeric(col_index))),as.numeric(col_index),col_index)}) 
files  <- unlist(strsplit(opt$input_file, units_sep))
xlimit <- as.numeric(unlist(strsplit(opt$xlimit,units_sep)))
ylimit <- as.numeric(unlist(strsplit(opt$ylimit,units_sep)))
label_order <- if(is.null(opt$tag_order)) NULL else{unlist(strsplit(opt$tag_order, tuples_sep))}
clusters    <- if(is.null(opt$clusters)) NULL else{unlist(strsplit(opt$clusters, units_sep))}

# Primero tenemos que cargar los datos con una funciçon tipo collect_data.
# Sería una lista de dataframes con (tag column, serie column) para cada uno de los distintos archivos dados.
 # O bien sé formaría un datgaframe para cada serie (caso de un solo archivo).

 # Suponiendo que está cargado... sigamos el análisis.

 # Sioguiente punto, si quiero hacer algo del ROCR, pasamos a formato del ROCR, si no del pROC, y así.
 # Esto permite poder utilizar con fuerza difertentes libreriuas en funcion de lo nque requiera

 # Ahora, tendríamos un formato de ese tipo para cargar las dintitas curvas en función de lo que quiera.

 # SEPARAR SI QUIERO --> DIBUJAR CURVA O OBTENER COMPONENTES DE MEDIDA (QUIZÁS NOS INTERESE REALIZAR INTERVALOS DE CONFIANZA)

 # Ojear que la variable tags y poner la primera columna del dataframe como los tags y lo otro como la columna del score

 # OJO SCORE == SERIE, ES UNA CUESTIÓN DE ANOTACÓN.

 # Hacer que la función collect data funcione en función de si el número de archivos es uno o varios.
 

if(opt$method %in% c('ROC', 'prec_rec', 'cut')){
    drawing_ROC_curves(file           = files,
                       tags           = tags,
                       series         = series,
                       series_names   = s_names,
                       graphname      = opt$output_file, 
                       method         = opt$method, 
                       xlimit         = xlimit, 
                       ylimit         = ylimit, 
                       format         = opt$format, 
                       label_order    = label_order,
                       compact_graph  = opt$no_compact,
                       legend         = !opt$no_legend,
                       cutOff         = opt$method == 'cut',
                       rate           = opt$rate,
                       legendPos      = opt$legendposition,
                       exportMeasures = opt$export)
}else{
    stop(paste("Method not allowed: ", opt$method, sep = ""))
}
