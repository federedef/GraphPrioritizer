#!/usr/bin/env bash
. ~soft_bio_267/initializes/init_autoflow 

#Input variables.
exec_mode=$1 
add_opt=$2 

# Used Paths.
input_path=`pwd`
export PATH=$input_path/aux_scripts:~soft_bio_267/programs/x86_64/scripts:$PATH
autoflow_scripts=$input_path/autoflow_scripts
output_folder=$SCRATCH/executions/backupgenes
report_folder=$output_folder/report

# Custom variables.
annotations="disease phenotype molecular_function biological_process cellular_component protein_interaction_unweighted protein_interaction_weighted pathway genetic_interaction_unweighted genetic_interaction_weighted" # disease phenotype molecular_function biological_process cellular_component protein_interaction pathway genetic_interaction paper_coDep
kernels="ka ct el rf"
integration_types="mean integration_mean_by_presence"
net2custom=$input_path'/net2custom' 
control_gens=$input_path'/control_gens' # What are its backups?

kernels_varflow=`echo $kernels | tr " " ";"`

if [ "$exec_mode" == "download" ] ; then
  #########################################################
  # STAGE 1 DOWNLOAD DATA
  #########################################################
  . ~soft_bio_267/initializes/init_R
  . ~soft_bio_267/initializes/init_ruby

  # Pass raw downloaded files.
  if [ -s ./data_downloaded/aux ] ; then
    echo "removing pre-existed obos files"
    find ./data_downloaded/aux -name "*.obo*" -delete 
  fi

  # Downloading ONTOLOGIES and PATHWAY ANNOTATION files from MONARCH.
  downloader.rb -i ./input_source/source_data -o ./data_downloaded
  mkdir -p ./input_raw
  cp ./data_downloaded/raw/monarch/tsv/all_associations/* ./input_raw

  # Downloading PROTEIN INTERACTIONS and ALIASES from STRING.
  wget https://stringdb-static.org/download/protein.links.v11.5/9606.protein.links.v11.5.txt.gz -O input_raw/string_data.v11.5.txt.gz
  gzip -d input_raw/string_data.v11.5.txt.gz

  # Downloading GENETIC INTERACTIONS from DEPMAP.
  wget https://ndownloader.figshare.com/files/34008491 -O input_raw/CRISPR_gene_effect

  ############################
  ## Obtain TRANSLATOR TABLES.
  mkdir -p ./translators

  # Downloading Ensemble_HGNC from STRING.
  wget https://stringdb-static.org/download/protein.aliases.v11.5/9606.protein.aliases.v11.5.txt.gz -O ./translators/protein_aliases.v11.5.txt.gz
  gzip -d translators/protein_aliases.v11.5.txt.gz
  grep -w "Ensembl_HGNC_HGNC_ID" translators/protein_aliases.v11.5.txt | cut -f 1,2 > ./translators/Ensemble_HGNC
  rm ./translators/protein_aliases.v11.5.txt

  # Downloading HGNC_symbol
  wget http://ftp.ebi.ac.uk/pub/databases/genenames/hgnc/archive/monthly/tsv/hgnc_complete_set_2022-04-01.txt -O ./translators/HGNC_symbol
  awk '{OFS="\t"}{print $2,$1}' ./translators/HGNC_symbol > ./translators/symbol_HGNC
  rm ./translators/HGNC_symbol

elif [ "$exec_mode" == "process_download" ] ; then

  mkdir -p ./input_processed

  declare -A tag_filter 
  tag_filter[phenotype]='HP:'
  tag_filter[disease]='MONDO:'
  tag_filter[function]='GO:'
  tag_filter[pathway]='REACT:'
  tag_filter[interaction]='RO:0002434' # RO:0002434 <=> interacts with

  # PROCESS ONTOLOGIES #
  for sample in phenotype disease function ; do
    zgrep ${tag_filter[$sample]} input_raw/gene_${sample}.all.tsv.gz | grep 'NCBITaxon:9606' | grep "HGNC:" | \
    aggregate_column_data.rb -i - -x 0 -a 4 > input_processed/$sample # | head -n 230
  done

  ## Creating paco files for each go branch.
  gene_ontology=( molecular_function cellular_component biological_process )
  for branch in ${gene_ontology[@]} ; do
    cp input_processed/function input_processed/$branch
  done
  rm input_processed/function

  # PROCESS REACTIONS # | head -n 230 
  zgrep "REACT:" input_raw/gene_pathway.all.tsv.gz |  grep 'NCBITaxon:9606' | grep "HGNC:" | \
   cut -f 1,5 > input_processed/pathway
  
  # PROCESS PROTEIN INTERACTIONS # | head -n 200 
  cat input_raw/string_data.v11.5.txt | tr -s " " "\t" > string_data.v11.5.txt
  idconverter.rb -d ./translators/Ensemble_HGNC -i string_data.v11.5.txt -c 0,1 > ./input_raw/interaction_scored && rm string_data.v11.5.txt
  awk '{OFS="\t"}{if ( $3 > 700 ) {print $1,$2}}' ./input_raw/interaction_scored > ./input_processed/protein_interaction_unweighted # && rm ./input_raw/interaction_scored
  awk '{OFS="\t"}{if ( $3 > 700 ) {print $1,$2,$3}}' ./input_raw/interaction_scored > ./input_processed/protein_interaction_weighted

  # PROCESS GENETIC INTERACTIONS # | cut -f 1-100 | head -n 100
  sed 's/([0-9]*)//1g' ./input_raw/CRISPR_gene_effect | cut -d "," -f 2- | sed 's/,/\t/g' | sed 's/ //g' > ./input_raw/CRISPR_gene_effect_symbol
  idconverter.rb -d ./translators/symbol_HGNC -i ./input_raw/CRISPR_gene_effect_symbol -r 0 > ./input_processed/genetic_interaction_unweighted
  cp ./input_processed/genetic_interaction_unweighted ./input_processed/genetic_interaction_weighted
  rm ./input_raw/CRISPR_gene_effect_symbol

elif [ "$exec_mode" == "white_list" ] ; then

#########################################################
# OPTIONAL STAGE : SELECT GENES FROM WHITELIST
#########################################################

  cd input_processed
  filter_by_whitelist.rb -f phenotype,disease,biological_process,cellular_component,molecular_function,pathway,protein_interaction \
  -c "0;0;0;0;0;0;0,1" -t ../white_list/hgnc_white_list
  filter_by_whitelist.rb -f genetic_interaction -c "0;" -t ../white_list/hgnc_white_list -r

  echo -e "sample\tprefiltered_rows\tprefiltered_cols\tposfiltered_rows\tposfiltered_cols" > filter_metrics
  for sample in phenotype disease biological_process cellular_component molecular_function pathway protein_interaction genetic_interaction ; do
    nrows_prefiltered=`wc -l $sample | tr " " "\t" | cut -f1 `
    nrows_posfiltered=`wc -l filtered_$sample | tr " " "\t" | cut -f1 `
    ncols_prefiltered=`head -n 1 $sample | tr '\t' '\n' | wc -l`
    ncols_posfiltered=`head -n 1 filtered_$sample | tr '\t' '\n' | wc -l`
    echo -e "$sample\t$nrows_prefiltered\t$ncols_prefiltered\t$nrows_posfiltered\t$ncols_posfiltered" >> filter_metrics
    rm $sample
    mv filtered_$sample $sample
  done
  
  echo "Annotation files filtered"
  cd..

elif [ "$exec_mode" == "backup_preparation" ] ; then 
  source ~soft_bio_267/initializes/init_R
  
  mkdir -p ./backupgens/processed_backups 
  
  # POSITIVE CONTROL #
  # AdHoc added backups
  cp ./backupgens/data/AdHoc_Backups ./backupgens/processed_backups/AdHoc_Backups
  # Big Papi.
  grep -w 'All 6' ./backupgens/data/Big_Papi | awk '{FS="\t";OFS="\t"}{if ( $6 <= 0.05) print $1,$2}' > ./backupgens/data/filtered_Big_Papi
  # Digenic Paralog.
  awk '{FS="\t"}{if ( $2 <= 0.05 && $3 <= 0.05 && $4 <= 0.05 && $5 <= 0.05 && $6 <= 0.05 && $7 <= 0.05 && $8 <= 0.05 && $9 <= 0.05 && $10 <= 0.05 && $11 <= 0.05 && $12 <= 0.05) print $1}' ./backupgens/data/Digenic_Paralog | \
   tr -s ";" "\t" | tr -d "\"" > ./backupgens/data/filtered_Digenic_Paralog

  # Download the necessary tab to translation from symbol to HGNC.
  if [ ! -s ./translators/symbol_HGNC ] ; then 
    wget http://ftp.ebi.ac.uk/pub/databases/genenames/hgnc/archive/monthly/tsv/hgnc_complete_set_2022-04-01.txt -O ./translators/HGNC_symbol
    awk '{OFS="\t"}{print $2,$1}' ./translators/HGNC_symbol > ./translators/symbol_HGNC
  fi

  idconverter.rb -d ./translators/symbol_HGNC -i ./backupgens/data/filtered_Big_Papi -c 0,1 > ./backupgens/processed_backups/Big_Papi
  idconverter.rb -d ./translators/symbol_HGNC -i ./backupgens/data/filtered_Digenic_Paralog -c 0,1 > ./backupgens/processed_backups/Digenic_Paralog
  
  cat ./backupgens/processed_backups/* | sort | uniq -u  > ./backupgens/backup_gens

  # NEGATIVE CONTROL #
  grep -w 'All 6' ./backupgens/data/Big_Papi | awk '{FS="\t";OFS="\t"}{if ( $7 <= 0.05) print $1,$2}' > ./backupgens/data/filtered_Big_Papi_negative_control
  idconverter.rb -d ./backupgens/data/symbol_HGNC -i ./backupgens/data/filtered_Big_Papi_negative_control -c 0,1 | awk '{if (!( $1 == $2 )) print $0 }' > ./backupgens/non_backup_gens
  
  # Finally add new column indicating which pairs are paralogs in NEGATIVE AND POSITIVE CONTROLS.
  which_are_paralogs.R -i ./backupgens/backup_gens -o "./backupgens" -O "backup_gens"
  which_are_paralogs.R -i ./backupgens/non_backup_gens -o "./backupgens" -O "non_backup_gens"

elif [ "$exec_mode" == "control_type" ] ; then 

##################################################################
# OPTIONAL STAGE : SEE IF THE RELATION BACKUP-GENSEED IS SYMMETRIC
##################################################################
  pos_or_neg=$3
  filter_feature=$4 # Paralogs, Not_Paralogs, ".*"

  echo "$filter_feature"

  if [ $add_opt == "reverse" ] ; then 
    if [ $pos_or_neg == "positive" ] ; then 
      awk '{OFS="\t"}{print $2,$1,$3}' ./backupgens/backup_gens | grep -w "$filter_feature" | cut -f 1,2 | aggregate_column_data.rb -i - -x 0 -a 1 > ./control_gens 
    elif [ $pos_or_neg == "negative" ] ; then
      awk '{OFS="\t"}{print $2,$1,$3}' ./backupgens/non_backup_gens | grep -w "$filter_feature" | cut -f 1,2 | aggregate_column_data.rb -i - -x 0 -a 1 > ./control_gens 
    fi    
  elif [ $add_opt == "right" ] ; then 
    if [ $pos_or_neg == "positive" ] ; then 
      awk '{OFS="\t"}{print $1,$2,$3}' ./backupgens/backup_gens | grep -w "$filter_feature" | cut -f 1,2 | aggregate_column_data.rb -i - -x 0 -a 1 > ./control_gens 
    elif [ $pos_or_neg == "negative" ] ; then
      awk '{OFS="\t"}{print $1,$2,$3}' ./backupgens/non_backup_gens | grep -w "$filter_feature" | cut -f 1,2 | aggregate_column_data.rb -i - -x 0 -a 1 > ./control_gens 
    fi        
  fi

  if [ $add_opt == "disease" ] ; then
    cp ./diseasegens/processed_diseasome ./control_gens
  fi

elif [ "$exec_mode" == "input_stats" ] ; then 

##################################################################
# OPTIONAL STAGE : STABLISH THE STATS FOR EACH LAYER
##################################################################
  
  # TODO: Adapt this area.

  mkdir -p $output_folder/input_stats

  for annotation in $annotations ; do 

      autoflow_vars=`echo " 
      \\$annotation=${annotation},
      \\$input_path=$input_path,
      \\$net2custom=$net2custom
      " | tr -d [:space:]`

      AutoFlow -w $autoflow_scripts/input_stats.af -V $autoflow_vars -o $output_folder/input_stats/${annotation} $add_opt 

  done

#########################################################
# STAGE 2 AUTOFLOW EXECUTION
#########################################################

elif [ "$exec_mode" == "kernels" ] ; then
  #######################################################
  #STAGE 2.1 PROCESS SIMILARITY AND OBTAIN KERNELS
  mkdir -p $output_folder/similarity_kernels


  for annotation in $annotations ; do 

      autoflow_vars=`echo " 
      \\$annotation=${annotation},
      \\$input_path=$input_path,
      \\$net2custom=$net2custom,
      \\$kernels_varflow=$kernels_varflow
      " | tr -d [:space:]`

      AutoFlow -w $autoflow_scripts/sim_kern.af -V $autoflow_vars -o $output_folder/similarity_kernels/${annotation} $add_opt
      #TODO
      #process_type=`grep -P '^$annotation' $net2custom | cut -f 6`
      #if [ $process_type == "kernel" ] ; then
      #  AutoFlow -w $autoflow_scripts/sim_kern.af -V $autoflow_vars -o $output_folder/similarity_kernels/${annotation} $add_opt 
      #elif [ $process_type == "umap" ]; then
      #  AutoFlow -w $autoflow_scripts/sim_umap.af -V $autoflow_vars -o $output_folder/similarity_kernels/${annotation} $add_opt 
      #fi
      #ODOT

  done

elif [ "$exec_mode" == "ranking" ] ; then
  #########################################################
  # STAGE 2.2 OBTAIN RANKING FROM NON INTEGRATED KERNELS
  if [ -s $output_folder/rankings ] ; then
    rm -r $output_folder/rankings 
  fi
  mkdir -p $output_folder/rankings
  method=$2
  
  cat  $output_folder/similarity_kernels/*/*/ugot_path > $output_folder/similarity_kernels/ugot_path

  for annotation in $annotations ; do 
    for kernel in $kernels ; do 

      ugot_path="$output_folder/similarity_kernels/ugot_path"
      folder_kernel_path=`awk '{print $0,NR}' $ugot_path | sort -k 5 -r -u | grep "${annotation}_$kernel" | awk '{print $4}'`
      echo ${folder_kernel_path}
      if [ ! -z ${folder_kernel_path} ] ; then # This kernel for this annotation is done? 

        autoflow_vars=`echo " 
        \\$param1=$annotation,
        \\$kernel=$kernel,
        \\$input_path=$input_path,
        \\$folder_kernel_path=$folder_kernel_path,
        \\$input_name='kernel_matrix_bin',
        \\$control_gens=$control_gens,
        \\$paralog_feature=$input_path/paralog_feature,
        \\$output_name='non_integrated_rank',
        \\$method=$method
        " | tr -d [:space:]`

        AutoFlow -w $autoflow_scripts/ranking.af -V $autoflow_vars -o $output_folder/rankings/ranking_${kernel}_${annotation} -m 60gb -t 4-00:00:00 $3
      fi

    done
  done


elif [ "$exec_mode" == "integrate" ] ; then 
  #########################################################
  # STAGE 2.3 INTEGRATE THE KERNELS
  mkdir -p $output_folder/integrations
  cat  $output_folder/similarity_kernels/*/*/ugot_path > $output_folder/similarity_kernels/ugot_path # What I got?

  for integration_type in ${integration_types} ; do 

      ugot_path="$output_folder/similarity_kernels/ugot_path"

      autoflow_vars=`echo "
      \\$integration_type=${integration_type},
      \\$kernels_varflow=${kernels_varflow},
      \\$ugot_path=$ugot_path
      " | tr -d [:space:]`

      AutoFlow -w $autoflow_scripts/integrate.af -V $autoflow_vars -o $output_folder/integrations/${integration_type} -m 60gb -t 4-00:00:00 $add_opt 

  done

elif [ "$exec_mode" == "integrated_ranking" ] ; then
  #########################################################
  # STAGE 2.4 OBTAIN RANKING FROM INTEGRATED KERNELS
  if [ -s $output_folder/integrated_rankings ] ; then
    rm -r $output_folder/integrated_rankings # To not mix executions.
  fi
  mkdir -p $output_folder/integrated_rankings
  cat  $output_folder/integrations/*/*/ugot_path > $output_folder/integrations/ugot_path # What I got?
  method=$2

  for integration_type in ${integration_types} ; do 
    for kernel in $kernels ; do 

      ugot_path="$output_folder/integrations/ugot_path"
      folder_kernel_path=`awk '{print $0,NR}' $ugot_path | sort -k 5 -r -u | grep "${integration_type}_$kernel" | awk '{print $4}'`
      echo ${folder_kernel_path}
      if [ ! -z ${folder_kernel_path} ] ; then # This kernel for this integration_type is done? 

        autoflow_vars=`echo " 
        \\$param1=$integration_type,
        \\$kernel=$kernel,
        \\$input_path=$input_path,
        \\$folder_kernel_path=$folder_kernel_path,
        \\$input_name='general_matrix',
        \\$control_gens=$control_gens,
        \\$paralog_feature=$input_path/paralog_feature,
        \\$output_name='integrated_rank',
        \\$method=$method
        " | tr -d [:space:]`

        AutoFlow -w $autoflow_scripts/ranking.af -V $autoflow_vars -o $output_folder/integrated_rankings/ranking_${kernel}_${integration_type} -m 60gb -t 4-00:00:00 $3
      fi

    done
  done

#########################################################
# STAGE 3 OBTAIN REPORT FROM RESULTS
#########################################################

elif [ "$exec_mode" == "report" ] ; then 
  source ~soft_bio_267/initializes/init_ruby
  html_name=$2
  
  #############################################

  cat $output_folder/rankings/*/*/rank_list > $output_folder/non_integrated_rank_list
  cat $output_folder/integrated_rankings/*/*/rank_list > $output_folder/integrated_rank_list
  
  cat $output_folder/rankings/*/*/rank_metrics > $output_folder/non_integrated_rank_metrics
  cat $output_folder/integrated_rankings/*/*/rank_metrics > $output_folder/integrated_rank_metrics

  echo -e "annot_kernel\tannot\tkernel\tseed_gen\tbackup_gen\trank\tcummulative_density\tabsolute_position" | cat - $output_folder/non_integrated_rank_list > $report_folder/metrics/non_integrated_rank_list
  echo -e "integration_kernel\tintegration\tkernel\tseed_gen\tbackup_gen\trank\tcummulative_density\tabsolute_position" | cat - $output_folder/integrated_rank_list > $report_folder/metrics/integrated_rank_list

  mkdir -p $report_folder/metrics


  declare -A references
  references[annotations_metrics]='Net'
  references[similarity_metrics]='Net'
  references[filtered_similarity_metrics]='Net'
  references[uncomb_kernel_metrics]='Sample,Net,Kernel'
  references[comb_kernel_metrics]='Sample,Integration,Kernel'
  references[non_integrated_rank_metrics]='Sample,Net,Kernel'
  references[integrated_rank_metrics]='Sample,Integration,Kernel'
  #references[annotation_grade_metrics]='Gene_seed'

  for metric in annotations_metrics similarity_metrics uncomb_kernel_metrics comb_kernel_metrics non_integrated_rank_metrics integrated_rank_metrics filtered_similarity_metrics ; do
    if [ -s $output_folder/$metric ] ; then
    create_metric_table.rb $output_folder/$metric ${references[$metric]} $report_folder/metrics/parsed_${metric} 
    fi
  done

report_html -t ./report/templates/kernel_report.erb -d $report_folder/metrics/parsed_annotations_metrics,$report_folder/metrics/parsed_uncomb_kernel_metrics,$report_folder/metrics/parsed_comb_kernel_metrics,$report_folder/metrics/parsed_similarity_metrics,$report_folder/metrics/parsed_filtered_similarity_metrics -o "report_kernel$html_name"
report_html -t ./report/templates/ranking_report.erb -d $report_folder/metrics/parsed_non_integrated_rank_metrics,$report_folder/metrics/parsed_integrated_rank_metrics,$report_folder/metrics/non_integrated_rank_list,$report_folder/metrics/integrated_rank_list -o "report_ranking$html_name"

#########################################################
# STAGE TO CHECK AUTOFLOW IS RIGHT
#########################################################
elif [ "$exec_mode" == "check" ] ; then
  #STAGE 3 CHECK EXECUTION
  for folder in `ls $output_folder/$add_opt/` ; do 
    if [ -d $output_folder/$add_opt/$folder ] ; then
      echo "$folder"
      flow_logger -w -e $output_folder/$add_opt/$folder -r all
    fi
  done  
fi
