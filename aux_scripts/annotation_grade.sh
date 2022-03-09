#!/usr/bin/env bash

gens_seed=$1
output_folder=$2
net2custom=$3
annotations=$4
path_annotations=$5

genes_iterator=`cat $gens_seed | tr "\n" "\t"`

if [ -s $2/annotation_grade_metrics ] ; then
	rm $2/annotation_grade_metrics
fi

for gene in ${genes_iterator} ; do 
	for annotation in $annotations ; do
		ont_id=`grep -P "^${annotation}" $net2custom | cut -f 3`
		echo ${ont_id}
		if [ $ont_id == "ontology" ] ; then
			number_annotations=`grep $gene $path_annotations/$annotation | cut -f 2 | tr "," "\n" | wc -l` 
			echo -e "$gene\t$annotation\t${number_annotations}" >> $2/annotation_grade_metrics
		elif [ $ont_id == "-" ] ; then
			number_annotations=`cut -f 1 $path_annotations/$annotation | grep $gene | wc -l` 
			echo -e "$gene\t$annotation\t${number_annotations}" >> $2/annotation_grade_metrics
		fi
	done
done
