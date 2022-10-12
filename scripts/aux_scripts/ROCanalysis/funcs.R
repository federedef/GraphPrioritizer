#! /usr/bin/env Rscript


get_data <- function(file, sep = "\t", quote = "", header = TRUE, stringsAsFactors = TRUE, comment.char = "", complete = TRUE){
#' Method used to load a table from a file and remove not complete entries
#'
#' @param file to be loaded
#' @param sep separator used into file
#' @param quote character used as quotes into file
#' @param header used to indicate if file has a header or not
#' @param strirngsAsFactors used to indicate if strings must be stored as factors or not
#' @param comment.char character used as comment flag into file
#' @param complete if TRUE, only complete cases will be returned
#' @return the laoded and filtered data contained into given file
#' @author refactored by Fernando Moreno Jabato \email{jabato@uma.es}. Original author Pedro Seoane Zonjic
    # Load raw data
    raw <- read.table(file   = file, 
                      sep    = sep,
                      header = header, 
                      comment.char = comment.char, 
                      stringsAsFactors = stringsAsFactors)

    # Check complete cases
    if(complete){
        return(raw[complete.cases(raw),])
    }

    # Return loaded data
    return(raw)
}



get_best_thresold <- function(perf,echo = FALSE, prec_rec = FALSE){
#' Calculate the best threeshold for a given performance and write it as a text in the output channel
#' 
#' @param perf performance object from ROCR package
#' @author Pedro Seoane Zonjic
    accuracy <- unlist(slot(perf, "y.values"))
    thresolds <- unlist(slot(perf, "x.values"))
    if(!prec_rec){
        max_ac <- max(accuracy)        
    }else{
        max_ac <- min(accuracy)
    }
    best_thresold <- max(thresolds[which(accuracy %in% max_ac)])
    if(echo){
        print(best_thresold)        
    }
    return(best_thresold)
}




drawing_ROC_curves <- function(file, tags, series, series_names = NULL, graphname, method, xlimit, ylimit, format, label_order = NULL, compact_graph = TRUE, legend = TRUE, cutOff = FALSE, rate, legendPos = NULL, exportMeasures = FALSE){
#' Generate ROC curves from a dataframe given and render it out into a file
#'
#' @param file file with predictions and success values
#' @param tags Success values column indexes (number and/or numeric values)
#' @param series Prediction column indexes (number and/or numeric values)
#' @param series_names Prediction column names to be plotted
#' @param graphname output file basename (extension is added automatically)
#' @param method graph type. Allowed: 'ROC' and 'prec_rec'
#' @param xlimit graph X-axis limits
#' @param ylimit graph Y-axis limits
#' @param format output format. Allowed: 'pdf','png'
#' @param label_order Prediction column names
#' @param compact_graph if TRUE, all lines will be plotted in the same graph
#' @param legend show, or not, the legend
#' @param cutOff if TRUE, cutoff curves are plotted and RATE measure is used
#' @param rate measure to plot. ONLY USED when cutOff is true
#' @param legendPos position of legend. If NULL, defualt will be used. Allowed: bottomright, bottomleft, topright, topleft
#' @param exportMeasures flag to export emasures
#' @import ROCR and zoo packages
#' @importFrom ROCR prediction performance
#' @author refactored by Fernando Moreno Jabato \email{jabato@uma.es}. Original author Pedro Seoane Zonjic

    # Load necessary packages
    require(ROCR)

    # Prepare plots values to be calculated
    # FRED <- HACER UN FUNCIÓN EXTERNA CON ESTE CACHO DE CÓDIGO.
	if(method == 'ROC'){
		x_axis_measure="fpr"
		y_axis_measure="tpr"
        if(is.null(legendPos)){
            legend_position="bottomright"
        }else{
            legend_position=legendPos
        }
	}else if(method == 'prec_rec'){
		x_axis_measure="rec"
		y_axis_measure="prec"
        if(is.null(legendPos)){
            legend_position="bottomleft"
        }else{
            legend_position=legendPos
        }
	}else if(method == 'cut'){
        if(is.null(legendPos)){
            legend_position="bottomleft"
        }else{
            legend_position=legendPos
        }
    }else{
        stop(paste("Method not allowed: ", method, sep = ""))        
    }

    # Prepare output graphs
    if(format=='pdf'){
	    pdf(paste(graphname,".pdf", sep = ""))
    }else if(format=='png'){
	    png(paste(graphname,".png", sep = ""))
    }else{
        stop("Export format not allowed")
    }

    # Prepare plot data
	colors <- c('red', 'blue', 'green', 'orange', 'black', 'magenta', 'yellow', 'cyan', 'darkgray')
  
    # Prepare legend container
    legend_tag <- c()

    # Prepare measures to be exported
    if(exportMeasures){
        measures_df <- data.frame(Serie = character(), Measure = character(), Value = numeric(), stringsAsFactors = FALSE)      
    }
    for(i in seq_along(file)){
        # Load file
        table <- get_data(file[i])
        # Obtain prediction values
        tag <- if(length(tags)>1) tags[[i]] else{tags[[1]]}
        hits <- table[,tag]
        serie <- table[,series[[i]]]

 	# Prepare set
        serie <- as.numeric(serie)
        
	# Create a prediction object
        if(is.null(label_order)){
            hits <- as.numeric(hits)
            pred <- prediction(serie, hits, label_order)
        }else{
            hits <- as.character(hits)
            pred <- prediction(serie, hits, unlist(strsplit(label_order[i],",")))
        }
        

        if(cutOff){ # Plot cutoff curves
            perf <- performance(pred, measure = rate)
            get_best_thresold(perf,echo=TRUE)
        }else{
            perf <- performance(pred, measure = y_axis_measure, x.measure =  x_axis_measure)
        }

        # Plot info
        plot(perf, add=(compact_graph & (i>1)), col=colors[i], xlim=xlimit, ylim=ylimit)

        # --> FRED: Esto podría añadirse como una funcion extrerna (?)
        # Prepare legend
        if(method == 'ROC'){
            AUC <- performance(pred, measure = "auc")
            AUC <- unlist(slot(AUC, 'y.values'))
            auc <- AUC
            legend_tag <- c(legend_tag, paste(series_names[[i]], '(AUC = ', round(AUC, 3),')', sep=''))
        }else if(method == 'prec_rec'){
            require(zoo)
            precission <- perf@y.values[[1]][-1]
            recall <- perf@x.values[[1]][-1]
            id <- order(recall)
            AUC <- sum(diff(recall[id])*rollmean(precission[id],2))
            prauc <- AUC
            legend_tag <- c(legend_tag, paste(series_names[[i]], '(AUC-PR = ', round(AUC, 3),')', sep=''))
        }else{
            legend_tag <- c(legend_tag, series_names[[i]])
        }

        # Calculare measures to export
        # FRED # Hacer una función para obtener un dataframe con todos los valores y resultados de las métricas.
        #######
        if(exportMeasures){
            # Find best f-measure value
            f_measures <- performance(pred, measure = 'f')
            best_f <- max(unlist(f_measures@y.values), na.rm = TRUE) 
            best_f_indx <- which(unlist(f_measures@y.values) == best_f)

            # Obtain target measures
            measures <- c("acc","tpr","tnr","fpr","fnr")
            measure_values <- unlist(lapply(measures,function(m){
                meas <- performance(pred, measure = m)
                unlist(slot(meas, 'y.values'))[best_f_indx]
            }))

            measure_references <- rep("Max f-measure",length(measures))

            # Add f-measure
            measures <- c("f-measure", measures)
            measure_values <- c(best_f,measure_values)
            measure_references <- c("Max f-measure", measure_references)

            # Add X,y values
            measures <- c(measures,"x-val","y-val")
            measure_values <- c(measure_values,unlist(perf@x.values)[best_f_indx],unlist(perf@y.values)[best_f_indx])
            measure_references <- c(measure_references,"Max f-measure","Max f-measure")


            # AUC
            if(exists("auc")){
                measures <- c(measures,"auc")
                measure_values <- c(measure_values,auc)
                measure_references <- c(measure_references,"All")
            }
            # PR-AUC
            if(exists("prauc")){
                measures <- c(measures,"prauc")
                measure_values <- c(measure_values,prauc)
                measure_references <- c(measure_references,"All")
            }


            # Create DF and concat
            res <- data.frame(Serie = rep(series_names[[i]],length(measures)),
                              Reference = measure_references,
                              Measure = measures,
                              Value = measure_values,
                              stringsAsFactors = FALSE)
            measures_df <- rbind(measures_df,res)
        }
        # FRED 
        ########
    } # END i FOR

    # Add legend and render final image
    if(legend){
        legend(legend_position, legend=legend_tag, col=colors, lwd=2)                      
    }
    dev.off()    

    # Export measures
    if(exportMeasures){
        # Export target measures
        write.table(measures_df,file = paste(graphname,"_measures", sep = ""), col.names = TRUE, row.names = FALSE, sep = "\t", quote = FALSE)
    }
}


# qUIZÁS SERÍA INTERESANTE UNA FUNCIÓN QUE ORQUESTE LAS DEMÁS, POR ESA PARTE.