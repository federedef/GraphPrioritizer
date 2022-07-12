#!/usr/bin/env bash
export PATH=~soft_bio_267/programs/x86_64/scripts:$PATH
diseasome_file=$1

echo "eliminating parenthesis"
awk 'BEGIN{FS="\t";OFS="\t"}{if ( $4 >= 2 && NR != 1){print $2,$7};}' $diseasome_file | sed 's/([0-9]*)//g' | sed 's/ //g' > processed_diseasome
desaggregate_column_data.rb -i processed_diseasome -x 1 > disaggregated_processed_diseasome
idconverter.rb -d ../translators/symbol_HGNC -i disaggregated_processed_diseasome -c 1 | aggregate_column_data.rb -i - -x 0 -a 1 > aggregated_diseasome
echo "Symbol IDS to HGNC passed"
awk '{genes=split($2,a,","); if (genes >= 2) {print $0}}' aggregated_diseasome > processed_diseasome
echo "Selected just groups with 2 or more genes"
rm disaggregated_processed_diseasome aggregated_diseasome
