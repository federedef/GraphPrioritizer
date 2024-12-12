source ~soft_bio_267/initializes/init_python
source $input_path/scripts/aux_scripts/aux_daemon.sh

mkdir -p ./input/upgraded/input_processed/
mkdir -p ./input/downgraded/input_processed/
touch ./input/upgraded/input_processed/info_process_file

declare -A tag_filter 
tag_filter[phenotype]='HP:'
tag_filter[disease]='MONDO:'
tag_filter[function]='GO:'
tag_filter[pathway]='REACT:'
tag_filter[interaction]='RO:0002434' # RO:0002434 <=> interacts with
tag_filter[molecular_function]='GO:0003674'
tag_filter[biological_process]='GO:0008150'
tag_filter[cellular_component]='GO:0005575'

# For upgraded #
################
datatime="upgraded"
# Ontologies
# ----------
for sample in phenotype disease function ; do
  zgrep ${tag_filter[$sample]} ./input/$datatime/input_raw/gene_${sample}.all.tsv.gz | grep 'NCBITaxon:9606' | grep "HGNC:" | \
  aggregate_column_data -i - -x 1 -a 5 > ./input/$datatime/input_processed/$sample # | head -n 230
done
## Creating paco files for hpo.
semtools -i ./input/$datatime/input_processed/phenotype -o ./input/$datatime/input_processed/filtered_phenotype -O HPO -S "," -c -T HP:0000001
cat ./input/$datatime/input_processed/filtered_phenotype | tr -s "|" "," > ./input/$datatime/input_processed/phenotype
rm ./input/$datatime/input_processed/filtered_phenotype
rm rejected_profs
## Creating paco files for each go branch.
gene_ontology=( molecular_function cellular_component biological_process )
for branch in ${gene_ontology[@]} ; do
  semtools -i ./input/$datatime/input_processed/function -o ./input/$datatime/input_processed/filtered_$branch -O GO -S "," -c -T ${tag_filter[$branch]}
  cat ./input/$datatime/input_processed/filtered_$branch | tr -s "|" "," > ./input/$datatime/input_processed/$branch
  rm ./rejected_profs
  rm ./input/$datatime/input_processed/filtered_$branch
done
rm ./input/$datatime/input_processed/function
# Protein associations
# --------------------
## STRING 11.5 
process_string $datatime
## HIPPO current
process_hippie $datatime
# DEPMAP
# -----------
process_gen_int $datatime "effect"
process_gen_int $datatime "exprs"
# GENE-TF interaction.ls
# ----------------------
standard_name_replacer -i ./input/$datatime/input_raw/gene_TF -I ./translators/symbol_HGNC -c 1,2 -u | sed 's/HGNC:/TF:/2g' > ./input/$datatime/input_processed/gene_TF
# HGNC-groups
# -----------
process_hgnc_group $datatime
# Phenotypic Series
# -----------------
get_PS_gene_relation.py -i "/mnt/home/users/bio_267_uma/federogc/projects/GraphPrioritizer/input/downloaded_raw/phenotypic_series/series_data" -o "./input/$datatime/input_processed/PS_genes"
desaggregate_column_data -i ./input/$datatime/input_processed/PS_genes -x 2 > ./input/$datatime/input_processed/tmp 
standard_name_replacer -i ./input/$datatime/input_processed/tmp -I ./translators/symbol_HGNC -c 2 -u | awk 'BEGIN{FS="\t";OFS="\t"}{print $2,$1}' > ./input/$datatime/input_processed/gene_PS
rm ./input/$datatime/input_processed/PS_genes ./input/$datatime/input_processed/tmp 
# Reactions
# ---------
zgrep "REACT:" ./input/$datatime/input_raw/gene_pathway.all.tsv.gz |  grep 'NCBITaxon:9606' | grep "HGNC:" | \
  cut -f 1,5 > ./input/$datatime/input_processed/pathway

# For downgraded #
##################
datatime="downgraded"
# Ontologies
# ----------
echo -e "in disease"
zgrep ${tag_filter[disease]} ./input/$datatime/input_raw/gene_disease.9606.tsv.gz | grep 'NCBITaxon:9606' | grep "HGNC:" | \
aggregate_column_data -i - -x 1 -a 5 > ./input/$datatime/input_processed/disease 

tail -n +2 ./input/$datatime/input_raw/HPO_genes.txt | cut -f 1,4 | \
 aggregate_column_data -i - -x 2 -a 1 | standard_name_replacer -i - -I ./translators/symbol_HGNC -c 1 -u > ./input/$datatime/input_processed/phenotype

echo "in go"
gzip -d -c ./input/downgraded/input_raw/gene_functions.gaf.gz > ./input/downgraded/input_raw/gene_functions
echo "remove header"
#tail -n +31 ./input/$datatime/input_raw/gene_functions | cut -f 3,5,7 | \
#  grep -E -w "EXP|IDA|IPI|IMP|IGI|IEP|IC|HTP|HDA|HMP|HGI|HEP" | \
#  cut -f 1,2 | aggregate_column_data -i - -x 1 -a 2 > ./input/$datatime/input_processed/function
tail -n +31 ./input/$datatime/input_raw/gene_functions | cut -f 3,5 | aggregate_column_data -i - -x 1 -a 2 > ./input/$datatime/input_processed/function
standard_name_replacer -i ./input/$datatime/input_processed/function -I ./translators/symbol_HGNC -c 1 -u > tmp && rm ./input/$datatime/input_processed/function
mv tmp ./input/$datatime/input_processed/function

# Creating paco files for hpo.
semtools -i ./input/$datatime/input_processed/phenotype -o ./input/$datatime/input_processed/filtered_phenotype -O ./input/$datatime/input_obo/hp.obo -S "," -c -T HP:0000001
cat ./input/$datatime/input_processed/filtered_phenotype | tr -s "|" "," > ./input/$datatime/input_processed/phenotype
rm ./input/$datatime/input_processed/filtered_phenotype
rm rejected_profs

semtools -i ./input/$datatime/input_processed/disease -o ./input/$datatime/input_processed/filtered_disease -O ./input/$datatime/input_obo/mondo.obo -S "," -c -T MONDO:0000001
cat ./input/$datatime/input_processed/filtered_disease | tr -s "|" "," > ./input/$datatime/input_processed/disease
rm ./input/$datatime/input_processed/filtered_disease
rm rejected_profs

# Creating paco files for each go branch.
gene_ontology=( molecular_function cellular_component biological_process )
for branch in ${gene_ontology[@]} ; do
  semtools -i ./input/$datatime/input_processed/function -o ./input/$datatime/input_processed/filtered_$branch -O ./input/$datatime/input_obo/go.obo -S "," -c -T ${tag_filter[$branch]}
  cat ./input/$datatime/input_processed/filtered_$branch | tr -s "|" "," > ./input/$datatime/input_processed/$branch
  echo -e "$branch is:"
  wc -l ./input/$datatime/input_processed/$branch
  rm ./rejected_profs
  rm ./input/$datatime/input_processed/filtered_$branch
done
rm ./input/$datatime/input_processed/function

# Protein associations
# --------------------
## STRING 11.0
process_string $datatime
## HIPPIE from Paper
standard_name_replacer -i ./input/$datatime/input_raw/hippie.txt -I ./translators/symbol_HGNC -c 1,2 -u > ./input/$datatime/input_processed/hippie_ppi 
# DEPMAP
# -----------
## from paper
cut -f 1,2,3 ./input/$datatime/input_raw/KimCoess_gene | standard_name_replacer -I ./translators/symbol_HGNC -i - -c 1,2 -u > ./input/$datatime/input_processed/KimCoess_gene
## from DepMap
process_gen_int $datatime "effect"
# HGNC-groups
# -----------
process_hgnc_group $datatime
# Reactions
# ---------
cut -f 2- ./input/$datatime/input_raw/ReactomePathways.gmt | sed 's/https:\/\/reactome.org\/content\/detail\//REACT:/g' \
  | sed "s/\t/,/2g" \
  | desaggregate_column_data -i - -x 2 \
  | cut -f 1,2 \
  | standard_name_replacer -i - -I ./translators/symbol_HGNC -c 2 -u \
  | awk '{OFS="\t"}{print $2,$1}' > ./input/$datatime/input_processed/pathway