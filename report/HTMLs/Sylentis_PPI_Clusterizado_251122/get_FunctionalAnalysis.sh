#!/usr/bin/env bash
#SBATCH --cpus-per-task=20
#SBATCH --mem='60gb'
#SBATCH --constraint=cal
#SBATCH --time='05:00:00'
source ~soft_bio_267/initializes/init_degenes_hunter

clusters_to_enrichment.R -w 16 -i ./FunctionalAnalysisInput -o ./Final_results/Functional_analysis_from_clusters -f MF,BP,CC,KEGG,Reactome,DO,DGN -p 0.01 -c -M PRS -F -O Human -k ENSEMBL
