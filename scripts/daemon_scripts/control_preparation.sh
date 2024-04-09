source ~soft_bio_267/initializes/init_R
source ~soft_bio_267/initializes/init_python
source ~soft_bio_267/initializes/init_ruby
  # # Zampieri  bench  #
  # ####################
  mkdir -p $control_genes_folder/zampieri/processed_data 

  desaggregate_column_data -i ./input/input_processed/disease -x 2 | awk '{OFS="\t"}{print $2,$1}' > terms2annot
  cut -f1 terms2annot | sort | uniq > terms_mondo
  # Extracting OMIM cross reference
  semtools -i terms_mondo -O ./input/input_obo/mondo.obo -o term2omim --xref_sense -k "OMIM:[0-9]*" --list
  awk '{OFS="\t"}{sub(/OMIM:/,"",$2); print $1, $2}' term2omim > tmp && mv tmp term2omim
  standard_name_replacer -i term2omim -I ./translators/mimTitles -c 2 > tmp && mv tmp term2omim
  # Collapse based on similarity text and common direct ancestor
  collapse_similar_childs_into_parental.py -i terms2annot -n term2omim  -O ./input/input_obo/mondo.obo -o "$control_genes_folder/zampieri/processed_data/collapsed_annotations" -r ',/' -t "0.85" --with_annotation
  rm terms2annot
  rm term2omim
  rm terms_mondo

  # Parent | child | gene
  awk '{OFS="\t"}{print $1,$3}' $control_genes_folder/zampieri/processed_data/collapsed_annotations | aggregate_column_data -i - -x 1 -a 2 > disease_genes
  # Parent | gene | disclass 
  get_disorder_class.py -i disease_genes -C $control_genes_folder/zampieri/data/disorder_classes -O ./input/input_obo/mondo.obo -o $control_genes_folder/zampieri/processed_data/disease_genes_disorderclass
  rm disease_genes
  grep -v -E "unclasiffied|multiple" $control_genes_folder/zampieri/processed_data/disease_genes_disorderclass > tmp && mv tmp $control_genes_folder/zampieri/processed_data/disease_genes_disorderclass

  get_disease_classes.rb $control_genes_folder/zampieri/processed_data/disease_genes_disorderclass 30 > $control_genes_folder/zampieri/processed_data/disgroup_gene
  # Getting negatives
  get_negatives_from_disease.py -i $control_genes_folder/zampieri/processed_data/disgroup_gene -o "$control_genes_folder/zampieri/non_disease_gens"
  # Getting Positives
  cp $control_genes_folder/zampieri/processed_data/disgroup_gene "$control_genes_folder/zampieri/disease_gens"

  # # Menche bench #
  # ################
  # mkdir -p $control_genes_folder/menche
  # grep -v -E "RASopathy|Serpinopathy" $control_genes_folder/menche/data/menche_bench.tsv > menche_26 # removing short aggrupation from dataset
  # desaggregate_column_data -i menche_26 -x 2 -s ";" > disaggregated_menche_bench.tsv

  # standard_name_replacer -I ./translators/symbol_HGNC -i disaggregated_menche_bench.tsv -c 2 -u | aggregate_column_data -i - -x 1 -a 2 > $control_genes_folder/menche/disease_gens
  # sed -i 's/ /_/g' $control_genes_folder/menche/disease_gens
  # rm disaggregated_menche_bench.tsv
  # rm menche_26

