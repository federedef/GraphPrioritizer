#!/usr/bin/env bash
. ~soft_bio_267/initializes/init_autoflow 

exec_mode=$1 
add_opt=$2 # flags to autoflow
input_path=`pwd`
export PATH=$input_path/aux_scripts:~soft_bio_267/programs/x86_64/scripts:$PATH

output_folder=$SCRATCH/executions/backupgenes
kernels_calc_af_report=$output_folder/report


#Custom variables.
annotations="phenotype molecular_function biological_process cellular_component"
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

  declare -A tag_filter 
  tag_filter[phenotype]='HP:'
  tag_filter[disease]='MONDO:'
  tag_filter[function]='GO:'
  tag_filter[pathway]='REACT:'
  tag_filter[interaction]='RO:0002434' # RO:0002434 <=> interacts with

  for sample in phenotype disease function ; do
    zgrep ${tag_filter[$sample]} input_raw/gene_${sample}.all.tsv.gz | grep 'NCBITaxon:9606' | grep "HGNC:" | \
    aggregate_column_data.rb -i - -x 0 -a 4 | head -n 100 > input_processed/$sample
  done

  #Warning: Truncate "| head -n 100" when trying.
  # TODO: The next addition have to be checked.
  zgrep "REACT:" input_raw/gene_pathway.all.tsv.gz |  grep 'NCBITaxon:9606' | grep "HGNC:" | \
   cut -f 1,5 | head -n 100 > input_processed/pathway 
  zgrep "RO:0002434" input_raw/gene_interaction.all.tsv.gz | grep 'NCBITaxon:9606' | \
  awk 'BEGIN{FS="\t";OFS="\t"}{if( $1 ~ /HGNC:/ && $5 ~ /HGNC:/) print $1,$5}' | head -n 100 > input_processed/interaction 
  

  # Creating paco files for each go branch.
  gene_ontology=( molecular_function cellular_component biological_process )
  for branch in ${gene_ontology[@]} ; do
    cp input_processed/function input_processed/$branch
    echo -e "input_processed/$branch"
  done
  rm input_processed/function


elif [ "$exec_mode" == "kernels" ] ; then
  #STAGE 2 AUTOFLOW EXECUTION

  mkdir -p $output_folder/similarity_kernels

  for annotation in $annotations ; do 

      autoflow_vars=`echo " 
      \\$annotation=${annotation},
      \\$input_path=$input_path,
      \\$net2custom=$net2custom,
      \\$kernels_varflow=$kernels_varflow
      " | tr -d [:space:]`

      # CAUTION, PUT THIS IF NECESSARY -m 60gb -t 4-00:00:00
      AutoFlow -w sim_kern.af -V $autoflow_vars -o $output_folder/similarity_kernels/${annotation} $add_opt 

  done
###################################################################################################################
# IDEA: Usar parametros para especificar los kernels que quiero integrar, o el modo etc.
elif [ "$exec_mode" == "integrate" ] ; then 

  mkdir -p $output_folder/integrations

  for integration_type in ${integration_types} ; do 

      ugot_path="$output_folder/similarity_kernels/ugot_path"

      autoflow_vars=`echo "
      \\$integration_type=${integration_type},
      \\$kernels_varflow=${kernels_varflow},
      \\$ugot_path=$ugot_path
      " | tr -d [:space:]`

      echo $autoflow_vars 
      # TODO: quizas haya  que anadir una especificacion de cuales capas se han conseguido integrar al final.
      # CAUTION, PUT THIS IF NECESSARY -m 60gb -t 4-00:00:00 -m 60gb -t 4-00:00:00
      AutoFlow -w integrate.af -V $autoflow_vars -o $output_folder/integrations/${integration_type} $add_opt 

  done

elif [ "$exec_mode" == "ranking" ] ; then
  # STAGE 2 AUTOFLOW EXECUTION
  # Con esta sección podemos aplicar la ejecución por kernel de interés
  # PRIMERO RALIZAMOS EL RANKEO CON LOS KERNELS SIN INTEGRAR.

  #STAGE 2 AUTOFLOW EXECUTION

  mkdir -p $output_folder/rankings
  echo "eyy" 

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
        AutoFlow -w ranking_non_int.af -V $autoflow_vars -o $output_folder/rankings/ranking_${kernel}_${annotation} $add_opt 
      fi

    done
  done

elif [ "$exec_mode" == "integrated_ranking" ] ; then

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
        AutoFlow -w ranking_int.af -V $autoflow_vars -o $output_folder/integrated_rankings/ranking_${kernel}_${integration_type} $add_opt 
      fi

    done
  done

elif [ "$exec_mode" == "predictividad" ] ; then
  #STAGE 2 AUTOFLOW EXECUTION
  # Con esta sección podemos aplicar la ejecución por kernel de interés
  for i in vec ; do 
    AutoFlow -w rankeo.af -V $autoflow_vars -o rankeo_$variable -m 60gb -t 4-00:00:00 $add_opt 
  done

##################################################################################################################
elif [ "$exec_mode" == "check" ] ; then
  #STAGE 3 CHECK EXECUTION
  # La sección del check la realizado por bucle o en selección directa.
  for folder in `ls $output_folder` ; do 
    echo "$folder"
    flow_logger -w -e $output_folder/$folder -r all
  done

elif [ "$exec_mode" == "report" ] ; then 
  source ~soft_bio_267/initializes/init_ruby

  #STAGE 4.1 RECOLLECT CANDIDATES LIST fROM RESULTS
  mkdir -p report 
  mkdir -p report/correlations
  mkdir -p report/candidates
  mkdir -p report/metrics
  
  rsync -a --delete ${kernels_calc_af_exec}/correlate_matrices.R_*/*_correlation.png ./report/correlations
  rsync -a --delete ${kernels_calc_af_exec}/ranker_gene.rb_*/*_all_candidates ./report/candidates

  declare -A references
  references[annotations_metrics]='Net'
  references[similarity_metrics]='Net'
  references[uncomb_kernel_metrics]='Sample,Net,Kernel'
  references[comb_kernel_metrics]='Sample,Integration,Kernel'
  references[non_integrated_rank_metrics]='Sample,Net,Kernel'
  references[integrated_rank_metrics]='Sample,Integration,Kernel'

  for metric in annotations_metrics similarity_metrics uncomb_kernel_metrics comb_kernel_metrics non_integrated_rank_metrics integrated_rank_metrics; do
    if [ -s $kernels_calc_af_exec/$metric ] ; then
    create_metric_table.rb $kernels_calc_af_exec/$metric ${references[$metric]} ./report/metrics/parsed_${metric} 
    fi
  done

  report_html -t kernel_report.erb -d ./report/metrics/parsed_annotations_metrics,./report/metrics/parsed_uncomb_kernel_metrics,./report/metrics/parsed_comb_kernel_metrics,./report/metrics/parsed_similarity_metrics -o report_kernel
  report_html -t ranking_report.erb -d ./report/metrics/parsed_non_integrated_rank_metrics,./report/metrics/parsed_integrated_rank_metrics -o report_ranking
  #if [ -s $kernels_calc_af_exec/filtered_metrics ] ; then
  #  create_metric_table.rb $kernels_calc_af_exec/filtered_metrics Net $results_files/parsed_filtered_metrics
  #  awk -i inplace -v nets=$net 'BEGIN {split(nets, N, ";")}{if( NR == 1 ) print $0; for (net in N) if($1 == N[net]) print $0}' $results_files/parsed_filtered_metrics
  #  report_html -t report.erb -d $results_files/parsed_uncomb_kernel_metrics,$results_files/parsed_comb_kernel_metrics,$results_files/parsed_similarity_metrics,$results_files/parsed_filtered_metrics -o report_metrics
  #else 
  #  report_html -t report.erb -d ./report/metrics/parsed_annotations_metrics,./report/metrics/parsed_uncomb_kernels_metrics,./report/metrics/parsed_comb_kernel_metrics,./report/metrics/parsed_similarity_metrics -o report_metrics
  #fi
  
fi


