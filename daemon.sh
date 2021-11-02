#!/usr/bin/env bash
. ~soft_bio_267/initializes/init_autoflow 
exec_mode=$1 # Modificar como Pepe lo tiene en su daemon aux_sh/trim_and_map.sh
add_opt=$2 # Un string que damos como segundo argumento.
export annotations_files_folder=$SCRATCH/executions/backupgenes
export results_files=/mnt/home/users/bio_267_uma/federogc/projects/backupgenes/report


#Custom variables.
#ont=hp.obo
net="small_pro;small_pro_two" #;loquesea.paco;... gen_phen_mini; small_pro
kernel="ct;rf"
input_path=`pwd`
net2ont=$input_path'/net2ont' 

autoflow_vars=`echo " 
\\$nets=$net,
\\$kernel=$kernel,
\\$input_path=$input_path,
\\$net2ont=$net2ont
" | tr -d [:space:]`

if [ "$exec_mode" == "download" ] ; then
  #STAGE 1 DOWNLOADING REFERENCE
  pwd
elif [ "$exec_mode" == "autoflow" ] ; then
  #STAGE 2 AUTOFLOW EXECUTION
  AutoFlow -w autoflow_template.af -V $autoflow_vars -o $annotations_files_folder/exec $add_opt 
elif [ "$exec_mode" == "check" ] ; then
  flow_logger -w -e $annotations_files_folder/exec -r all
elif [ "$exec_mode" == "report" ] ; then 
  #STAGE 3 GENERATE REPORT fROM RESULTS
  pwd
fi


