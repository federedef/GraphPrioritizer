#!/usr/bin/env bash
. ~soft_bio_267/initializes/init_autoflow 
. ~soft_bio_267/initializes/init_python
. ~soft_bio_267/initializes/init_R
# Input variables
exec_mode=$1 
add_opt=${@: -1} 
# Used Paths
export input_path=`pwd`
export sys_bio_lab_scripts_path=~soft_bio_267/programs/x86_64/scripts
export PATH=$input_path/scripts/aux_scripts:$sys_bio_lab_scripts_path:$PATH
export autoflow_scripts=$input_path/scripts/autoflow_scripts
daemon_scripts=$input_path/scripts/daemon_scripts
export control_genes_folder=$input_path/control_genes
export output_folder=$SCRATCH/executions/GraphPrioritizer
export report_folder=$output_folder/report
export translators=$input_path/translators
# Custom variables
annotations=" disease phenotype molecular_function biological_process cellular_component"
annotations+=" string_ppi_combined hippie_ppi"
#annotations+=" string_ppi_textmining string_ppi_database string_ppi_experimental string_ppi_coexpression string_ppi_cooccurence string_ppi_fusion string_ppi_neighborhood"
annotations+=" DepMap_effect_pearson DepMap_effect_spearman DepMap_Kim"
annotations+=" pathway gene_hgncGroup"
integrated_annotations="phenotype string_ppi_textmining string_ppi_coexpression string_ppi_database string_ppi_experimental pathway"
kernels="rf el node2vec raw_sim"
integration_types="mean integration_mean_by_presence median max"
net2custom=$input_path'/net2json' 
control_pos=$input_path'/control_pos'
control_neg=$input_path'/control_neg'
production_seedgens=$input_path'/production_seedgens'
whitelist="whitelist"
# Processed input variables
kernels_varflow=`echo $kernels | tr " " ";"`
annotations_varflow=`echo $annotations | tr " " ";"`

echo "$annotations"
## DEFINING DATASETS 
#####################
if [ "$exec_mode" == "download_layers" ] ; then
  # STAGE 1.1 DOWNLOAD DATA
  $daemon_scripts/download_layers.sh

elif [ "$exec_mode" == "download_translators" ] ; then
  # STAGE 1.2 TRANSLATOR TABLES
  mkdir -p ./translators

  declare -A translators2col
  translators2col[symbol]=2
  translators2col[entrez]=19
  translators2col[ensemble]=20
  wget http://ftp.ebi.ac.uk/pub/databases/genenames/hgnc/archive/monthly/tsv/hgnc_complete_set_2022-04-01.txt -O ./translators/HGNC_allids
  for translator in "${!translators2col[@]}"; do
    echo "$translator"
    awk -v translator=${translators2col[$translator]} 'BEGIN{FS="\t";OFS="\t"}{print $translator,$1}' ./translators/HGNC_allids > ./translators/${translator}_HGNC
    awk 'BEGIN{FS="\t";OFS="\t"}{print $2,$1}' ./translators/${translator}_HGNC > ./translators/HGNC_${translator}
  done

  # omim 2 text
  wget https://data.omim.org/downloads/Vigwxa9YRaCz7jdsYnIfUQ/mimTitles.txt -O ./translators/mimTitles
  grep -v "#" ./translators/mimTitles | cut -f 2,3 > tmp && mv tmp ./translators/mimTitles

  # Downloading ProtEnsemble_HGNC from STRING.
  wget https://stringdb-static.org/download/protein.aliases.v11.5/9606.protein.aliases.v11.5.txt.gz -O ./translators/protein_aliases.v11.5.txt.gz
  gzip -d translators/protein_aliases.v11.5.txt.gz
  grep -w "Ensembl_HGNC_HGNC_ID" translators/protein_aliases.v11.5.txt | cut -f 1,2 > ./translators/ProtEnsemble_HGNC
  rm ./translators/protein_aliases.v11.5.txt

elif [ "$exec_mode" == "process_download" ] ; then
  # STAGE 1.3 PROCESS DOWNLOAD
  $daemon_scripts/process_download.sh

elif [ "$exec_mode" == "dversion" ] ; then
  # STAGE 1.4 SELECTING DOWNGRADED OR UPGRADED
  dversion=$2 
  modify_json.py -k "data_process;Data_version" -v "$dversion" -jp net2json
  if [ -s ./input/input_processed ] ; then
    rm ./input/input_processed
  fi 
  if [ -s ./input/input_obo ] ; then
    rm ./input/input_obo
  fi 
  ln -sf $input_path/input/$dversion/input_processed ./input/input_processed
  ln -sf $input_path/input/$dversion/input_obo ./input/input_obo

elif [ "$exec_mode" == "whitelist" ] ; then
  # STAGE 1.5 (OPTIONAL STAGE): SELECT GENES FROM WHITELIST
  $daemon_scripts/whitelist.sh

## DEFINING BENCHMARKS
#######################
elif [ "$exec_mode" == "process_control" ] ; then 

  $daemon_scripts/control_preparation.sh

elif [ "$exec_mode" == "get_control" ] ; then 

  benchmark=$2
  if [ -s ./control_pos ] ; then
    rm ./control_pos
  fi
  if [ -s ./control_neg ] ; then
    rm ./control_neg
  fi
  if [ $benchmark == "zampieri" ] ; then
    cp $control_genes_folder/zampieri/disease_gens ./control_pos
    cp $control_genes_folder/zampieri/non_disease_gens ./control_neg
  elif [ $benchmark == "menche" ] ; then
    cp $control_genes_folder/menche/disease_gens ./control_pos
  fi

#########################################################
# STAGE 2 AUTOFLOW EXECUTION
#########################################################

elif [ "$exec_mode" == "kernels" ] ; then
  #######################################################
  #STAGE 2.1 PROCESS SIMILARITY AND OBTAIN KERNELS
  mkdir -p $output_folder/similarity_kernels
  whitelist="true"
  # update net2json
  embeddings=`echo $kernels | tr -s " " "," | awk '{print "["$0"]"}'`
  modify_json.py -k "data_process;Embeddings" -v "$embeddings" -jp net2json

  for annotation in $annotations ; do 

      autoflow_vars=`echo " 
      \\$annotation=${annotation},
      \\$input_path=$input_path/input/,
      \\$net2custom=$net2custom,
      \\$kernels_varflow=$kernels_varflow,
      \\$whitelist=$whitelist,
      \\$translators=$translators
      " | tr -d [:space:]`

      process_type=`net2json_parser.py --net_id $annotation --json_path $net2custom | grep -P -w '^Process' | cut -f 2`
      echo $process_type
      net2json_parser.py --net_id $annotation --json_path $net2custom
      echo "Performing embedding -- $annotation"
      AutoFlow -w $autoflow_scripts/sim_kern.af -V $autoflow_vars -o $output_folder/similarity_kernels/${annotation}  -L $add_opt #-A "exclude=sr133,sr014,sr030" -n bc -A "reservation:nuevos_nodos"

  done

  cp ./net2json $output_folder/similarity_kernels/net2json

elif [ "$exec_mode" == "plot_sims" ] ; then
  # Plotting the graphs in the correct manner
  mkdir -p plot_sims

  cat  $output_folder/similarity_kernels/*/*/ugot_path > $output_folder/similarity_kernels/ugot_path
  ugot_path="$output_folder/similarity_kernels/ugot_path"
  rawSim_paths=`awk '{print $0,NR}' $ugot_path | sort -k 5 -r -u | grep "raw_sim" | awk 'BEGIN{OFS="\t"}{print $2,$4}'`
  filter_sims=`echo $annotations | sed 's/ /\n/g'`
  rawSim_paths=`grep -F -f <(echo "$filter_sims") <(echo "$rawSim_paths")`
  echo -e "$rawSim_paths" >  $output_folder/similarity_kernels/rawSim_paths

  autoflow_vars=`echo "\\$rawSim_paths=$output_folder/similarity_kernels/rawSim_paths,\\$annotations_varflow=$annotations_varflow"`
  echo -e "$autoflow_vars"
  AutoFlow -w $autoflow_scripts/plot_sims.af -V $autoflow_vars -o $output_folder/plot_sims -L $add_opt 

elif [ "$exec_mode" == "ranking" ] ; then
  #########################################################
  # STAGE 2.2 OBTAIN RANKING FROM NON INTEGRATED KERNELS
  benchmark=$2 # menche or zampieri
  mkdir -p $output_folder/rankings
  if [ -s $output_folder/rankings/$benchmark ] ; then
    rm -r $output_folder/rankings/$benchmark
  fi
  mkdir -p $output_folder/rankings/$benchmark

  # update net2json
  annot=`echo $annotations | tr -s " " "," | awk '{print "["$0"]"}'`
  modify_json.py -k "data_process;layers2process" -v "$annot" -jp net2json
  
  cat  $output_folder/similarity_kernels/*/*/ugot_path > $output_folder/similarity_kernels/ugot_path
  for annotation in $annotations ; do 
    for kernel in $kernels ; do 

      #ugot_path="$output_folder/similarity_kernels/ugot_path"
      ugot_path="$output_folder/similarity_kernels/ugot_path"
      folder_kernel_path=`awk '{print $0,NR}' $ugot_path | sort -k 5 -r -u | grep "${annotation}_$kernel" | awk '{print $4}'`
      echo ${folder_kernel_path}
      if [ ! -z ${folder_kernel_path} ] ; then 

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
        \\$benchmark=$benchmark,
        \\$geneseeds=$input_path/geneseeds
        " | tr -d [:space:]`

        AutoFlow -w $autoflow_scripts/ranking.af -V $autoflow_vars -n cal -o $output_folder/rankings/$benchmark/ranking_${kernel}_${annotation} -m 30gb -t 0-03:59:59 -L $3 #-A "exclude=sr060" 
      fi
      sleep 2

    done
  done


elif [ "$exec_mode" == "integrate" ] ; then 
  #########################################################
  # STAGE 2.3 INTEGRATE THE KERNELS

  rm -r $output_folder/integrations
  mkdir -p $output_folder/integrations
  
  echo -e "$integrated_annotations" | tr -s " " "\n" > uwant
  cat  $output_folder/similarity_kernels/*/*/ugot_path > $output_folder/similarity_kernels/ugot_path
  filter_by_list -f $output_folder/similarity_kernels/ugot_path -c "2" -t uwant -o $output_folder/similarity_kernels
  rm uwant

  # update net2json
  int_annot=`echo $integrated_annotations | tr -s " " "," | awk '{print "["$0"]"}'`
  modify_json.py -k "data_process;Integrated_layers" -v "$int_annot" -jp net2json

  for integration_type in ${integration_types} ; do 

      ugot_path="$output_folder/similarity_kernels/filtered_ugot_path"

      autoflow_vars=`echo "
      \\$integration_type=${integration_type},
      \\$kernels_varflow=${kernels_varflow},
      \\$ugot_path=$ugot_path
      " | tr -d [:space:]`
      AutoFlow -w $autoflow_scripts/integrate.af -V $autoflow_vars -o $output_folder/integrations/${integration_type} -n cal -m 60gb -t 0-02:00:00 -L $add_opt 

  done

elif [ "$exec_mode" == "integrated_ranking" ] ; then
  #########################################################
  # STAGE 2.4 OBTAIN RANKING FROM INTEGRATED KERNELS
  benchmark=$2 # menche or zampieri
  mkdir -p $output_folder/integrated_rankings
  if [ -s $output_folder/integrated_rankings/$benchmark ] ; then
    rm -r $output_folder/integrated_rankings/$benchmark # To not mix executions.
  fi
  mkdir -p $output_folder/integrated_rankings/$benchmark
  cat  $output_folder/integrations/*/*/ugot_path > $output_folder/integrations/ugot_path # What I got?
  
  for integration_type in ${integration_types} ; do 
    for kernel in $kernels ; do 

      ugot_path="$output_folder/integrations/ugot_path"
      folder_kernel_path=`awk '{print $0,NR}' $ugot_path | sort -k 5 -r -u | grep -w "${integration_type}_$kernel" | awk '{print $4}'`
      echo ${folder_kernel_path}
      if [ ! -z ${folder_kernel_path} ] ; then 

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
        \\$benchmark=$benchmark,
        \\$geneseeds=$input_path/geneseeds
        " | tr -d [:space:]`
        AutoFlow -w $autoflow_scripts/ranking.af -V $autoflow_vars -n cal -o $output_folder/integrated_rankings/$benchmark/ranking_${kernel}_${integration_type} -m 30gb -t 0-03:59:59 -L $3
      fi
      sleep 1

    done
  done

#########################################################
# STAGE 3 OBTAIN REPORT FROM RESULTS
#########################################################

elif [ "$exec_mode" == "report" ] ; then 
  save=$2
  interested_layers=$annotations

  for html_name in "zampieri" "menche"; do
    #Setting up the report section #
    find $report_folder/$html_name -mindepth 2 -delete
    find $output_folder -maxdepth 1 -type f -delete
    mkdir -p $report_folder/$html_name/kernel_report
    mkdir -p $report_folder/$html_name/ranking_report
    $daemon_scripts/process_data_for_report.sh $html_name $save "$interested_layers"
    # Obtaining HTMLs
    report_html -t ./report/templates/kernel_report.py -c ./report/templates/css --css_cdn https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css -d `ls $report_folder/$html_name/kernel_report/* | tr -s [:space:] "," | sed 's/,*$//g'` -o "report_layer_building$html_name"
    report_html -t ./report/templates/ranking_report.py -c ./report/templates/css --css_cdn https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css -d `ls $report_folder/$html_name/ranking_report/* | tr -s [:space:] "," | sed 's/,*$//g'` -o "report_algQuality$html_name"
    if [ ! -z "$save" ] ; then
      name_dir=`date +%d_%m_%Y`
      mv ./report_layer_building$html_name.html ./report/HTMLs/$name_dir/
      mv ./report_algQuality$html_name.html ./report/HTMLs/$name_dir/
    fi
  done

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

elif [ "$exec_mode" == "recover" ]; then 
  #STAGE 4 RECOVER EXECUTION
  for folder in `ls $output_folder/$add_opt/` ; do 
    if [ -d $output_folder/$add_opt/$folder ] ; then
      echo "$folder"
      flow_logger -w -e $output_folder/$add_opt/$folder --sleep 0.1 -l -p  
    fi
  done
fi
