#!/usr/bin/env bash
. ~soft_bio_267/initializes/init_autoflow 

exec_mode=$1 
add_opt=$2 # flags to autoflow
input_path=`pwd`
export PATH=$input_path/aux_scripts:~soft_bio_267/programs/x86_64/scripts:$PATH # To test
export PATH=/mnt/home/users/bio_267_uma/federogc/clin_db_manager/bin:$PATH # To incorporate in the download section.

output_folder=$SCRATCH/executions/backupgenes
autoflow_output=$output_folder/exec
results_files=$output_folder/report


#Custom variables.
net="gene2phenotype;gene2disease;gene2molecular_function;gene2biological_process;gene2cellular_sublocation" #"small_pro;small_pro_two" #;loquesea.paco;... gen_phen_mini; small_pro
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
  . ~soft_bio_267/initializes/init_R
  . ~soft_bio_267/initializes/init_ruby

  # PASS RAW DOWNLOADED FILES.

  if [ -s ./data_downloaded/aux ] ; then
    echo "removing pre-existed obos files"
    find ./data_downloaded/aux -name "*.obo*" -delete 
  fi

  # Descarga de ontologías.
  downloader.rb -i ./input_source/source_data -o ./data_downloaded
  cp -r ./data_downloaded/raw/monarch/tsv/all_associations ./input_raw

  # PROCESS THE FILES.
  if [ ! -s ./input_processed ] ; then
    mkdir ./input_processed
  fi

  #TODO: Quitar el head cuando probemos

  zgrep 'HP:' input_raw/gene_phenotype.all.tsv.gz | grep 'NCBITaxon:9606' | grep "HGNC:" | aggregate_column_data.rb -i - -x 0 -a 4 | head -n 100 > input_processed/gene2phenotype 
  zgrep 'MONDO:' input_raw/gene_disease.all.tsv.gz | grep 'NCBITaxon:9606' | grep "HGNC:" | aggregate_column_data.rb -i - -x 0 -a 4 | head -n 100 > input_processed/gene2disease
  zgrep 'GO:' input_raw/gene_function.all.tsv.gz | grep 'NCBITaxon:9606' | grep "HGNC:" | aggregate_column_data.rb -i - -x 0 -a 4 | head -n 100 > input_processed/gene2function
  cp -r ./data_downloaded/aux ./input_processed/

  if [ -s ./input_processed/obos ] ; then
    echo "removing pre-existed obos folder"
    rm -r ./input_processed/obos
  fi

  mv ./input_processed/aux ./input_processed/obos

  cp input_processed/gene2function input_processed/gene2molecular_function
  cp input_processed/gene2function input_processed/gene2cellular_sublocation
  cp input_processed/gene2function input_processed/gene2biological_process
  rm input_processed/gene2function

elif [ "$exec_mode" == "autoflow" ] ; then
  #STAGE 2 AUTOFLOW EXECUTION
  AutoFlow -w autoflow_template.af -V $autoflow_vars -o $autoflow_output $add_opt 

elif [ "$exec_mode" == "check" ] ; then
  #STAGE 3 CHECK EXECUTION
  flow_logger -w -e $autoflow_output -r all

elif [ "$exec_mode" == "report" ] ; then 
  #STAGE 4 GENERATE REPORT fROM RESULTS
  source ~soft_bio_267/initializes/init_ruby
  
  if [ ! -s ./correlations ] ; then 
    mkdir ./correlations
  fi

  cp -r $results_files/uncomb_corr ./correlations/
  cp $results_files/int_kern_correlation.png ./correlations/int_kern_correlation.png
  
  create_metric_table.rb $autoflow_output/similarity_metrics Net $results_files/parsed_similarity_metrics
  create_metric_table.rb $autoflow_output/uncomb_kernel_metrics Sample,Net,Kernel $results_files/parsed_uncomb_kmetrics
  create_metric_table.rb $autoflow_output/comb_kernel_metrics Sample,Integration,Kernel $results_files/parsed_comb_kmetrics
  report_html -t report.erb -d $results_files/parsed_uncomb_kmetrics,$results_files/parsed_comb_kmetrics,$results_files/parsed_similarity_metrics -o report_metrics
fi


