#!/usr/bin/env bash
#SBATCH --cpus-per-task=20
#SBATCH --mem='60gb'
#SBATCH --constraint=cal
#SBATCH --time='05:00:00'
source ~soft_bio_267/initializes/init_degenes_hunter

input_file=$1
output_path=$2

clusters_to_enrichment.R -w 16 -i $input_file -o $output_path -f MF,BP,CC,KEGG,Reactome,DO,DGN -p 0.01 -c -M PRS -F -O Human -k ENSEMBL
