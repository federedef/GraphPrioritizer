#!/usr/bin/env bash
. ~soft_bio_267/initializes/init_autoflow 
exec_mode=$1 # Modificar como Pepe lo tiene en su daemon aux_sh/trim_and_map.sh
add_opt=$2 # Un string que damos como segundo argumento.
input_path=`pwd`
export PATH=$input_path/aux_scripts:$PATH 

output_folder=$SCRATCH/executions/backupgenes
autoflow_output=$output_folder/exec
results_files=$output_folder/report
# Añadir el export para el path.


#Custom variables.
#ont=hp.obo
net="small_pro;small_pro_two" #;loquesea.paco;... gen_phen_mini; small_pro
kernel="ct;rf"
integration_types="mean;" #...;integration_mean_by_presence;...
net2ont=$input_path'/net2ont' 
gens_seed=$input_path'/gens_seed' #New

autoflow_vars=`echo " 
\\$nets=$net,
\\$kernel=$kernel,
\\$input_path=$input_path,
\\$integration_types=$integration_types,
\\$net2ont=$net2ont,
\\$gens_seed=$gens_seed
" | tr -d [:space:]`


if [ "$exec_mode" == "download" ] ; then
  #STAGE 1 DOWNLOADING REFERENCE
  pwd
elif [ "$exec_mode" == "autoflow" ] ; then
  #STAGE 2 AUTOFLOW EXECUTION
  AutoFlow -w autoflow_template.af -V $autoflow_vars -o $autoflow_output $add_opt 
elif [ "$exec_mode" == "check" ] ; then
  flow_logger -w -e $autoflow_output -r all
elif [ "$exec_mode" == "report" ] ; then 
  #STAGE 3 GENERATE REPORT fROM RESULTS
  source ~soft_bio_267/initializes/init_ruby
  mkdir $results_files
  echo $autoflow_output/uncomb_kernel_metrics
  create_metric_table.rb $autoflow_output/uncomb_kernel_metrics sample,net,kernel $results_files/parsed_uncomb_kmetrics
  create_metric_table.rb $autoflow_output/comb_kernel_metrics sample,integration,kernel $results_files/parsed_comb_kmetrics
  report_html -t report.erb -d $results_files/parsed_uncomb_kmetrics,$results_files/parsed_comb_kmetrics -o report_metrics
fi


