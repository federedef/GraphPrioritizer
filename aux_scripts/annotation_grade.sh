#!/usr/bin/env bash

gens_seed=$1
report_folder=$2
net2custom=$3
annotations=$4
data_annotation=$5

genes_iterator=`cat $gens_seed | tr "\n" "\t"`

for gene in ${genes_iterator} ; do 
	
	for annotation in annotations ; do
		ont_id=`grep -P '^$annotation' $net2custom | cut -f 2`
		if [ $ont_id == "ontology" ] ; do 
			grep $gene $data_annotation/$annotation | cut -f 2 | tr "," "\n" | wc -l 

		fi


done

if [ "$exec_mode" == "ontology" ] ; then
	genes_iterator=`cat $gens_seed | tr "\n" "\t"`
	for gene in genes_iterator ; do 
		grep -P '^$gene' 
	awk 'BEGIN{FS="\t";OFS="\t"}{if( $1 == $2 ) $3="0"; print $1,$2,$3}' ${net_id}_semantic_similarity_list > semantic_similarity_list # State diagonal values to 0.
elif [ "$exec_mode" == "network" ] ; then 

	if [ "$simil_code" = "-" ] ; then 
		cp $net_path/$1 $result_path/${net_id}_semantic_similarity_list
	else
		NetAnalyzer.rb -i $nets_path/$1 -a "${net_id}_semantic_similarity_list" $simil_code # Put output as semantic_similarity_list
	fi
	
	awk 'BEGIN{FS="\t";OFS="\t"}{if( $1 == $2 ) $3="0"; print $1,$2,$3}' ${net_id}_semantic_similarity_list > semantic_similarity_list # State diagonal values to 0.
fi
