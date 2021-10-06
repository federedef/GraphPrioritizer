#!/usr/bin/env bash
. ~soft_bio_267/initializes/init_autoflow 
exec_mode=$1 # Modificar como Pepe lo tiene en su daemon aux_sh/trim_and_map.sh
export annotations_files_folder=$SCRATCH/executions/backupgenes
export results_files=/mnt/home/users/bio_267_uma/federogc/projects/backupgenes/report
add_opt=$2 # Un string que damos como segundo argumento.

#Custom variables.
ont=hp.obo
net=gene_phen_filtered.paco;loquesea.paco;...
kernel=ct
input_path=././

autoflow_vars=`echo " 
\\$ont=$ont,
\\$nets=$net,
\\$kernel=$kernel,
\\$input_path=$input_path
" | tr -d [:space:]`

 if [ "$exec_mode" == "download" ] ; then
     #STAGE 1 DOWNLOADING REFERENCE 

elif [ "$exec_mode" == "autoflow" ] ; then
	#STAGE 2 AUTOFLOW EXECUTION
	AutoFlow -w autoflow_template.af -V $autoflow_vars -O annotations_files_folder $add_opt # Confirmar con Pepe
elif [ "$exec_mode" == "report" ] ; then 
	#STAGE 3 GENERATE REPORT fROM RESULTS
fi


