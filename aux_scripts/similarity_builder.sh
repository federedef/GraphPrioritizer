#!/usr/bin/env bash

net_id=$1
ont_id=$2
exec_mode=$3
simil_code=$4
filter_factor=$5
input_path=/mnt/home/users/bio_267_uma/federogc/projects/backupgenes #TODO: Put this not harcoded.
result_path=`pwd`

nets_path=$input_path/input_processed
obos_path=$input_path/input_processed/obos


if [ "$exec_mode" == "ontology" ] ; then
	semtools.rb -i $nets_path/$1 -o ./results.txt -O $obos_path/$ont_id -s lin -S "," # -k "HP:" Return linn similitud by pairs. 
	awk 'BEGIN{FS="\t";OFS="\t"}{if( $1 == $2 ) $3="0"; print $1,$2,$3}' ${net_id}_semantic_similarity_list > semantic_similarity_list # State diagonal values to 0.
elif [ "$exec_mode" == "network" ] ; then 

	if [ "$simil_code" = "-" ] ; then 
		cp $nets_path/$1 $result_path/${net_id}_semantic_similarity_list
	else
		NetAnalyzer.rb -i $nets_path/$1 -a "${net_id}_semantic_similarity_list" $simil_code # Put output as semantic_similarity_list
	fi
	
	awk 'BEGIN{FS="\t";OFS="\t"}{if( $1 == $2 ) $3="0"; print $1,$2,$3}' ${net_id}_semantic_similarity_list > semantic_similarity_list # State diagonal values to 0.
fi


# NetAnalyzer.rb -i network.txt -l 'hpo,HP:;patients,[0-9]' -m hypergeometric -u 'hpo;patients' -a 'associations_file.txt'
# TODO: Need to select just the gene-gene pathway that share at least 5... El hypergeometric no nos sirve, necesitamos otro sistema que parta del numero absoluto de redes compartidas.
