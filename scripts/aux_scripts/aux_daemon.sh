
function add_header () {
	header=$1
	input_path=$2
	output_path=$3
	if [ -s $input_path ] ; then 
    	echo -e $header | cat - $input_path > $output_path
  	fi
}

function process_string () {
	datatime=$1
	cat ./input/$datatime/input_raw/string_data.txt | tr -s " " "\t" > string_data.txt
  	head -n 1 string_data.txt > header
  	standard_name_replacer -i string_data.txt -I ./translators/ProtEnsemble_HGNC -c 1,2 -u > tmp && rm string_data.txt
  	cat header tmp > tmp_header
  	generate_strings.py -i tmp_header -o ./input/$datatime/input_processed/
  	rm tmp tmp_header
}

function process_hippie () {
	datatime=$1
	grep pubmed ./input/$datatime/input_raw/hippie.txt | cut -f 15,17,18 | awk '{OFS="\t"}{if (NF == 3) print $2,$3,$1}' \
  | standard_name_replacer -i - -I ./translators/symbol_HGNC -c 1,2 > ./input/$datatime/input_processed/hippie_ppi 
}

function process_gen_int () {
  datatime=$1
  genetic_type=$2
  sed 's/([0-9]*)//1g' ./input/$datatime/input_raw/CRISPR_gene_effect | cut -d "," -f 2- | sed 's/,/\t/g' | sed 's/ //g' > ./input/$datatime/input_raw/CRISPR_gene_effect_symbol
  cut -f 1 -d "," ./input/$datatime/input_raw/CRISPR_gene_effect | tr -d "DepMap_ID"  | tr -s "\t" "\n" | sed '1d' >  ./input/$datatime/input_processed/DepMap_effect_rows
  standard_name_replacer -I ./translators/symbol_HGNC -i ./input/$datatime/input_raw/CRISPR_gene_effect_symbol -c 1 -u --transposed > ./input/$datatime/input_processed/genetic_interaction_effect_values
  head -n 1 ./input/$datatime/input_processed/genetic_interaction_effect_values | tr -s "\t" "\n" >  ./input/$datatime/input_processed/DepMap_effect_cols
  sed '1d' ./input/$datatime/input_processed/genetic_interaction_effect_values > ./input/$datatime/input_processed/DepMap_effect
  rm ./input/$datatime/input_raw/CRISPR_gene_effect_symbol ./input/$datatime/input_processed/genetic_interaction_effect_values
}

function process_hgnc_group () {
	datatime=$1
	cut -f 1,14 ./input/$datatime/input_raw/gene_hgncGroup | sed "s/\"//g" | tr -s "|" "," | awk '{if( $2 != "") print $0}' \
    | desaggregate_column_data -i "-" -x 2 | sed 's/\t/\tGROUP:/1g' | sed 1d > ./input/$datatime/input_processed/gene_hgncGroup
}