#!/usr/bin/env bash
. ~soft_bio_267/initializes/init_autoflow 

exec_mode=$1 
add_opt=$2 # flags to autoflow
input_path=`pwd`
export PATH=$input_path/aux_scripts:~soft_bio_267/programs/x86_64/scripts:$PATH # To test

output_folder=$SCRATCH/executions/backupgenes
autoflow_output=$output_folder/exec
results_files=$output_folder/report



#Custom variables.
net="small_pro;small_pro_two" #;loquesea.paco;... gen_phen_mini; small_pro
kernel="ct;rf"
integration_types="mean;" #...;integration_mean_by_presence;...
net2ont=$input_path'/net2ont' 
gens_seed=$input_path'/gens_seed' # What are the knocked genes?

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

  if [ ! -s $results_files ] ; then
    mkdir $results_files
  fi

  if [ ! -s ./matrices_correlation.pdf ] ; then
    cp $results_files/matrices_correlation.pdf matrices_correlation.pdf
  fi

  #echo $autoflow_output/uncomb_kernel_metrics
  create_metric_table.rb $autoflow_output/similarity_metrics Net $results_files/parsed_similarity_metrics
  create_metric_table.rb $autoflow_output/uncomb_kernel_metrics Sample,Net,Kernel $results_files/parsed_uncomb_kmetrics
  create_metric_table.rb $autoflow_output/comb_kernel_metrics Sample,Integration,Kernel $results_files/parsed_comb_kmetrics
  report_html -t report.erb -d $results_files/parsed_uncomb_kmetrics,$results_files/parsed_comb_kmetrics,$results_files/parsed_similarity_metrics -o report_metrics
fi


