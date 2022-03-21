#!/usr/bin/env bash
. ~soft_bio_267/initializes/init_autoflow 

exec_mode=$1 
add_opt=$2 # flags to autoflow
input_path=`pwd`
export PATH=$input_path/aux_scripts:~soft_bio_267/programs/x86_64/scripts:$PATH

autoflow_scripts=$input_path/autoflow_scripts
output_folder=$SCRATCH/executions/backupgenes
report_folder=$output_folder/report
#kernels_calc_af_report=$output_folder/report


#Custom variables.
annotations="phenotype molecular_function biological_process cellular_component disease"
kernels="ka ct el rf"
integration_types="mean integration_mean_by_presence"
net2custom=$input_path'/net2custom'
gens_seed=$input_path'/gens_seed' # What are the knocked genes?
backup_gens=$input_path'/backup_gens' # What are its backups?

kernels_varflow="ka;ct;el;rf"
#net="%phenotype;molecular_function;%biological_process;cellular_component" 
#kernel="ka;ct;el;rf"
#integration_types="mean;integration_mean_by_presence;"
#autoflow_vars=`echo " 
#\\$nets=$net,
#\\$kernel=$kernel,
#\\$input_path=$input_path,
#\\$integration_types=$integration_types,
#\\$net2custom=$net2custom,
#\\$gens_seed=$gens_seed,
#\\$backup_gens=$backup_gens
#" | tr -d [:space:]`

#########################################################
#STAGE 1 DOWNLOAD DATA
#########################################################

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

elif [ "$exec_mode" == "process_download" ] ; then

  #Process the files
  mkdir -p ./input_processed

  declare -A tag_filter 
  tag_filter[phenotype]='HP:'
  tag_filter[disease]='MONDO:'
  tag_filter[function]='GO:'
  tag_filter[pathway]='REACT:'
  tag_filter[interaction]='RO:0002434' # RO:0002434 <=> interacts with

  for sample in phenotype disease function ; do
    zgrep ${tag_filter[$sample]} input_raw/gene_${sample}.all.tsv.gz | grep 'NCBITaxon:9606' | grep "HGNC:" | \
    aggregate_column_data.rb -i - -x 0 -a 4 > input_processed/$sample
  done

  # Warning: Truncate "| head -n 100" when trying.
  # TODO: The next addition have to be checked.
  zgrep "REACT:" input_raw/gene_pathway.all.tsv.gz |  grep 'NCBITaxon:9606' | grep "HGNC:" | \
   cut -f 1,5 | head -n 230 > input_processed/pathway # | head -n 230
  zgrep "RO:0002434" input_raw/gene_interaction.all.tsv.gz | grep 'NCBITaxon:9606' | \
  awk 'BEGIN{FS="\t";OFS="\t"}{if( $1 ~ /HGNC:/ && $5 ~ /HGNC:/) print $1,$5}' | head -n 430 > input_processed/interaction # | head -n 230
  

  # Creating paco files for each go branch.
  gene_ontology=( molecular_function cellular_component biological_process )
  for branch in ${gene_ontology[@]} ; do
    cp input_processed/function input_processed/$branch
    echo -e "input_processed/$branch"
  done
  rm input_processed/function

elif [ "$exec_mode" == "white_list" ] ; then

#########################################################
# OPTIONAL STAGE : SELECT GENES FROM WHITELIST
#########################################################

  echo -e "sample\tpre-filtered\tpos-filtered" > input_processed/filter_metrics

  for sample in phenotype disease biological_process cellular_component molecular_function pathway interaction ; do
    # Using a process substitution
    join -t $'\t' -1 1 -2 1 <(sort -k 1 input_processed/$sample) <(sort $input_path/white_list/hgnc_white_list) > input_processed/filtered_$sample
    nrows_prefiltered=`wc -l input_processed/$sample | tr " " "\t" | cut -f1 `
    nrows_posfiltered=`wc -l input_processed/filtered_$sample | tr " " "\t" | cut -f1 `
    echo -e "$sample\t$nrows_prefiltered\t$nrows_posfiltered" >> input_processed/filter_metrics
    rm input_processed/$sample
    mv input_processed/filtered_$sample input_processed/$sample
  done

  join -t $'\t' -1 2 -2 1 <(sort -k 2 input_processed/interaction) <(sort $input_path/white_list/hgnc_white_list) > input_processed/filtered_interaction
  nrows_prefiltered=`wc -l input_processed/interaction | tr " " "\t" | cut -f1 `
  nrows_posfiltered=`wc -l input_processed/filtered_interaction | tr " " "\t" | cut -f1 `
  echo -e "interaction\t$nrows_prefiltered\t$nrows_posfiltered" >> input_processed/filter_metrics
  rm input_processed/interaction
  mv input_processed/filtered_interaction input_processed/interaction

  echo "Annotation files filtered"


#########################################################
#STAGE 2 AUTOFLOW EXECUTION
#########################################################

elif [ "$exec_mode" == "input_stats" ] ; then 

  mkdir -p $output_folder/input_stats

  for annotation in $annotations ; do 

      autoflow_vars=`echo " 
      \\$annotation=${annotation},
      \\$input_path=$input_path,
      \\$net2custom=$net2custom
      " | tr -d [:space:]`

      AutoFlow -w $autoflow_scripts/input_stats.af -V $autoflow_vars -o $output_folder/input_stats/${annotation} $add_opt 

  done

elif [ "$exec_mode" == "kernels" ] ; then
  #########################################################
  #STAGE 2.1 PROCESS SIMILARITY AND OBTAIN KERNELS


  mkdir -p $output_folder/similarity_kernels

  for annotation in $annotations ; do 

      autoflow_vars=`echo " 
      \\$annotation=${annotation},
      \\$input_path=$input_path,
      \\$net2custom=$net2custom,
      \\$kernels_varflow=$kernels_varflow
      " | tr -d [:space:]`

      # CAUTION, PUT THIS IF NECESSARY -m 60gb -t 4-00:00:00
      AutoFlow -w $autoflow_scripts/sim_kern.af -V $autoflow_vars -o $output_folder/similarity_kernels/${annotation} -c 16 -m 60gb -t 4-00:00:00 $add_opt 

  done

elif [ "$exec_mode" == "ranking" ] ; then
  #########################################################
  #STAGE 2.2 OBTAIN RANKING FROM NON INTEGRATED KERNELS

  mkdir -p $output_folder/rankings

  for annotation in $annotations ; do 
    for kernel in $kernels ; do 

      ugot_path="$output_folder/similarity_kernels/ugot_path"
      folder_kernel_path=`awk '{print $0,NR}' $ugot_path | sort -k 5 -r -u | grep "${annotation}_$kernel" | awk '{print $4}'`
      echo ${folder_kernel_path}
      if [ ! -z ${folder_kernel_path} ] ; then # This kernel for this annotation is done? 

        autoflow_vars=`echo " 
        \\$annotation=$annotation,
        \\$kernel=$kernel,
        \\$input_path=$input_path,
        \\$folder_kernel_path=$folder_kernel_path,
        \\$gens_seed=$gens_seed,
        \\$backup_gens=$backup_gens
        " | tr -d [:space:]`

        # CAUTION, PUT THIS IF NECESSARY -m 60gb -t 4-00:00:00
        AutoFlow -w $autoflow_scripts/ranking_non_int.af -V $autoflow_vars -o $output_folder/rankings/ranking_${kernel}_${annotation} -m 60gb -t 4-00:00:00 $add_opt 
      fi

    done
  done


elif [ "$exec_mode" == "integrate" ] ; then 
  #########################################################
  #STAGE 2.3 INTEGRATE THE KERNELS

  # IDEA: Usar parametros para especificar 
  # los kernels que quiero integrar, o el modo etc.

  mkdir -p $output_folder/integrations

  for integration_type in ${integration_types} ; do 

      ugot_path="$output_folder/similarity_kernels/ugot_path"

      autoflow_vars=`echo "
      \\$integration_type=${integration_type},
      \\$kernels_varflow=${kernels_varflow},
      \\$ugot_path=$ugot_path
      " | tr -d [:space:]`

      # TODO: quizas haya  que anadir una especificacion de cuales capas se han conseguido integrar al final.
      # CAUTION, PUT THIS IF NECESSARY -m 60gb -t 4-00:00:00 -m 60gb -t 4-00:00:00
      AutoFlow -w $autoflow_scripts/integrate.af -V $autoflow_vars -o $output_folder/integrations/${integration_type} -m 60gb -t 4-00:00:00 $add_opt 

  done

elif [ "$exec_mode" == "integrated_ranking" ] ; then
  #########################################################
  #STAGE 2.4 OBTAIN RANKING FROM INTEGRATED KERNELS

  mkdir -p $output_folder/integrated_rankings

  for integration_type in ${integration_types} ; do 
    for kernel in $kernels ; do 

      ugot_path="$output_folder/integrations/ugot_path"
      folder_kernel_path=`awk '{print $0,NR}' $ugot_path | sort -k 5 -r -u | grep "${integration_type}_$kernel" | awk '{print $4}'`
      echo ${folder_kernel_path}
      if [ ! -z ${folder_kernel_path} ] ; then # This kernel for this integration_type is done? 

        autoflow_vars=`echo " 
        \\$integration_type=$integration_type,
        \\$kernel=$kernel,
        \\$input_path=$input_path,
        \\$folder_kernel_path=$folder_kernel_path,
        \\$gens_seed=$gens_seed,
        \\$backup_gens=$backup_gens
        " | tr -d [:space:]`

        # CAUTION, PUT THIS IF NECESSARY -m 60gb -t 4-00:00:00
        AutoFlow -w $autoflow_scripts/ranking_int.af -V $autoflow_vars -o $output_folder/integrated_rankings/ranking_${kernel}_${integration_type} -m 60gb -t 4-00:00:00 $add_opt 
      fi

    done
  done

#########################################################
#STAGE 3 PREPARING PLOTS FOR THE REPORT
#########################################################

elif [ "$exec_mode" == "metrics" ] ; then
  source ~soft_bio_267/initializes/init_R
  mkdir -p $report_folder

  # TODO: Pensar en el método adecuado para medir la similitud entre capas o kernels.
  # (quizas acortando por los rankings) o por medio de la referencia en similitud.
  

  #########################################################
  #STAGE 3.1 OBTAIN THE AMOUNT OF DATA FOR EACH SEED-GEN
  #          ON EACH ANNOTATION LAYER
  #annotation_grade.sh $gens_seed $output_folder $net2custom "$annotations" $input_path/input_processed

  #########################################################
  #STAGE 3.2 OBTAIN CDF PLOTS FROM NON INTEGRATED
  mkdir -p $report_folder/non_integrated_cdf_plots
  plot_cdf.R -d $output_folder/non_integrated_rank_list -f 2 -s 3 -c 6 -o cdf_plots -O $report_folder/non_integrated_cdf_plots -w 10 -g 10

  #########################################################
  #STAGE 3.3 OBTAIN CDF PLOTS FROM INTEGRATED
  mkdir -p $report_folder/integrated_cdf_plots
  plot_cdf.R -d $output_folder/integrated_rank_list -f 2 -s 3 -c 6 -o cdf_plots -O $report_folder/integrated_cdf_plots -w 10 -g 10

#########################################################
#STAGE 4 OBTAIN REPORT FROM RESULTS
#########################################################

elif [ "$exec_mode" == "report" ] ; then 
  source ~soft_bio_267/initializes/init_ruby
  
  #############################################
  mkdir -p report/cdfs
  cp -r $report_folder/non_integrated_cdf_plots report/cdfs
  cp -r $report_folder/integrated_cdf_plots report/cdfs

  mkdir -p $report_folder/metrics
  declare -A references
  references[annotations_metrics]='Net'
  references[similarity_metrics]='Net'
  references[uncomb_kernel_metrics]='Sample,Net,Kernel'
  references[comb_kernel_metrics]='Sample,Integration,Kernel'
  references[non_integrated_rank_metrics]='Sample,Net,Kernel'
  references[integrated_rank_metrics]='Sample,Integration,Kernel'
  #references[annotation_grade_metrics]='Gene_seed'

  for metric in annotations_metrics similarity_metrics uncomb_kernel_metrics comb_kernel_metrics non_integrated_rank_metrics integrated_rank_metrics ; do
    if [ -s $output_folder/$metric ] ; then
    create_metric_table.rb $output_folder/$metric ${references[$metric]} $report_folder/metrics/parsed_${metric} 
    fi
  done

report_html -t ./report/templates/kernel_report.erb -d $report_folder/metrics/parsed_annotations_metrics,$report_folder/metrics/parsed_uncomb_kernel_metrics,$report_folder/metrics/parsed_comb_kernel_metrics,$report_folder/metrics/parsed_similarity_metrics -o report_kernel
report_html -t ./report/templates/ranking_report.erb -d $report_folder/metrics/parsed_non_integrated_rank_metrics,$report_folder/metrics/parsed_integrated_rank_metrics -o report_ranking

#########################################################
#STAGE TO CHECK AUTOFLOW IS RIGHT
#########################################################
elif [ "$exec_mode" == "check" ] ; then
  #STAGE 3 CHECK EXECUTION
  # La sección del check la realizado por bucle o en selección directa.
  for folder in `ls $output_folder/$add_opt/` ; do 
    if [ -d $output_folder/$add_opt/$folder ] ; then
      echo "$folder"
      flow_logger -w -e $output_folder/$add_opt/$folder -r all
    fi
  done  
fi
