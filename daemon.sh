#!/usr/bin/env bash
. ~soft_bio_267/initializes/init_autoflow 

exec_mode=$1 
add_opt=$2 # flags to autoflow
input_path=`pwd`
export PATH=$input_path/aux_scripts:~soft_bio_267/programs/x86_64/scripts:$PATH

output_folder=$SCRATCH/executions/backupgenes
kernels_calc_af_exec=$output_folder/exec 
kernels_calc_af_report=$output_folder/report


#Custom variables.
net="phenotype;molecular_function;biological_process;cellular_component" #;loquesea.paco;... gen_phen_mini; small_pro
kernel="ct;rf"
integration_types="mean;" #...mean;integration_mean_by_presence;...
#net2ont=$input_path'/net2ont' 
net2custom=$input_path'/net2custom'
gens_seed=$input_path'/gens_seed' # What are the knocked genes?

autoflow_vars=`echo " 
\\$nets=$net,
\\$kernel=$kernel,
\\$input_path=$input_path,
\\$integration_types=$integration_types,
\\$net2custom=$net2custom,
\\$gens_seed=$gens_seed
" | tr -d [:space:]`


if [ "$exec_mode" == "download" ] ; then
  #STAGE 1 DOWNLOADING REFERENCE
  . ~soft_bio_267/initializes/init_R
  . ~soft_bio_267/initializes/init_ruby

  #Pass raw downloaded files.
  if [ -s ./data_downloaded/aux ] ; then
    echo "removing pre-existed obos files"
    find ./data_downloaded/aux -name "*.obo*" -delete 
  fi

  #Downloading ontologies and annotation files.
  downloader.rb -i ./input_source/source_data -o ./data_downloaded
  mkdir -p ./input_raw
  cp ./data_downloaded/raw/monarch/tsv/all_associations/* ./input_raw

  #Process the files
  mkdir -p ./input_processed
  #Warning: Truncate "| head -n 100" when trying.
  #aggregate_column_data.rb -i - -x 0 -a 4 | head -n 101 
  zgrep 'HP:' input_raw/gene_phenotype.all.tsv.gz | grep 'NCBITaxon:9606' | grep "HGNC:" | aggregate_column_data.rb -i - -x 0 -a 4 | head -n 101  > input_processed/phenotype 
  zgrep 'MONDO:' input_raw/gene_disease.all.tsv.gz | grep 'NCBITaxon:9606' | grep "HGNC:" | aggregate_column_data.rb -i - -x 0 -a 4 | head -n 101  > input_processed/disease
  zgrep 'GO:' input_raw/gene_function.all.tsv.gz | grep 'NCBITaxon:9606' | grep "HGNC:" | aggregate_column_data.rb -i - -x 0 -a 4 | head -n 101  > input_processed/function
  # TODO: The next addition have to be checked.
  zgrep "REACT:" input_raw/gene_pathway.all.tsv.gz |  grep 'NCBITaxon:9606' | grep "HGNC:" | cut -f 1,5 > input_processed/pathway # | head -n 100
  zgrep "RO:0002434" input_raw/gene_interaction.all.tsv.gz | grep 'NCBITaxon:9606' | awk 'BEGIN{FS="\t";OFS="\t"}{if( $1 ~ /HGNC:/ && $5 ~ /HGNC:/) print $1,$5}' > input_processed/interaction #| head -n 100 
  # RO:0002434 <=> interacts with

  #mkdir -p ./input_processed/obos
  #mv ./data_downloaded/aux/* ./input_processed/obos

  # Creating paco files for each go branch.
  cp input_processed/function input_processed/molecular_function
  cp input_processed/function input_processed/cellular_component
  cp input_processed/function input_processed/biological_process
  rm input_processed/function

elif [ "$exec_mode" == "kernels" ] ; then
  #STAGE 2 AUTOFLOW EXECUTION
  AutoFlow -w kernels_calc.af -V $autoflow_vars -o $kernels_calc_af_exec $add_opt 

elif [ "$exec_mode" == "backups" ] ; then
  #STAGE 2 AUTOFLOW EXECUTION
  AutoFlow -w autoflow_template.af -V $autoflow_vars -o $autoflow_output $add_opt 

elif [ "$exec_mode" == "check" ] ; then
  #STAGE 3 CHECK EXECUTION
  flow_logger -w -e $kernels_calc_af_exec -r all

elif [ "$exec_mode" == "report" ] ; then 
  source ~soft_bio_267/initializes/init_ruby

  #STAGE 4.1 RECOLLECT CANDIDATES LIST fROM RESULTS
  mkdir -p report 
  mkdir -p report/correlations
  mkdir -p report/metrics
  cp ${kernels_calc_af_exec}/correlate_matrices.R_*/*_correlation.png ./report/correlations

  #mkdir -p candidates
  #rsync -a --delete $results_files/candidates/ ./candidates/
  #STAGE 4.2 GENERATE REPORT fROM RESULTS

  # Profile metrics
  create_metric_table.rb $kernels_calc_af_exec/annotations_metrics Net ./report/metrics/parsed_annotations_metrics
  #awk -i inplace -v nets=$net 'BEGIN {split(nets, N, ";")}{if( NR == 1 ) print $0; for (net in N) if($1 == N[net]) print $0}' $results_files/parsed_annotations_metrics
  # Similarity metrics
  create_metric_table.rb $kernels_calc_af_exec/similarity_metrics Net ./report/metrics/parsed_similarity_metrics
  #awk -i inplace -v nets=$net 'BEGIN {split(nets, N, ";")}{if( NR == 1 ) print $0; for (net in N) if($1 == N[net]) print $0}' ./report/metrics/parsed_similarity_metrics
  # Uncomb Kernel metrics.
  create_metric_table.rb $kernels_calc_af_exec/uncomb_kernel_metrics Sample,Net,Kernel ./report/metrics/parsed_uncomb_kmetrics
  awk -i inplace -v nets=$net 'BEGIN {split(nets, N, ";")}{if( NR == 1 ) print $0; for (net in N) if($2 == N[net] ) print $0}' ./report/metrics/parsed_uncomb_kmetrics
  # Comb Kernls.
  create_metric_table.rb $kernels_calc_af_exec/comb_kernel_metrics Sample,Integration,Kernel ./report/metrics/parsed_comb_kmetrics
  # Filtered similarity metrics
  if [ -s $kernels_calc_af_exec/filtered_metrics ] ; then
    create_metric_table.rb $kernels_calc_af_exec/filtered_metrics Net $results_files/parsed_filtered_metrics
    awk -i inplace -v nets=$net 'BEGIN {split(nets, N, ";")}{if( NR == 1 ) print $0; for (net in N) if($1 == N[net]) print $0}' $results_files/parsed_filtered_metrics
    report_html -t report.erb -d $results_files/parsed_uncomb_kmetrics,$results_files/parsed_comb_kmetrics,$results_files/parsed_similarity_metrics,$results_files/parsed_filtered_metrics -o report_metrics
  else 
    report_html -t report.erb -d ./report/metrics/parsed_annotations_metrics,./report/metrics/parsed_uncomb_kmetrics,./report/metrics/parsed_comb_kmetrics,./report/metrics/parsed_similarity_metrics -o report_metrics
  fi
  
fi


