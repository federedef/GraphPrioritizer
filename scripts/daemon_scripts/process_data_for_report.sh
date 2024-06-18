source ~soft_bio_267/initializes/init_python
source $input_path/scripts/aux_scripts/aux_daemon.sh
html_name=$1
save=$2
interested_layers=$3
  declare -A original_folders
  original_folders[annotations_metrics]='similarity_kernels'
  original_folders[final_stats_by_steps]='similarity_kernels'
  original_folders[uncomb_kernel_metrics]='similarity_kernels'
  original_folders[graph_attr_by_net]='similarity_kernels'
  original_folders[comb_kernel_metrics]='integrations'

  original_folders[non_integrated_rank_summary]="rankings/$html_name"
  original_folders[non_integrated_rank_measures]="rankings/$html_name"
  original_folders[non_integrated_rank_cdf]="rankings/$html_name"
  original_folders[non_integrated_rank_pos_cov]="rankings/$html_name"
  original_folders[non_integrated_rank_positive_stats]="rankings/$html_name"
  original_folders[non_integrated_rank_size_auc_by_group]="rankings/$html_name"
  original_folders[non_integrated_rank_group_vs_posrank]="rankings/$html_name"

  original_folders[integrated_rank_summary]="integrated_rankings/$html_name"
  original_folders[integrated_rank_measures]="integrated_rankings/$html_name"
  original_folders[integrated_rank_cdf]="integrated_rankings/$html_name"
  original_folders[integrated_rank_pos_cov]="integrated_rankings/$html_name"
  original_folders[integrated_rank_positive_stats]="integrated_rankings/$html_name"
  original_folders[integrated_rank_size_auc_by_group]="integrated_rankings/$html_name"
  original_folders[integrated_rank_group_vs_posrank]="integrated_rankings/$html_name"
  
  # Here the data is collected from executed folders.
  for file in "${!original_folders[@]}" ; do
    original_folder=${original_folders[$file]}
    count=`find $output_folder/$original_folder -maxdepth 4 -mindepth 4 -name $file | wc -l`
    if [ "$count" -gt "0" ] ; then
      echo "$file"
      cat $output_folder/$original_folder/*/*/$file > $output_folder/$file
    fi
  done 

  #Here data is selected with just the selected layers of interest
  for file in "annotations_metrics" "final_stats_by_steps" "uncomb_kernel_metrics" "graph_attr_by_net"; do
    echo "Selecting $file"
    grep -e "`echo $interested_layers | tr -s ' ' '\n'`" $output_folder/$file > tmp
    mv tmp $output_folder/$file
    echo `wc -l $output_folder/$file`
  done
  for file in `find $output_folder/non_integrated_* -maxdepth 0 -type f -printf "%f\n"`; do
    echo "Selecting $file"
    grep -w -F -f <(echo $interested_layers | tr -s ' ' '\n') $output_folder/$file > tmp
    mv tmp $output_folder/$file
    echo `wc -l $output_folder/$file`
  done

  ##########################
  # Processing all metrics #
  declare -A references_kernel_report
  references_kernel_report[annotations_metrics]='Net'
  references_kernel_report[final_stats_by_steps]='Net_Step,Net,Step'
  references_kernel_report[uncomb_kernel_metrics]='Sample,Net,Embedding'
  references_kernel_report[comb_kernel_metrics]='Sample,Integration,Embedding'
  references_kernel_report[graph_attr_by_net]='Net'

  for metric in ${!references_kernel_report[@]} ; do 
    if [ -s $output_folder/$metric ] ; then
      echo "$output_folder/$metric"
      create_metric_table $output_folder/$metric ${references_kernel_report[$metric]} $report_folder/$html_name/kernel_report/parsed_${metric} 
    fi
  done 

  declare -A references_ranking_report
  references_ranking_report[non_integrated_rank_summary]='Sample,Net,Embedding'
  references_ranking_report[non_integrated_rank_pos_cov]='Sample,Net,Embedding'
  references_ranking_report[non_integrated_rank_positive_stats]='Sample,Net,Embedding,group_seed'
  references_ranking_report[integrated_rank_summary]='Sample,Integration,Embedding'
  references_ranking_report[integrated_rank_pos_cov]='Sample,Integration,Embedding'
  references_ranking_report[integrated_rank_positive_stats]='Sample,Integration,Embedding,group_seed'

  for metric in ${!references_ranking_report[@]} ; do 
    if [ -s $output_folder/$metric ] ; then
      echo "$output_folder/$metric"
      create_metric_table $output_folder/$metric ${references_ranking_report[$metric]} $report_folder/$html_name/ranking_report/parsed_${metric} 
    fi
  done 

  #################
  # Adding headers #

  declare -A headers
  headers[non_integrated_rank_size_auc_by_group]="sample\tannot\tEmbedding\tseed\tpos_cov\tauc"
  headers[integrated_rank_size_auc_by_group]="sample\tmethod\tEmbedding\tseed\tpos_cov\tauc"
  headers[non_integrated_rank_measures]="annot_Embedding\tannot\tEmbedding\trank\tacc\ttpr\tfpr\tprec\trec"
  headers[integrated_rank_measures]="integration_Embedding\tintegration\tEmbedding\trank\tacc\ttpr\tfpr\tprec\trec"
  headers[non_integrated_rank_cdf]="annot_Embedding\tannot\tEmbedding\tcandidate\tscore\trank\tcummulative_frec\tgroup_seed"
  headers[integrated_rank_cdf]="integration_Embedding\tintegration\tEmbedding\tcandidate\tscore\trank\tcummulative_frec\tgroup_seed"
  headers[non_integrated_rank_group_vs_posrank]="annot_Embedding\tannot\tEmbedding\tgroup_seed\trank"
  headers[integrated_rank_group_vs_posrank]="integration_Embedding\tintegration\tEmbedding\tgroup_seed\trank"

  for table in ${!headers[@]}; do
    input_path=$output_folder/$table
    output_path=$report_folder/$html_name/ranking_report/$table
    add_header ${headers[$table]} $input_path $output_path
  done

  # Adding control pos
  echo -e "Seed Name\tGenes" > $report_folder/$html_name/ranking_report/control_pos
  desaggregate_column_data -x 2 -i ./control_genes/$html_name/disease_gens >> $report_folder/$html_name/ranking_report/control_pos

  if [ ! -z "$save" ] ; then
    name_dir=`date +%d_%m_%Y`
    mkdir ./report/HTMLs/$name_dir
    # Copy net2json
    cp ./net2json ./report/HTMLs/$name_dir/
    if [ "$save" == "all" ] ; then
      mkdir -p $output_folder/saved_report/$name_dir/$html_name
      cp -r $report_folder/$html_name/ranking_report $output_folder/saved_report/$name_dir/$html_name
      cp -r $report_folder/$html_name/kernel_report $output_folder/saved_report/$name_dir/$html_name
    fi
  else 
    echo "Reports to check available"
  fi