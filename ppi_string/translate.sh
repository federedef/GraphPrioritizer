#!/usr/bin/env bash
input_path="/mnt/home/users/bio_267_uma/federogc/projects/backupgenes"
PATH=$input_path/aux_scripts:$PATH
geneid_translator.rb -t ./input/Ensembl_HGNC_HGNC_ID -f ./input/string_data.txt -c 0,1 > interaction
