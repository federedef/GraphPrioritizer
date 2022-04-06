#!/usr/bin/env bash
keyword=$1
folder_reference="/mnt/home/users/pab_001_uma/pedro/proyectos/sylentis_ojo/extern_data"
file2subset="${folder_reference}/protein.aliases.v11.5.txt"
interaction_file="${folder_reference}/string_data.txt"

mkdir -p input
cp ${interaction_file} ./input
grep -w "$keyword" $file2subset | cut -f 1,2 > ./input/$1
#keyword="Ensembl_HGNC_HGNC_ID"
