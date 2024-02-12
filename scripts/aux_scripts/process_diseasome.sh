#!/usr/bin/env bash
source ~soft_bio_267/initializes/init_python

diseasome_file=$1
diseasome_folder=$2

pushd $diseasome_folder

echo "Phase 1. Extracting and translating genes involved in a disease"
echo "eliminating parenthesis"
awk 'BEGIN{FS="\t";OFS="\t"}{if ( $4 >= 2 && NR != 1){print $3,$7};}' ./data/$diseasome_file | sed 's/([0-9]*)//g' | sed 's/ //g' > preproc_disease_genes
desaggregate_column_data -i preproc_disease_genes -x 2 > disaggregated_preproc_disease_genes
standard_name_replacer -u -I ../../translators/symbol_HGNC -i disaggregated_preproc_disease_genes -c 2 | aggregate_column_data -i - -x 1 -a 2 > aggregated_preproc_disease_genes
echo "Symbol IDS to HGNC passed"
awk '{genes=split($2,a,","); if (genes >= 30) {print $0}}' aggregated_preproc_disease_genes > processed_disease_genes
echo "Selected just groups with 30 or more genes"
echo "Phase 2. Extracting Group disorder -> disease"
awk 'BEGIN{FS="\t";OFS="\t"}{if ( $4 >= 2 && NR != 1){print $2,$3};}' ./data/$diseasome_file | sed 's/([0-9]*)//g' \
| sed 's/ //g' > disase_disgroup
merge_tabular disase_disgroup processed_disease_genes | awk 'BEGIN{FS="\t";OFS="\t"}{if ( $3 != "-"){print $0};}' > ./processed_data/diseasome_disgroup_genes

rm preproc_disease_genes
rm disaggregated_preproc_disease_genes
rm aggregated_preproc_disease_genes
rm disase_disgroup
rm processed_disease_genes

popd 


