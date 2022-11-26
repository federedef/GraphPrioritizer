#!/usr/bin/env bash
. ~soft_bio_267/initializes/init_autoflow 

#Input variables.
exec_mode=$1 
add_opt=$2 

# Used Paths.
export input_path=`pwd`
export PATH=$input_path/scripts/aux_scripts:~soft_bio_267/programs/x86_64/scripts:$PATH
export autoflow_scripts=$input_path/scripts/autoflow_scripts
daemon_scripts=$input_path/scripts/daemon_scripts
export control_genes_folder=$input_path/control_genes
export output_folder=$SCRATCH/executions/backupgenes
report_folder=$output_folder/report

# Custom variables.
annotations="disease phenotype molecular_function biological_process cellular_component protein_interaction pathway gene_TF gene_hgncGroup"
annotations="disease phenotype molecular_function biological_process cellular_component"
annotations+="protein_interaction pathway gene_TF gene_hgncGroup"
annotations+="genetic_interaction_effect genetic_interaction_exprs genetic_interaction_effect_bicor genetic_interaction_exprs_bicor"
annotations+="genetic_interaction_effect_spearman genetic_interaction_exprs_spearman genetic_interaction_effect_umap"
annotations+="genetic_interaction_exprs_umap"
annotations="protein_interaction"
kernels="ka rf ct el node2vec"
kernels="ka"
integration_types="mean integration_mean_by_presence"
net2custom=$input_path'/net2custom' 
control_pos=$input_path'/control_pos'
control_neg=$input_path'/control_neg'
production_seedgens=$input_path'/production_seedgens'

kernels_varflow=`echo $kernels | tr " " ";"`

if [ "$exec_mode" == "download_layers" ] ; then
  #########################################################
  # STAGE 1 DOWNLOAD DATA
  #########################################################
  . ~soft_bio_267/initializes/init_R
  . ~soft_bio_267/initializes/init_ruby

  # Pass raw downloaded files.
  if [ -s ./input/data_downloaded/aux ] ; then
    echo "removing pre-existed obos files"
    find ./input/data_downloaded/aux -name "*.obo*" -delete 
  fi

  # Downloading ONTOLOGIES and PATHWAY ANNOTATION files from MONARCH.
  downloader.rb -i ./input/input_source/source_data -o ./input/data_downloaded
  mkdir -p ./input/input_raw
  cp ./input/data_downloaded/raw/monarch/tsv/all_associations/* ./input/input_raw

  # Downloading PROTEIN INTERACTIONS and ALIASES from STRING.
  wget https://stringdb-static.org/download/protein.links.v11.5/9606.protein.links.v11.5.txt.gz -O ./input/input_raw/string_data.v11.5.txt.gz
  gzip -d ./input/input_raw/string_data.v11.5.txt.gz

  # Downloading GENETIC INTERACTIONS from DEPMAP.
  wget https://ndownloader.figshare.com/files/34990033 -O ./input/input_raw/CRISPR_gene_effect 
  wget https://ndownloader.figshare.com/files/34989919 -O ./input/input_raw/CRISPR_gene_exprs 
  # Gene Expression: https://ndownloader.figshare.com/files/34989919
  # Cell Surpervivence score: https://ndownloader.figshare.com/files/34008491

  # Downloading Gen-Transcriptional Factor relation.
  get_gen_TF_data.R -O ./input/input_raw/gene_TF
  rm -r omnipathr-log

  # Downloading HGNC_group
  wget http://ftp.ebi.ac.uk/pub/databases/genenames/hgnc/archive/monthly/tsv/hgnc_complete_set_2022-04-01.txt -O ./input/input_raw/gene_hgncGroup

elif [ "$exec_mode" == "download_translators" ] ; then

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

  # The other direction symbol_HGNC
  awk '{OFS="\t"}{print $2,$1}' ./translators/HGNC_symbol > ./translators/symbol_HGNC

elif [ "$exec_mode" == "process_download" ] ; then
  source ~soft_bio_267/initializes/init_python

   mkdir -p ./input/input_processed

  declare -A tag_filter 
  tag_filter[phenotype]='HP:'
  tag_filter[disease]='MONDO:'
  tag_filter[function]='GO:'
  tag_filter[pathway]='REACT:'
  tag_filter[interaction]='RO:0002434' # RO:0002434 <=> interacts with

  # PROCESS ONTOLOGIES #
  for sample in phenotype disease function ; do
    zgrep ${tag_filter[$sample]} ./input/input_raw/gene_${sample}.all.tsv.gz | grep 'NCBITaxon:9606' | grep "HGNC:" | \
    aggregate_column_data.rb -i - -x 0 -a 4 > ./input/input_processed/$sample # | head -n 230
  done

  ## Creating paco files for each go branch.
  gene_ontology=( molecular_function cellular_component biological_process )
  for branch in ${gene_ontology[@]} ; do
    cp ./input/input_processed/function ./input/input_processed/$branch
  done
  rm ./input/input_processed/function

  # PROCESS REACTIONS # | head -n 230 
  zgrep "REACT:" ./input/input_raw/gene_pathway.all.tsv.gz |  grep 'NCBITaxon:9606' | grep "HGNC:" | \
   cut -f 1,5 > ./input/input_processed/pathway
  
  # PROCESS PROTEIN INTERACTIONS # | head -n 200 
  cat ./input/input_raw/string_data.v11.5.txt | tr -s " " "\t" > string_data.v11.5.txt
  idconverter.rb -d ./translators/Ensemble_HGNC -i string_data.v11.5.txt -c 0,1 > ./input/input_raw/interaction_scored && rm string_data.v11.5.txt
  #awk '{OFS="\t"}{print $1,$2}' ./input/input_raw/interaction_scored > ./input/input_processed/protein_interaction_unweighted # && rm ./input_raw/interaction_scored
  # if ( $3 > 700 )
  #awk '{OFS="\t"}{print $1,$2,$3}' ./input/input_raw/interaction_scored > .input/input_processed/protein_interaction_weighted
  awk '{OFS="\t"}{print $1,$2,$3}' ./input/input_raw/interaction_scored > ./input/input_processed/protein_interaction

  # PROCESS GENETIC INTERACTIONS # | cut -f 1-100 | head -n 100
  sed 's/([0-9]*)//1g' ./input/input_raw/CRISPR_gene_effect | cut -d "," -f 2- | sed 's/,/\t/g' | sed 's/ //g' > ./input/input_raw/CRISPR_gene_effect_symbol
  idconverter.rb -d ./translators/symbol_HGNC -i ./input/input_raw/CRISPR_gene_effect_symbol -r 0 > ./input/input_processed/genetic_interaction_effect
  rm ./input/input_raw/CRISPR_gene_effect_symbol

  # PROCESS GENETIC INTERACTIONS # | cut -f 1-100 | head -n 100
  sed 's/([0-9]*)//1g' ./input/input_raw/CRISPR_gene_exprs | cut -d "," -f 2- | sed 's/,/\t/g' | sed 's/ //g' > ./input/input_raw/CRISPR_gene_exprs_symbol
  idconverter.rb -d ./translators/symbol_HGNC -i ./input/input_raw/CRISPR_gene_exprs_symbol -r 0 > ./input/input_processed/genetic_interaction_exprs
  rm ./input/input_raw/CRISPR_gene_exprs_symbol

  # Translating to GENE-TF interaction.
  idconverter.rb -d ./translators/symbol_HGNC -i ./input/input_raw/gene_TF -c 0,1 | sed 's/HGNC:/TF:/2g' > ./input/input_processed/gene_TF

  # Formatting data_columns
  cut -f 1,14 ./input/input_raw/gene_hgncGroup | sed "s/\"//g" | tr -s "|" "," | awk '{if( $2 != "") print $0}' \
  | desaggregate_column_data.rb -i "-" -x 1 | sed 's/\t/\tGROUP:/1g' > ./input/input_processed/gene_hgncGroup

  # Formatting PS-Genes

  get_PS_gene_relation.py -i "/mnt/home/users/bio_267_uma/federogc/projects/backupgenes/input/phenotypic_series/series_data" -o "./input/input_processed/PS_genes"
  desaggregate_column_data.rb -i ./input/input_processed/PS_genes -x 1 > ./input/input_processed/tmp 
  idconverter.rb -d ./translators/symbol_HGNC -i ./input/input_processed/tmp -c 1 | awk '{print $2,$1}' > ./input/input_processed/gene_PS
  rm ./input/input_processed/PS_genes ./input/input_processed/tmp 


elif [ "$exec_mode" == "white_list" ] ; then

#########################################################
# OPTIONAL STAGE : SELECT GENES FROM WHITELIST
#########################################################

  cd ./input/input_processed
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
  cd ../..

elif [ "$exec_mode" == "control_preparation" ] ; then 

  $daemon_scripts/control_preparation.sh

elif [ "$exec_mode" == "control_type" ] ; then 

##################################################################
# OPTIONAL STAGE : SEE IF THE RELATION BACKUP-GENSEED IS SYMMETRIC
##################################################################
  filter_feature=$3 # Paralogs, Not_Paralogs, ".*"

  echo "$filter_feature"

  if [ $add_opt == "reverse" ] ; then 
      awk '{OFS="\t"}{print $2,$1,$3}' $control_genes_folder/backupgens/backup_gens | grep -w "$filter_feature" | cut -f 1,2 | aggregate_column_data.rb -i - -x 0 -a 1 > ./control_pos
      awk '{OFS="\t"}{print $2,$1,$3}' $control_genes_folder/backupgens/non_backup_gens | grep -w "$filter_feature" | cut -f 1,2 | aggregate_column_data.rb -i - -x 0 -a 1 > ./control_neg   
  elif [ $add_opt == "right" ] ; then 
      awk '{OFS="\t"}{print $1,$2,$3}' $control_genes_folder/backupgens/backup_gens | grep -w "$filter_feature" | cut -f 1,2 | aggregate_column_data.rb -i - -x 0 -a 1 > ./control_pos
      awk '{OFS="\t"}{print $1,$2,$3}' $control_genes_folder/backupgens/non_backup_gens | grep -w "$filter_feature" | cut -f 1,2 | aggregate_column_data.rb -i - -x 0 -a 1 > ./control_neg
  fi

  if [ $add_opt == "disease" ] ; then
    cp $control_genes_folder/diseasegens/disease_gens ./control_pos
    cp $control_genes_folder/diseasegens/non_disease_gens ./control_neg
  fi

elif [ "$exec_mode" == "get_production_seedgenes" ] ; then 

##################################################################
# OPTIONAL STAGE : SEE IF THE RELATION BACKUP-GENSEED IS SYMMETRIC
##################################################################
  translate_from=$add_opt
  cat ./production_seedgenes/* > production_seedgens

  if [ $translate_from == "symbol" ] ; then
    desaggregate_column_data.rb -i production_seedgens -x 1 > disaggregated_production_seedgens
    idconverter.rb -d ./translators/symbol_HGNC -i disaggregated_production_seedgens -c 1 | aggregate_column_data.rb -i - -x 0 -a 1 > production_seedgens
    rm disaggregated_production_seedgens
  elif [ $translate_from == "ensemble" ] ; then
    desaggregate_column_data.rb -i production_seedgens -x 1 > disaggregated_production_seedgens
    idconverter.rb -d ./translators/Ensemble_HGNC -i disaggregated_production_seedgens -c 1 | aggregate_column_data.rb -i - -x 0 -a 1 > production_seedgens
    rm disaggregated_production_seedgens
  fi

elif [ "$exec_mode" == "clusterize_seeds" ] ; then

  mkdir -p $output_folder/clusters_seeds

  seed_group_names=`cat $production_seedgens | cut -f 1 | tr -s "\n" ";"`

  for integration_type in ${integration_types} ; do 
    for kernel in $kernels ; do 

      ugot_path="$output_folder/integrations/ugot_path"
      folder_kernel_path=`awk '{print $0,NR}' $ugot_path | sort -k 5 -r -u | grep "${integration_type}_$kernel" | awk '{print $4}'`
      echo ${folder_kernel_path}
      if [ ! -z ${folder_kernel_path} ] ; then # This kernel for this integration_type is done? 
        
        autoflow_vars=`echo "
        \\$input_path=$input_path,
        \\$folder_kernel_path=$folder_kernel_path,
        \\$input_name='general_matrix',
        \\$production_seedgens=$production_seedgens,
        \\$seed_group_names=$seed_group_names
        " | tr -d [:space:]`

        AutoFlow -w $autoflow_scripts/extract_clusters.af -V $autoflow_vars -o $output_folder/clusters_seeds/clusters_${kernel}_${integration_type} $add_opt 
      fi

    done
  done

elif [ "$exec_mode" == "input_stats" ] ; then 

##################################################################
# OPTIONAL STAGE : STABLISH THE STATS FOR EACH LAYER
##################################################################
  
  if [ -s $output_folder/input_stats ] ; then
    rm -r $output_folder/input_stats
  fi
  mkdir -p $output_folder/input_stats

  for annotation in $annotations ; do 

      autoflow_vars=`echo " 
      \\$annotation=${annotation},
      \\$input_path=$input_path/input,
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
      \\$input_path=$input_path/input/,
      \\$net2custom=$net2custom,
      \\$kernels_varflow=$kernels_varflow
      " | tr -d [:space:]`

      process_type=`grep -P -w "^$annotation" $net2custom | cut -f 9`
      if [ "$process_type" == "kernel" ] ; then
        AutoFlow -w $autoflow_scripts/sim_kern.af -V $autoflow_vars -o $output_folder/similarity_kernels/${annotation} $add_opt 
      elif [ "$process_type" == "umap" ]; then
        echo "Performing umap for $annotation"
        AutoFlow -w $autoflow_scripts/sim_umap.af -V $autoflow_vars -o $output_folder/similarity_kernels/${annotation} $add_opt 
      fi

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
        \\$production_seedgens=$production_seedgens,
        \\$control_pos=$control_pos,
        \\$control_neg=$control_neg,
        \\$output_name='non_integrated_rank',
        \\$method=$method,
        \\$geneseeds=$input_path/geneseeds
        " | tr -d [:space:]`

        AutoFlow -w $autoflow_scripts/ranking.af -V $autoflow_vars -o $output_folder/rankings/ranking_${kernel}_${annotation} -m 60gb -t 4-00:00:00 $3
      fi

    done
  done


elif [ "$exec_mode" == "integrate" ] ; then 
  #########################################################
  # STAGE 2.3 INTEGRATE THE KERNELS
  rm -r $output_folder/integrations
  mkdir -p $output_folder/integrations
  #cat  $output_folder/similarity_kernels/*/*/ugot_path > $output_folder/similarity_kernels/ugot_path # What I got?
  
  echo -e "$annotations" | tr -s " " "\n" > uwant
  cat  $output_folder/similarity_kernels/*/*/ugot_path > $output_folder/similarity_kernels/ugot_path
  filter_by_whitelist.rb -f $output_folder/similarity_kernels/ugot_path -c "1;" -t uwant -o $output_folder/similarity_kernels
  rm uwant

  for integration_type in ${integration_types} ; do 

      ugot_path="$output_folder/similarity_kernels/filtered_ugot_path"

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
  
  #echo -e "$annotations" | tr -s " " "\n" > uwant
  #cat  $output_folder/similarity_kernels/*/*/ugot_path > $output_folder/similarity_kernels/ugot_path
  #filter_by_whitelist.rb -f $output_folder/similarity_kernels/ugot_path -c "1;" -t uwant -o $output_folder/similarity_kernels

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
        \\$production_seedgens=$production_seedgens,
        \\$control_pos=$control_pos,
        \\$control_neg=$control_neg,
        \\$output_name='integrated_rank',
        \\$method=$method,
        \\$geneseeds=$input_path/geneseeds
        " | tr -d [:space:]`

        AutoFlow -w $autoflow_scripts/ranking.af -V $autoflow_vars -o $output_folder/integrated_rankings/ranking_${kernel}_${integration_type} -m 60gb -t 4-00:00:00 $3
      fi

    done
  done

elif [ "$exec_mode" == "get_production_candidates" ] ; then
  name=$2
  mkdir -p ./production_seedgenes/output
  cat  $output_folder/rankings/*/*/non_integrated_rank_ranked_production_candidates > ./production_seedgenes/output/"$name"_non_integrated
  cat $output_folder/integrated_rankings/*/*/integrated_rank_ranked_production_candidates > ./production_seedgenes/output/"$name"_integrated

#########################################################
# STAGE 3 OBTAIN REPORT FROM RESULTS
#########################################################

elif [ "$exec_mode" == "report" ] ; then 
  source ~soft_bio_267/initializes/init_ruby
  source ~soft_bio_267/initializes/init_R
  report_type=$2
  html_name=$3
  
  #################################
  # Setting up the report section #
  find $report_folder/ -mindepth 2 -delete
  find $output_folder/ -maxdepth 1 -type f -delete

  mkdir -p $report_folder/kernel_report
  mkdir -p $report_folder/ranking_report
  mkdir -p $report_folder/img

  declare -A original_folders
  original_folders[annotations_metrics]='input_stats'
  original_folders[similarity_metrics]='similarity_kernels'
  original_folders[filtered_similarity_metrics]='similarity_kernels'
  original_folders[uncomb_kernel_metrics]='similarity_kernels'
  original_folders[comb_kernel_metrics]='integrations'

  original_folders[non_integrated_rank_summary]='rankings'
  original_folders[non_integrated_rank_measures]='rankings'
  original_folders[non_integrated_rank_cdf]='rankings'
  original_folders[non_integrated_rank_pos_cov]='rankings'
  original_folders[non_integrated_rank_positive_stats]='rankings'

  original_folders[integrated_rank_summary]='integrated_rankings'
  original_folders[integrated_rank_measures]='integrated_rankings'
  original_folders[integrated_rank_cdf]='integrated_rankings'
  original_folders[integrated_rank_pos_cov]='integrated_rankings'
  original_folders[integrated_rank_positive_stats]='integrated_rankings'
  
  # Here the data is collected from executed folders.
  for file in "${!original_folders[@]}" ; do
    original_folder=${original_folders[$file]}
    count=`find $output_folder/$original_folder -maxdepth 3 -mindepth 3 -name $file | wc -l`
    if [ "$count" -gt "0" ] ; then
      echo "$file"
      cat $output_folder/$original_folder/*/*/$file > $output_folder/$file
    fi
  done 


  ##########################
  # Processing all metrics #
  declare -A references
  references[annotations_metrics]='Net'
  references[similarity_metrics]='Net'
  references[filtered_similarity_metrics]='Net'
  references[uncomb_kernel_metrics]='Sample,Net,Kernel'
  references[comb_kernel_metrics]='Sample,Integration,Kernel'

  references[non_integrated_rank_summary]='Sample,Net,Kernel'
  references[non_integrated_rank_pos_cov]='Sample,Net,Kernel'
  references[non_integrated_rank_positive_stats]='Sample,Net,Kernel,group_seed'

  references[integrated_rank_summary]='Sample,Integration,Kernel'
  references[integrated_rank_pos_cov]='Sample,Integration,Kernel'
  references[integrated_rank_positive_stats]='Sample,Integration,Kernel,group_seed'

  references[annotation_grade_metrics]='Gene_seed'

  for metric in annotations_metrics similarity_metrics filtered_similarity_metrics uncomb_kernel_metrics comb_kernel_metrics ; do
    if [ -s $output_folder/$metric ] ; then
      create_metric_table.rb $output_folder/$metric ${references[$metric]} $report_folder/kernel_report/parsed_${metric} 
    fi
  done

  for metric in non_integrated_rank_summary integrated_rank_summary non_integrated_rank_pos_cov integrated_rank_pos_cov non_integrated_rank_positive_stats integrated_rank_positive_stats ; do
    if [ -s $output_folder/$metric ] ; then
      create_metric_table.rb $output_folder/$metric ${references[$metric]} $report_folder/ranking_report/parsed_${metric} 
    fi
  done

  if [ -s $output_folder/non_integrated_rank_measures ] ; then
     echo -e "annot_kernel\tannot\tkernel\trank\tacc\ttpr\tfpr\tprec\trec" | \
     cat - $output_folder/non_integrated_rank_measures > $report_folder/ranking_report/non_integrated_rank_measures
  fi

    if [ -s $output_folder/integrated_rank_measures ] ; then
    echo -e "integration_kernel\tintegration\tkernel\trank\tacc\ttpr\tfpr\tprec\trec" | \
     cat - $output_folder/integrated_rank_measures > $report_folder/ranking_report/integrated_rank_measures
  fi

  if [ -s $output_folder/non_integrated_rank_cdf ] ; then
     echo -e "annot_kernel\tannot\tkernel\tcandidate\tscore\trank\tcummulative_frec\tgroup_seed"| \
     cat - $output_folder/non_integrated_rank_cdf > $report_folder/ranking_report/non_integrated_rank_cdf
  fi

  if [ -s $output_folder/integrated_rank_cdf ] ; then
     echo -e "integration_kernel\tintegration\tkernel\tcandidate\tscore\trank\tcummulative_frec\tgroup_seed"| \
     cat - $output_folder/integrated_rank_cdf > $report_folder/ranking_report/integrated_rank_cdf
  fi

  ###################
  # Obtaining HTMLS #
  
  report_html -t ./report/templates/kernel_report.erb -d `ls $report_folder/kernel_report/* | tr -s [:space:] ","` -o "report_kernel$html_name"

  if [ "$report_type" == "data_quality" ] ; then

    report_html -t ./report/templates/dataQuality_report.erb -d `ls $report_folder/ranking_report/* | tr -s [:space:] ","` -o "report_dataQuality$html_name"

  elif [ "$report_type" == "alg_quality" ] ; then

    if [ -s $output_folder/non_integrated_rank_measures ] ; then
      get_graph.R -d $report_folder/ranking_report/non_integrated_rank_measures -x "fpr" -y "tpr" -g "kernel" -w "annot" -O "non_integrated_ROC" -o "$report_folder/img"
    fi

    if [ -s $output_folder/integrated_rank_measures ] ; then
      get_graph.R -d $report_folder/ranking_report/integrated_rank_measures -x "fpr" -y "tpr" -g "kernel" -w "integration" -O "integrated_ROC" -o "$report_folder/img"
    fi

    report_html -t ./report/templates/ranking_report.erb -d `ls $report_folder/ranking_report/* | tr -s [:space:] ","` -o "report_algQuality$html_name"
  fi



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
