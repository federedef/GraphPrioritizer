#!/usr/bin/env bash

exec_mode=$1
export annotations_files_folder = $SCRATCH/executions/backupgenes

if [ "$exec_mode" == "download" ] ; then
    #STAGE 1 DOWNLOADING REFERENCE 

elif [ "$exec_mode" == "autoflow" ] ; then
	#STAGE 2 AUTOFLOW EXECUTION
	AutoFlow -w autoflow_template.af -V '$ont='hp.obo',$net='gene_phen_filtered.paco',$kernel='ct'' -O annotations_files_folder
elif [ "$exec_mode" == "report" ] ; then 
	#STAGE 3 GENERATE REPORT fROM RESULTS
fi

