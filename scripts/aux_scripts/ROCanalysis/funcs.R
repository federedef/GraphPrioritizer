#!/usr/bin/env Rscript

get_data <- function(file, tag_column=1, serie_column=2, sep = "\t", quote = "", header = TRUE, stringsAsFactors = TRUE, comment.char = "", complete = TRUE){
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
    # Filter raw
    raw <- raw[,c(tag_column,serie_column)]
    raw[,1] <- as.numeric(raw[,1])
    raw[,2] <- as.numeric(raw[,2])
    # Check complete cases
    if(complete){
        return(raw[complete.cases(raw),])
    }
    # Return loaded data
    return(raw)
}


collect_data <- function(file_paths, tags, series, series_names) {
    collected_data <- list()

    if (length(file_paths) == 1) {
        for (serie in series) {
            df <- get_data(file_paths[1],tag_column=tags[1],serie_column=serie)
            collected_data <- c(collected_data,list(df))
        }
    } else {
        for(i in seq_along(file_paths)){
            df <- get_data(file_paths[i],tag_column=tags[i],serie_column=series[i])
            collected_data <- c(collected_data,list(df))
        }
    }
    names(collected_data) <- series_names

    return(collected_data)
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

drawing_ROC_curves <- function(data, graphname, method, xlimit, ylimit, 
    format, compact_graph = TRUE, legend = TRUE, cutOff = FALSE, rate, legendPos = NULL, n_bootstrap = NULL, stratified=TRUE){
    # Load necessary packages
    require(ROCR)
    require(fbroc)
    # Prepare plots values to be calculated
    plot_setup <- build_plot_setup(method, legendPos)

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
    
    for(i in 1:length(data)){ 
        serie_name <- names(data)[i]

        if (!is.numeric(n_bootstrap)){
            graph <- get_graph_from_rocr(data=data[[i]], measure = plot_setup$y_axis_measure, 
                x.measure = plot_setup$x_axis_measure, cutOff=cutOff, rate=rate)
            plot(graph$perf, add=(compact_graph & (i>1)), col=colors[i], xlim=xlimit, ylim=ylimit)
        }else if (method != "ROC"){
            stop("Bootstrap not allowed for this method")
        }else{
            graph <- get_graph_from_fbroc(data=data[[i]], n_bootstrap=n_bootstrap, stratified=stratified)

            if (compact_graph & (i>1)){
                lines(graph$xvalues, graph$yvalues, col=colors[i])
            }else{
                plot(graph$xvalues, graph$yvalues, col=colors[i], xlim=xlimit, ylim=ylimit, 
                    type= "l", xlab= "False positive rate", ylab="True positive pate")
            }
        }

        # Prepare legend
        if(method == 'ROC' || method == 'prec_rec'){
            auc <- get_auc(x_values=graph$xvalues, y_values= graph$yvalues)
            legend_tag <- c(legend_tag, paste(serie_name, '(AUC = ', round(auc, 3),')', sep=''))
        }else{
            legend_tag <- c(legend_tag, serie_name)
        }
    }
    # Add legend and render final image
    if(legend){
        legend(plot_setup$legend_position, legend=legend_tag, col=colors, lwd=2)                      
    }
    dev.off()    
}

get_graph_from_rocr <- function(data, measure, x.measure, cutOff, rate){
    pred <- build_pred_object(data)

    if(cutOff){ # Plot cutoff curves
        perf <- performance(pred, measure = rate)
        get_best_thresold(perf,echo=TRUE)
    }else{
        perf <- performance(pred, measure = measure, x.measure =  x.measure)
    }

    graph <- list(perf = perf, xvalues=perf@x.values[[1]][-1], yvalues=perf@y.values[[1]][-1])
    return(graph)
}

get_graph_from_fbroc <- function(data,n_bootstrap,stratified){
    hits <- as.logical(data[,1])
    serie <- as.numeric(data[,2])
    bootstraped_roc <- boot.roc(serie, hits, stratify = stratified, n.boot=n_bootstrap)
    tpr <- bootstraped_roc$roc[,1]
    fpr <- bootstraped_roc$roc[,2]

    graph <- list(perf = bootstraped_roc, xvalues=fpr, yvalues=tpr)
    return(graph)
}


summarize_performance <- function(data, serie_name, measures=c("acc","tpr","tnr","fpr","fnr","auc","f","partial_auc"),
    n_bootstrap=NULL, stratified=TRUE, conf_level=0.95, pauc_range=NULL){
    # pauc_range is a vector as c(0.3,0.7)
    observed_measures_df <- get_summary_from_rocr(data, serie_name, measures=measures, method = "ROC")

    if(is.numeric(n_bootstrap)){ 
        fpr_fixed <- observed_measures_df$Value[which(observed_measures_df$Measure == 'fpr')]
        tpr_fixed <- observed_measures_df$Value[which(observed_measures_df$Measure == 'tpr')]
        inferenced_measures_df <- get_summary_from_fbroc(data, serie_name, measures=measures, conf_level=conf_level, 
            n_bootstrap=n_bootstrap, stratified=stratified, fpr_fixed=fpr_fixed, tpr_fixed=tpr_fixed, pauc_range=pauc_range)
        df_final <- rbind(inferenced_measures_df,observed_measures_df)
    }else{
        df_final <- observed_measures_df 
    }

    return(df_final)
}

get_summary_from_fbroc <- function(data, serie_name, measures, conf_level= 0.95, n_bootstrap=1000, stratified=TRUE, fpr_fixed=NULL, 
    tpr_fixed=NULL, pauc_range=c(0.1,0.7)){
    allowed_measures <- c("auc","partial.auc","fpr","tpr") 
    measures <- intersect(measures,allowed_measures)
    measures_df <- data.frame(Serie = c(),
                              Reference = c(),
                              Measure = c(),
                              Value = c(),
                              stringsAsFactors = FALSE)
    hits <- data[,1] == 1
    serie <- as.numeric(data[,2])
    bootstraped_roc <- boot.roc(serie, hits, stratify = stratified, n.boot=n_bootstrap)

    if (length(measures)>=1){
        calc_measures <- c()
        measure_values <- c()
        measure_references <- c()

        for (measure in measures) {
            fixed <- switch(measure,  
                    "auc"= list(fpr <- NULL, tpr <- NULL),  
                    "fpr"= list(fpr <- NULL, tpr <- tpr_fixed),  
                    "tpr"= list(fpr <- fpr_fixed, tpr <- NULL),  
                    "partial.auc"= list(fpr <- pauc_range, tpr <- NULL))
            fpr<- fixed$fpr_fixed
            tpr<- fixed$tpr_fixed

            inferenced_results <- perf(bootstraped_roc, measure, conf.level = conf_level, fpr = fpr_fixed, tpr = tpr_fixed)
            confidence_interval <- inferenced_results$CI.Performance

            calc_measures <- c(calc_measures,paste(measure,"down","ci",as.character(conf_level),sep="_"),
                paste(measure,"up","ci",as.character(conf_level),sep="_"))
            measure_values <- c(measure_values,confidence_interval)
            tag <- ifelse(measure %in% c("auc","partial.auc"),"All","max_f_measure")
            measure_references <- c(measure_references,rep(tag,2))
        }

        measures_df <- data.frame(Serie = rep(serie_name,length(calc_measures)),
                              Reference = measure_references,
                              Measure = calc_measures,
                              Value = measure_values,
                              stringsAsFactors = FALSE)
    }
    
    return(measures_df)

}

get_summary_from_rocr <- function(data, serie_name, measures=c("acc","tpr","tnr","fpr","fnr","auc","f"), method = NULL){
    require(ROCR)
    pred <- build_pred_object(data)
    
    f_measures <- performance(pred, measure = 'f')
    best_f <- max(unlist(f_measures@y.values), na.rm = TRUE) 
    filter_indxs <- which(unlist(f_measures@y.values) == best_f)

        # Obtain target measures
    measures_with_best_f <- measures[! measures %in% "auc"]
    measure_values <- unlist(lapply(measures_with_best_f,function(m){
        measure <- performance(pred, measure = m)
        unlist(slot(measure, 'y.values'))[filter_indxs]
    }))

    measure_references <- rep("max_f_measure",length(measures_with_best_f))

    if(method == 'ROC' || method == 'prec_rec'){
        if (method=="ROC"){perf <- performance(pred, measure = "tpr", x.measure =  "fpr")}
        if (method=='prec_rec'){perf <- performance(pred, measure = "prec", x.measure =  "rec")}
        
        auc <- get_auc(x_values=perf@x.values[[1]][-1], y_values= perf@y.values[[1]][-1])
        measures <- c(measures_with_best_f,"auc")
        measure_values <- c(measure_values,auc)
        measure_references <- c(measure_references,"All")
    }   
    
    measures_df <- data.frame(Serie = rep(serie_name,length(measures)),
                              Reference = measure_references,
                              Measure = measures,
                              Value = measure_values,
                              stringsAsFactors = FALSE)
    return(measures_df)

}

export_observed_measures <- function(data, serie_name, measures=c("acc","tpr","tnr","fpr","f")){
    # Extract all measures posible from ROCR.

    pred <- build_pred_object(data)
    n_cutoffs <- length(pred@cutoffs[[1]]) -1

    serie_name_df <- data.frame(Serie = rep(serie_name,n_cutoffs), cutoffs = pred@cutoffs[[1]][-1])
    measure_values_df <- as.data.frame(sapply(measures,function(m){
        measure <- performance(pred, measure = m)
        unlist(slot(measure, 'y.values'))
    }))
        
    measure_values_df <- measure_values_df[-1,]
    data_values <- cbind(serie_name_df,measure_values_df)

    return(data_values)
}


get_auc <- function(x_values,y_values){
    require(zoo)
    id <- order(x_values)
    AUC <- sum(diff(x_values[id])*rollmean(y_values[id],2))
    return(AUC)
}

build_pred_object <- function(data){
    require(ROCR)
    hits <- as.logical(data[,1])
    serie <- as.numeric(data[,2])

    pred <- prediction(serie, hits)

    return(pred)
}


build_plot_setup <- function(method, legendPos = NULL){
    if(method == 'ROC'){
        plot_setup <- list(x_axis_measure="fpr",y_axis_measure="tpr")
        if(is.null(legendPos)){
            plot_setup <- c(plot_setup, legend_position="bottomright")
        }else{
            plot_setup <- c(plot_setup, legend_position=legendPos)
        }
    }else if(method == 'prec_rec'){
        plot_setup <- list(x_axis_measure="rec",y_axis_measure="prec")
        if(is.null(legendPos)){
            plot_setup <- c(plot_setup, legend_position="bottomleft")
        }else{
            plot_setup <- c(plot_setup, legend_position=legendPos)
        }
    }else if(method == 'cut'){
        if(is.null(legendPos)){
            plot_setup <- list(legend_position="bottomleft")
        }else{
             plot_setup <- list(legend_position=legendPos)
        }
    }else{
        stop(paste("Method not allowed: ", method, sep = ""))        
    }
    return(plot_setup)
}

