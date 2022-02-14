#!/usr/bin/env bash
. ~soft_bio_267/initializes/init_autoflow 

exec_mode=$1 
add_opt=$2 # flags to autoflow
input_path=`pwd`
export PATH=$input_path/aux_scripts:~soft_bio_267/programs/x86_64/scripts:$PATH # To test
#export PATH=/mnt/home/users/bio_267_uma/federogc/clin_db_manager/bin:$PATH 

output_folder=$SCRATCH/executions/backupgenes
autoflow_output=$output_folder/exec
results_files=$output_folder/report


#Custom variables.
net="gene2phenotype;gene2molecular_function;" #;gene2molecular_function;gene2biological_process;gene2cellular_sublocation" "small_pro;small_pro_two" #;loquesea.paco;... gen_phen_mini; small_pro
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
  zgrep 'HP:' input_raw/gene_phenotype.all.tsv.gz | grep 'NCBITaxon:9606' | grep "HGNC:" | aggregate_column_data.rb -i - -x 0 -a 4 > input_processed/gene2phenotype 
  zgrep 'MONDO:' input_raw/gene_disease.all.tsv.gz | grep 'NCBITaxon:9606' | grep "HGNC:" | aggregate_column_data.rb -i - -x 0 -a 4 | head -n 100 > input_processed/gene2disease
  zgrep 'GO:' input_raw/gene_function.all.tsv.gz | grep 'NCBITaxon:9606' | grep "HGNC:" | aggregate_column_data.rb -i - -x 0 -a 4 > input_processed/gene2function
  # TODO: The next addition have to be checked.
  zgrep "REACT:" input_raw/gene_pathway.all.tsv.gz |  grep 'NCBITaxon:9606' | grep "HGNC:" | cut -f 1,5 | head -n 100 > input_processed/gene2pathway
  zgrep "RO:0002434" input_raw/gene_interaction.all.tsv.gz | grep 'NCBITaxon:9606' | awk 'BEGIN{FS="\t";OFS="\t"}{if( $1 ~ /HGNC:/ && $5 ~ /HGNC:/) print $1,$5}' | head -n 100 > input_processed/gene2interaction 
  # RO:0002434 <=> interacts with

  mkdir -p ./input_processed/obos
  mv ./data_downloaded/aux/* ./input_processed/obos

  # Creating paco files for each go branch.
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
  source ~soft_bio_267/initializes/init_ruby

  #STAGE 4.1 RECOLLECT CANDIDATES LIST fROM RESULTS
  
  cp -r $results_files/candidates ./

  #STAGE 4.2 GENERATE REPORT fROM RESULTS

  # Recollect the matrix correlactions png's.
  if [ ! -s ./correlations ] ; then 
    mkdir ./correlations
  elif [ -s ./correlations ] ; then
    rm -r ./correlations
    mkdir ./correlations
  fi
  # Folder that just save files for the report.
  cp -r $results_files/uncomb_corr ./correlations/
  cp $results_files/*correlation.png ./correlations/
  # Folder that save all the correlations generated in all the sessions.
  mkdir -p all_correlations
  cp ./correlations/*_correlation.png ./all_correlations
  cp ./correlations/uncomb_corr/* ./all_correlations

  # Similarity metrics
  create_metric_table.rb $autoflow_output/similarity_metrics Net $results_files/parsed_similarity_metrics
  awk -i inplace -v nets=$net 'BEGIN {split(nets, N, ";")}{if( NR == 1 ) print $0; for (net in N) if($1 == N[net]) print $0}' $results_files/parsed_similarity_metrics
  # Uncomb Kernel metrics.
  create_metric_table.rb $autoflow_output/uncomb_kernel_metrics Sample,Net,Kernel $results_files/parsed_uncomb_kmetrics
  awk -i inplace -v nets=$net 'BEGIN {split(nets, N, ";")}{if( NR == 1 ) print $0; for (net in N) if($2 == N[net] ) print $0}' $results_files/parsed_uncomb_kmetrics
  # Comb Kernls.
  create_metric_table.rb $autoflow_output/comb_kernel_metrics Sample,Integration,Kernel $results_files/parsed_comb_kmetrics
  # Filtered similarity metrics
  if [ -s $autoflow_output/filtered_metrics ] ; then
    create_metric_table.rb $autoflow_output/filtered_metrics Net $results_files/parsed_filtered_metrics
    awk -i inplace -v nets=$net 'BEGIN {split(nets, N, ";")}{if( NR == 1 ) print $0; for (net in N) if($1 == N[net]) print $0}' $results_files/parsed_filtered_metrics
    report_html -t report.erb -d $results_files/parsed_uncomb_kmetrics,$results_files/parsed_comb_kmetrics,$results_files/parsed_similarity_metrics,$results_files/parsed_filtered_metrics -o report_metrics
  else 
    report_html -t report.erb -d $results_files/parsed_uncomb_kmetrics,$results_files/parsed_comb_kmetrics,$results_files/parsed_similarity_metrics -o report_metrics
  fi
  
fi


