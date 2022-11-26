#!/usr/bin/env bash
grep -P "^protein_interaction_ka" parsed_non_integrated_rank_positive_stats > groupseed2medians
echo "filtering the groups with less than 0.02 median"
cut -f 4,5,11 groupseed2medians | sort -k1 | awk '{if ($3 <= 0.02) print $0}' > filtered_groupseed2medians
echo "Adding the genes from the seed_groups"
sort -k1 filtered_groupseed2medians > file1
cat /mnt/home/users/bio_267_uma/federogc/projects/backupgenes/production_seedgens > file2

join -j 1 file1 file2 | tr -s " " "\t" > groupseed2medians2genes
rm file1 file2
echo -e  "Cluster_ID\tNum elementos\tMediana\tGenes" | cat - groupseed2medians2genes > clusters_data
echo `wc -l filtered_groupseed2medians`
echo `wc -l groupseed2medians2genes`
rm groupseed2medians2genes

