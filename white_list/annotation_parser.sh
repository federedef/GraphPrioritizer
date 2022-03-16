#!/usr/bin/env bash

file2parse=$1
types2select=$2 #protein_coding;lncRNA;(...)

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

# Example of execution: ./annotation_parser.sh annotation.gtf protein_coding
