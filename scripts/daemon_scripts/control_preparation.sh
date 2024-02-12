source ~soft_bio_267/initializes/init_R
source ~soft_bio_267/initializes/init_python
source ~soft_bio_267/initializes/init_ruby
  # Zampieri  bench  #
  ####################
  mkdir -p $control_genes_folder/zampieri/processed_data 

  get_disease_classes.rb ./control_genes/zampieri/data/zampieri_bench.tsv 30 > $control_genes_folder/zampieri/processed_data/disgroup_gene
  desaggregate_column_data -i $control_genes_folder/zampieri/processed_data/disgroup_gene -x 2 > disaggregated_preproc_disease_genes
  standard_name_replacer -u -I ./translators/entrez_HGNC -i disaggregated_preproc_disease_genes -c 2 | aggregate_column_data -i - -x 1 -a 2 > $control_genes_folder/zampieri/processed_data/disgroup_gene
  # Getting negatives
  get_negatives_from_disease.py -i $control_genes_folder/zampieri/processed_data/disgroup_gene -o "$control_genes_folder/zampieri/non_disease_gens"
  # Getting Positives
  cp $control_genes_folder/zampieri/processed_data/disgroup_gene "$control_genes_folder/zampieri/disease_gens"

  # # Menche bench #
  # ################
  # mkdir -p $control_genes_folder/menche

  # desaggregate_column_data -i $control_genes_folder/menche/data/menche_bench.tsv -x 2 -s ";" > disaggregated_menche_bench.tsv
  # standard_name_replacer -I ./translators/symbol_HGNC -i disaggregated_menche_bench.tsv -c 2 -u | aggregate_column_data -i - -x 1 -a 2 > $control_genes_folder/menche/disease_gens
  # sed -i 's/ /_/g' $control_genes_folder/menche/disease_gens
  # rm disaggregated_menche_bench.tsv

