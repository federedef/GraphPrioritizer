source ~soft_bio_267/initializes/init_R
source ~soft_bio_267/initializes/init_python

  # Diseases Control #
  ####################
  mkdir -p $control_genes_folder/diseasegens/processed_data 

  process_diseasome.sh diseasome_from_paper.tsv $control_genes_folder/diseasegens
  # Getting negatives
  get_negatives_from_disease.py -i $control_genes_folder/diseasegens/processed_data/diseasome_disgroup_genes -o "$control_genes_folder/diseasegens/non_disease_gens"
  # Getting Positives
  cut -f 1,3 $control_genes_folder/diseasegens/processed_data/diseasome_disgroup_genes > "$control_genes_folder/diseasegens/disease_gens"
