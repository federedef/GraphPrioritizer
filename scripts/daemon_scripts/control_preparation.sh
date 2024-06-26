source ~soft_bio_267/initializes/init_R
source ~soft_bio_267/initializes/init_python
source ~soft_bio_267/initializes/init_ruby
# # Zampieri  bench  #
# ####################
mkdir -p $control_genes_folder/zampieri/processed_data 

# Parse documento comorbid (disease_txt, disease_code, genes)
parse_morbid_omim.py $control_genes_folder/zampieri/data/omim_data/morbidmap.txt > parsed_morbid
# Extracting OMIM cross reference (term2omim_code)
cut -f2 parsed_morbid | sort | uniq > omims
semtools -i omims -O "MONDO" -o term2omim_code -k "OMIM:[0-9]*" --list
# Extracting annotation and txt assoc (term2annot, term2omim_txt)
standard_name_replacer -i parsed_morbid -I term2omim_code -c 2 -u > omimtxt_mondo_genes
cut -f 1,2 omimtxt_mondo_genes | awk '{FS="\t";OFS="\t"}{print $2,$1}' > term2omim_txt
cut -f 2,3 omimtxt_mondo_genes > term2annot
# Collapse based on similarity text and common direct ancestor
collapse_similar_childs_into_parental.py -i term2annot -n term2omim_txt  -O `semtools -d list | grep "MONDO"` -o "$control_genes_folder/zampieri/processed_data/collapsed_annotations" -r ',/' -t "0.80" --with_annotation
rm term2annot
rm term2omim_txt
rm omims
rm term2omim_code

# Parent | genes
desaggregate_column_data -i control_genes/zampieri/processed_data/collapsed_annotations -x 3 | sed "s/ //" \
| awk '{OFS="\t"}{if (NF==3) print $0}' | standard_name_replacer -i - -I ./translators/symbol_HGNC -c 3 -u \
| cut -f 2,3 | aggregate_column_data -i - -x 1 -a 2 > disease_genes
# Parent | gene | disclass 
get_disorder_class.py -i disease_genes -C $control_genes_folder/zampieri/data/disorder_classes -O `semtools -d list | grep "MONDO"` -o $control_genes_folder/zampieri/processed_data/disease_genes_disorderclass
rm disease_genes
grep -v -E "unclasiffied|multiple" $control_genes_folder/zampieri/processed_data/disease_genes_disorderclass > tmp && mv tmp $control_genes_folder/zampieri/processed_data/disease_genes_disorderclass

get_disease_classes.rb $control_genes_folder/zampieri/processed_data/disease_genes_disorderclass 30 > $control_genes_folder/zampieri/processed_data/disgroup_gene
# Getting negatives
get_negatives_from_disease.py -i $control_genes_folder/zampieri/processed_data/disgroup_gene -o "$control_genes_folder/zampieri/non_disease_gens"
# Getting Positives
cp $control_genes_folder/zampieri/processed_data/disgroup_gene "$control_genes_folder/zampieri/disease_gens"

# Menche bench #
################
mkdir -p $control_genes_folder/menche
grep -v -E "Rare_genetic_respiratory_disease|RASopathy|Serpinopathy" $control_genes_folder/menche/data/menche_bench.tsv > menche_26 # removing short aggrupation from dataset
desaggregate_column_data -i menche_26 -x 2 -s ";" > disaggregated_menche_bench.tsv

standard_name_replacer -I ./translators/symbol_HGNC -i disaggregated_menche_bench.tsv -c 2 -u | aggregate_column_data -i - -x 1 -a 2 > $control_genes_folder/menche/disease_gens
sed -i 's/ /_/g' $control_genes_folder/menche/disease_gens
rm disaggregated_menche_bench.tsv
rm menche_26

