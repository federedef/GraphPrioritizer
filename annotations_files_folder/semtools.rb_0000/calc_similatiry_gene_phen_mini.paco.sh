#!/usr/bin/env bash
##JOB_GROUP_ID=autoflow_template.af_1633781597
#SBATCH --cpus-per-task=1
#SBATCH --mem=4gb
#SBATCH --time=20:00:00
#SBATCH --error=job.%J.err
#SBATCH --output=job.%J.out
hostname
flow_logger -e /mnt/home/users/bio_267_uma/federogc/projects/backupgenes/annotations_files_folder/.wf_log/semtools.rb_0000 -s calc_similatiry_gene_phen_mini.paco
source ~josecordoba/software/initializes/init_semtools_script
echo -e "gene_phen_mini.paco\tct" > tracker

time semtools.rb -i /mnt/home/users/bio_267_uma/federogc/projects/backupgenes/gene_phen_mini.paco -o similarity_pair.txt -k "HP:" -S ',' -O -s lin

flow_logger -e /mnt/home/users/bio_267_uma/federogc/projects/backupgenes/annotations_files_folder/.wf_log/semtools.rb_0000 -f calc_similatiry_gene_phen_mini.paco
echo 'General time'
times
