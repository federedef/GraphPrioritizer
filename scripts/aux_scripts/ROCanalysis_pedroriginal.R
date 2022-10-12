#! /usr/bin/env Rscript
suppressPackageStartupMessages(library(pROC))
suppressPackageStartupMessages(library(ROCR))
suppressPackageStartupMessages(library(optparse))


drawing_ROC_curves <- function(table, tags, series, graphname, method, xlimit, ylimit, format, label_order){
	if(method == 'ROC'){
		x_axis_measure="fpr"
		y_axis_measure="tpr"
	}
	else if(method == 'prec_rec'){
		x_axis_measure="rec"
		y_axis_measure="prec"
	}
    if(format=='pdf'){
	    pdf(graphname)
    }else if(format=='png'){
	    png(graphname)
    }
    	colors <- c('red', 'blue', 'green', 'orange', 'black', 'magenta', 'yellow', 'cyan', 'darkgray')
        all_tags <- table[,tags]
        main_serie <- table[,series[1]]
    	#roc_data <- roc(all_tags, main_serie, smooth=TRUE, plot=TRUE, col=colors[1], main="Statistical comparison", percent=FALSE, add=FALSE)
        
        pred <- prediction(main_serie, all_tags, label_order)
        perf <- performance(pred, measure = y_axis_measure, x.measure =  x_axis_measure)
        if(method == 'ROC'){
	        auc <- performance(pred, measure = "auc")
	        AUC <- unlist(slot(auc, 'y.values'))
	}
        plot(perf, col=colors[1], xlim=xlimit, ylim=ylimit)
	if(method == 'ROC'){
    		legend_tag <- c(paste(series[1], '=', round(AUC, 3), sep=' '))
	}else{
	    	legend_tag <- c(series[1])
	}
    	if(length(series) > 1 ){
            for(i in 2:length(series)){ 
                current_serie <- series[i]
                serie_values <- table[,series[i]]
                pred <- prediction(serie_values, all_tags, label_order)
                perf <- performance(pred, measure = y_axis_measure, x.measure = x_axis_measure)
		if(method == 'ROC'){
         	   	auc <- performance(pred, measure = "auc")
	        	AUC <- unlist(slot(auc, 'y.values'))
		}
                plot(perf, add = TRUE, col=colors[i], xlim=xlimit, ylim=ylimit)

	    #       roc(all_tags, serie_values, smooth=TRUE, plot=TRUE, col=colors[i], percent=FALSE, add=TRUE)
	    #        AUC <- auc(all_tags, serie_values)
			if(method == 'ROC'){
		    		legend_tag <- c(legend_tag, paste(series[i], '=', round(AUC, 3), sep=' '))
			}else{
		    		legend_tag <- c(legend_tag, series[i])
			}
	        }
    	}
        legend("bottomright", legend=legend_tag, col=colors, lwd=2)              
    dev.off()
}

get_best_thresold <- function(perf){
	accuracy <- unlist(slot(perf, "y.values"))
        thresolds <- unlist(slot(perf, "x.values"))
        max_ac <- max(accuracy)
        best_thresold <- max(thresolds[which(accuracy %in% max_ac)])
        print(best_thresold)
}

drawing_cutoff_curves <- function(table, tags, series, graphname, rate, xlimit, ylimit, format){
    if(format=='pdf'){
            pdf(graphname)
    }else if(format=='png'){
            png(graphname)
    }

        colors <- c('red', 'blue', 'green', 'orange', 'black', 'magenta', 'yellow', 'cyan', 'darkgray')
        all_tags <- table[,tags]
        main_serie <- table[,series[1]]     

        pred <- prediction(main_serie, all_tags)
        perf <- performance(pred, measure = rate)
	get_best_thresold(perf)
        plot(perf, col=colors[1], xlim=xlimit, ylim=ylimit)

         if(length(series) > 1 ){
             for(i in 2:length(series)){ 
                 current_serie <- series[i]
                 serie_values <- table[,series[i]]
		         pred <- prediction(serie_values, all_tags)
		         perf <- performance(pred, measure = rate)
			 get_best_thresold(perf)
		         plot(perf, col=colors[i], xlim=xlimit, ylim=ylimit, add=TRUE)
             }
         }
        legend("bottomleft", legend=series, col=colors, lwd=2)              
    dev.off()
}

get_data <- function(input_file){
	data <- read.table(input_file, sep = "\t", header=TRUE)
	#active_data <- data[ , all_cols]
	active_data <- data[complete.cases(data), ]
	return(active_data)
}

drawing_ROC_curves_by_files <- function(files, tags, series, graphname, method, xlimit, ylimit, format, label_order, clusters, no_legend, compact_graph){
        if(method == 'ROC'){
                x_axis_measure="fpr"
                y_axis_measure="tpr"
		legend_position="bottomright"
        }else if(method == 'prec_rec'){
                x_axis_measure="rec"
                y_axis_measure="prec"
		legend_position="topright"
        }

    if(format=='pdf'){
            pdf(graphname)
    }else if(format=='png'){
            png(graphname)
    }
    	colors <- c('red', 'blue', 'green', 'orange', 'black', 'magenta', 'yellow', 'cyan', 'darkgray')
    	main_file <- files[1]
    	main_data <- get_data(main_file)
        all_tags <- main_data[,tags]
        main_serie <- main_data[,series[1]]
    	#roc_data <- roc(all_tags, main_serie, smooth=TRUE, plot=TRUE, col=colors[1], main="Statistical comparison", percent=FALSE, add=FALSE)
        
        pred <- prediction(main_serie, all_tags, label_order)
        perf <- performance(pred, measure = y_axis_measure, x.measure = x_axis_measure)
	if(method=='ROC'){
	        auc <- performance(pred, measure = "auc")
        	AUC <- unlist(slot(auc, 'y.values'))
	}
        plot(perf, col=colors[1], xlim=xlimit, ylim=ylimit)

	if(method=='ROC'){
	    	legend_tag <- c(paste(basename(files[1]), '=', round(AUC, 3), sep=' '))
	}else{
	    	legend_tag <- c(basename(files[1]))
	}
	
    	if(length(series) > 1 ){
		color_by_cluster <- c(colors[1])
            for(i in 2:length(series)){ 
            	current_file <- files[i]
	    	current_data <- get_data(current_file)
                current_serie <- series[i]
                current_tags <- current_data[,tags]
                serie_values <- current_data[,series[i]]
                pred <- prediction(serie_values, current_tags, label_order)
                perf <- performance(pred, measure = y_axis_measure, x.measure = x_axis_measure)
		if(method=='ROC'){
        	        auc <- performance(pred, measure = "auc")
	                AUC <- unlist(slot(auc, 'y.values'))
		}
		plot_color <- colors[i]
		if(!is.null(clusters)){
			plot_color <- colors[match(clusters[i],unique(clusters))]
			color_by_cluster <- c(color_by_cluster, plot_color)
		}
		
                plot(perf, add = compact_graph, col=plot_color, xlim=xlimit, ylim=ylimit)

	    #       roc(all_tags, serie_values, smooth=TRUE, plot=TRUE, col=colors[i], percent=FALSE, add=TRUE)
	    #        AUC <- auc(all_tags, serie_values)
			if(method=='ROC'){
		    		legend_tag <- c(legend_tag, paste(basename(files[i]), '=', round(AUC, 3), sep=' '))
			}else{
		    		legend_tag <- c(legend_tag, basename(files[i]))
			}
	        }
    	}
	if(!no_legend){
		legend_colors <- colors
		if(!is.null(clusters)){
			legend_colors <- color_by_cluster
		}
        	legend(legend_position, legend=legend_tag, col=legend_colors, lwd=2)
	}
    dev.off()	
}

option_list <- list(
    make_option(c("-i", "--input_file"), type="character",
        help="Table values"),
    make_option(c("-o", "--output_file"), type="character", default="ROC.pdf",
        help="Output path. Default=%default"),
    make_option(c("-m", "--method"), type="character", default="ROC",
        help="Method to plot. Default=%default"),
    make_option(c("-s", "--column_series"), type="character", default="",
        help="Column series. Default=%default"),
    make_option(c("-f", "--format"), type="character", default="pdf",
        help="Output format. Default=%default"),
    make_option(c("-r", "--rate"), type="character", default="acc",
        help="Method to plot. Default=%default"),
    make_option(c("-T", "--tag_order"), type="character", default=NULL,
        help="Order of the labels used with the predictions. Default=%default"),
    make_option(c("-L", "--no_legend"), action="store_true", default=FALSE,
        help="Remove legend"),
    make_option(c("-C", "--no_compact"), action="store_false", default=TRUE,
        help="Generate a plot for each data serie"),
    make_option(c("-x", "--xlimit"), type="character", default="0.0, 1.0",
        help="Min,max limits on x axis. Default=%default"),
    make_option(c("-y", "--ylimit"), type="character", default="0.0, 1.0",
        help="Min,max limits on y axis. Default=%default"),
    make_option(c("-c", "--clusters"), type="character", default=NULL,
        help="Tag each file with a factor. Set as string comma separated. Default=%default"),
    make_option(c("-t", "--column_tags"), type="character", default="",
        help="Column tags. Default=%default")
)
opt <- parse_args(OptionParser(option_list=option_list))


series <- unlist(strsplit(opt$column_series, ','))
files <- unlist(strsplit(opt$input, ','))
xlimit <- eval(parse(text=paste('c(', opt$xlimit, ')')))
ylimit <- eval(parse(text=paste('c(', opt$ylimit, ')')))
label_order <- NULL
if(!is.null(opt$tag_order)){
	label_order <- strsplit(opt$tag_order, ',')[[1]]
}
if(length(files) == 1){ 
	active_data <- get_data(files)
	if(opt$method == 'ROC' | opt$method == 'prec_rec'){
	    drawing_ROC_curves(active_data, opt$column_tags, series, opt$output_file, opt$method, xlimit, ylimit, opt$format, label_order)
	}else if(opt$method == 'cut'){
	    drawing_cutoff_curves(active_data, opt$column_tags, series, opt$output_file, opt$rate, xlimit, ylimit, opt$format)
	}
}else{
    clusters <- NULL
    if(!is.null(opt$clusters)){
      clusters <- unlist(strsplit(opt$clusters, ','))
    }
    drawing_ROC_curves_by_files(files, opt$column_tags, series, opt$output_file, opt$method, xlimit, ylimit, opt$format, label_order, clusters, opt$no_legend, opt$no_compact)
}

