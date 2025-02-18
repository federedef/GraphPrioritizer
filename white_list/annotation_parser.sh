#!/usr/bin/env bash

types2select=$1 #protein_coding;lncRNA;(...)
file2parse="gencode.v35.annotation.gtf"
wget "ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_35/gencode.v35.annotation.gtf.gz"
gzip -d gencode.v35.annotation.gtf.gz


awk 'BEGIN{FS="\t"}{if ($3 ~ /gene/) { print $9 }}' $file2parse | awk 'BEGIN{FS=";";OFS="\t";}{print $1,$2,$3,$5}' > parsed_${file2parse}

echo "The number of each type of genes are:"
cut -f2 parsed_${file2parse} | cut -f3 -d " " | sort | uniq -c | sort -k1 -r

echo "Select just those genes with gene_type in $2"
types2select=`echo $types2select | tr ";" " "`
rm -f white_list
rm -f hgnc_white_list

for type in $types2select ; do	
  grep $type parsed_${file2parse} | grep "hgnc_id" | cut -f 4,3,2 >> white_list
  grep $type parsed_${file2parse} | grep "hgnc_id" | cut -f 4 | cut -f 3 -d " " | tr -d '"'>> hgnc_white_list
done

sort hgnc_white_list -o hgnc_white_list
rm parsed_${file2parse}
rm white_list
rm gencode.v35.annotation.gtf.gz

# Example of execution: ./annotation_parser.sh protein_coding
