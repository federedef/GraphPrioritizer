#!/usr/bin/env bash

net_id=$1
ont_id=$2
exec_mode=$3
simil_code=$4
filter_factor=$5

nets_path=$input_path/input_processed
obos_path=$input_path/input_processed/obos

if [ "$exec_mode" == "ontology" ] ; then
	semtools.rb -i $nets_path/$1 -o ./results.txt -O obos_path/$ont_id $simil_code #-s lin -S "," -T "$parent_id" # -k "HP:" Return linn similitud by pairs. 
	awk 'BEGIN{FS="\t";OFS="\t"}{if( $1 == $2 ) $3="0"; print $1,$2,$3}' ${net_id}_semantic_similarity_list > semantic_similarity_list # State diagonal values to 0.
elif [ "$exec_mode" == "network" ] ; then 
	NetAnalyzer.rb -i $nets_path/$1 -f pair -l 'genes:' $simil_code # Put output as semantic_similarity_list
	awk 'BEGIN{FS="\t";OFS="\t"}{if( $1 == $2 ) $3="0"; print $1,$2,$3}' ${net_id}_semantic_similarity_list > semantic_similarity_list # State diagonal values to 0.
fi

text2binary_matrix.rb -i semantic_similarity_list -o semantic_matrix_bin -t pair -s > similarity_metrics # Obtain statistical metrics and pass to matrix bien.

if [ "filter_factor" == "F" ] ; then
	disparity_filter.R -i semantic_matrix_bin -o "./"
fi