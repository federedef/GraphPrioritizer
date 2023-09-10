source ~soft_bio_267/initializes/init_R
source ~soft_bio_267/initializes/init_python

  # Zampieri  bench  #
  ####################
  mkdir -p $control_genes_folder/zampieri/processed_data 

  process_diseasome.sh zampieri_bench.tsv $control_genes_folder/zampieri
  # Getting negatives
  get_negatives_from_disease.py -i $control_genes_folder/zampieri/processed_data/diseasome_disgroup_genes -o "$control_genes_folder/zampieri/non_disease_gens"
  # Getting Positives
  cut -f 1,3 $control_genes_folder/zampieri/processed_data/diseasome_disgroup_genes > "$control_genes_folder/zampieri/disease_gens"

  # Menche bench #
  ################
  mkdir -p $control_genes_folder/menche

  desaggregate_column_data.py -i $control_genes_folder/menche/data/menche_bench.tsv -x 2 -s ";" > disaggregated_menche_bench.tsv
  standard_name_replacer.py -I ./translators/symbol_HGNC -i disaggregated_menche_bench.tsv -c 2 -u | aggregate_column_data.py -i - -x 1 -a 2 > $control_genes_folder/menche/disease_gens
  sed -i 's/ /_/g' $control_genes_folder/menche/disease_gens
  rm disaggregated_menche_bench.tsv

