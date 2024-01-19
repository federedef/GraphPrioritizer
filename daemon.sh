#!/usr/bin/env bash
. ~soft_bio_267/initializes/init_autoflow 

#Input variables.
exec_mode=$1 
#add_opt=$2 
add_opt=${@: -1} # TODO: Check this option


# Used Paths.
export input_path=`pwd`
export PATH=/mnt/home/users/bio_267_uma/federogc/sys_bio_lab_scripts:$input_path/scripts/aux_scripts:~soft_bio_267/programs/x86_64/scripts:$PATH
export autoflow_scripts=$input_path/scripts/autoflow_scripts
daemon_scripts=$input_path/scripts/daemon_scripts
export control_genes_folder=$input_path/control_genes
export output_folder=$SCRATCH/executions/GraphPrioritizer
report_folder=$output_folder/report

# Custom variables.
annotations=" disease phenotype molecular_function biological_process cellular_component"
annotations+=" string_ppi hippie_ppi"
annotations+=" string_ppi_textmining string_ppi_database string_ppi_experimental string_ppi_coexpression string_ppi_cooccurence string_ppi_fusion string_ppi_neighborhood"
annotations+=" DepMap_effect_pearson DepMap_effect_spearman kim_coess_gene"
annotations+=" pathway gene_TF gene_hgncGroup gene_PS"
integrated_annotations="disease phenotype molecular_function biological_process cellular_component string_ppi_exp pathway gene_TF gene_hgncGroup DepMap_effect_pearson gene_PS"
integrated_annotations="string_ppi_textmining string_ppi_database string_ppi_experimental string_ppi_coexpression string_ppi_cooccurence string_ppi_fusion string_ppi_neighborhood"
integrated_annotations="phenotype biological_process string_ppi_textmining string_ppi_coexpression gene_hgncGroup"
integrated_annotations="phenotype biological_process string_ppi_textmining string_ppi_coexpression string_ppi_experimental gene_hgncGroup kim_coess_gene pathway"
kernels="ka rf ct el node2vec raw_sim"
integration_types="mean integration_mean_by_presence median max"
net2custom=$input_path'/net2json' 
control_pos=$input_path'/control_pos'
control_neg=$input_path'/control_neg'
production_seedgens=$input_path'/production_seedgens'
whitelist="whitelist"

echo "$annotations"

kernels_varflow=`echo $kernels | tr " " ";"`
annotations_varflow=`echo $annotations | tr " " ";"`

if [ "$exec_mode" == "download_layers" ] ; then

  #########################################################
  # STAGE 1 DOWNLOAD DATA
  #########################################################
  . ~soft_bio_267/initializes/init_R
  . ~soft_bio_267/initializes/init_ruby

  mkdir -p ./input/upgraded
  mkdir -p ./input/upgraded/input_obo
  mkdir -p ./input/upgraded/input_raw
  mkdir -p ./input/upgraded/input_processed
  mkdir -p ./input/downgraded
  mkdir -p ./input/downgraded/input_obo
  mkdir -p ./input/downgraded/input_raw
  mkdir -p ./input/downgraded/input_processed

  # Pass raw downloaded files.
  if [ -s ./input/data_downloaded/aux ] ; then
    echo "removing pre-existed obos files"
    find ./input/data_downloaded/aux -name "*.obo*" -delete 
  fi


  # Downloading ONTOLOGIES and PATHWAY ANNOTATION files from MONARCH.
  # Upgraded version # MONDO, GO, HP, REACTOME
  downloader.rb -i ./input/upgraded_monarch -o ./input/monarch
  cp ./input/monarch/raw/monarch/tsv/all_associations/* ./input/upgraded/input_raw
  rm -r ./input/monarch
  ## GO Annotations 
  wget	http://purl.obolibrary.org/obo/go/go-basic.obo -O ./input/upgraded/input_obo/go.obo
  ## HP
  wget	http://purl.obolibrary.org/obo/hp.obo -O ./input/upgraded/input_obo/hp.obo
  ## MONDO
  wget	http://purl.obolibrary.org/obo/mondo.obo -O ./input/upgraded/input_obo/mondo.obo


  # Downgraded version # Reactome
  cp ./input/downloaded_raw/raw_menche/ReactomePathways.gmt ./input/downgraded/input_raw/ReactomePathways.gmt
  # Downgraded version # MONDO, HP, GO
  # Annotations #
  #-------------#
  cp ./input/downloaded_raw/raw_menche/HPO_phenotype_to_genes.txt ./input/downgraded/input_raw/HPO_genes.txt
  wget https://data.monarchinitiative.org/201902/tsv/gene_associations/gene_disease.9606.tsv.gz -O ./input/downgraded/input_raw/gene_disease.9606.tsv.gz
  ##GO Annotations 2018-11-15
  wget https://release.geneontology.org/2018-11-15/annotations/goa_human.gaf.gz -O ./input/downgraded/input_raw/gene_functions.gaf.gz
  
  ## OBOS
  #-------#
  ##GO 2018-11-15 ( just before 2018-11-24 Menche release )
  wget https://release.geneontology.org/2018-11-15/ontology/go-basic.obo -O ./input/downgraded/input_obo/go.obo
  ##HP OBO 2018-10-09
  wget https://raw.githubusercontent.com/obophenotype/human-phenotype-ontology/v2018-10-09/hp.obo -O ./input/downgraded/input_obo/hp.obo
  ## MONDO OBO 2018-12-02
  wget https://github.com/monarch-initiative/mondo/releases/download/v2018-12-02/mondo.obo -O ./input/downgraded/input_obo/mondo.obo


  # # Downloading PROTEIN INTERACTIONS and ALIASES from STRING.
  # Upgraded version
  wget https://stringdb-static.org/download/protein.links.detailed.v11.5/9606.protein.links.detailed.v11.5.txt.gz -O ./input/upgraded/input_raw/string_data.txt.gz
  gzip -d ./input/upgraded/input_raw/string_data.txt.gz
  # Downgraded version
  wget https://stringdb-static.org/download/protein.links.detailed.v11.0/9606.protein.links.detailed.v11.0.txt.gz -O ./input/downgraded/input_raw/string_data.txt.gz
  gzip -d ./input/downgraded/input_raw/string_data.txt.gz


  # Downloading PROTEIN INTERACTION form HIPPIE.
  # Upgraded version
  wget https://cbdm-01.zdv.uni-mainz.de/~mschaefer/hippie/HIPPIE-current.mitab.txt -O ./input/upgraded/input_raw/hippie.txt
  # Downgraded version
  #wget https://cbdm-01.zdv.uni-mainz.de/~mschaefer/hippie/HIPPIE-2.2.mitab.txt -O ./input/downgraded/input_raw/hippie.txt
  cp ./input/downloaded_raw/raw_menche/ppi.tsv ./input/downgraded/input_raw/hippie.txt

  # Downloading GENETIC INTERACTIONS from DEPMAP.
  # Upgraded version
  wget https://ndownloader.figshare.com/files/34990033 -O ./input/upgraded/input_raw/CRISPR_gene_effect 
  wget https://ndownloader.figshare.com/files/34989919 -O ./input/upgraded/input_raw/CRISPR_gene_exprs 
  # Gene Expression: https://ndownloader.figshare.com/files/34989919
  # Cell Surpervivence score: https://ndownloader.figshare.com/files/34008491
  # Downgraded version menche version
  wget https://www.life-science-alliance.org/content/lsa/2/2/e201800278/DC5/embed/inline-supplementary-material-5.txt -O ./input/downgraded/input_raw/KimCoess_gene
  # Downgraded version DepMap version
  cp ./input/downloaded_raw/gene_effect.csv ./input/downgraded/input_raw/CRISPR_gene_effect 

  # Downloading Gen-Transcriptional Factor relation.
  # https://rescued.omnipathdb.org/
  # 25-Feb-2021
  # Upgraded version
  get_gen_TF_data.R -O ./input/upgraded/input_raw/gene_TF
  rm -r omnipathr-log
  # Downgraded version
  get_gen_TF_data.R -O ./input/downgraded/input_raw/gene_TF
  rm -r omnipathr-log
  
  #Downloading HGNC_group
  # Upgraded version
  # TEST:   hgnc_complete_set_2024-01-01.txt
  wget http://ftp.ebi.ac.uk/pub/databases/genenames/hgnc/archive/monthly/tsv/hgnc_complete_set_2022-04-01.txt -O ./input/upgraded/input_raw/gene_hgncGroup
  # Downgraded version
  wget http://ftp.ebi.ac.uk/pub/databases/genenames/hgnc/archive/quarterly/tsv/hgnc_complete_set_2020-07-01.txt -O ./input/downgraded/input_raw/gene_hgncGroup

elif [ "$exec_mode" == "download_translators" ] ; then

  ############################
  ## Obtain TRANSLATOR TABLES.
  mkdir -p ./translators

  # Downloading ProtEnsemble_HGNC from STRING.
  wget https://stringdb-static.org/download/protein.aliases.v11.5/9606.protein.aliases.v11.5.txt.gz -O ./translators/protein_aliases.v11.5.txt.gz
  gzip -d translators/protein_aliases.v11.5.txt.gz
  grep -w "Ensembl_HGNC_HGNC_ID" translators/protein_aliases.v11.5.txt | cut -f 1,2 > ./translators/ProtEnsemble_HGNC
  rm ./translators/protein_aliases.v11.5.txt

  # Downloading Ensemble_HGNC from BioMart

  # TODO

  # Downloading HGNC_symbol
  wget http://ftp.ebi.ac.uk/pub/databases/genenames/hgnc/archive/monthly/tsv/hgnc_complete_set_2022-04-01.txt -O ./translators/HGNC_symbol
  awk '{OFS="\t"}{print $2,$1}' ./translators/HGNC_symbol > ./translators/symbol_HGNC
  awk '{FS="\t";OFS="\t"}{print $19,$1}' ./translators/HGNC_symbol > ./translators/entrez_HGNC

  # The other direction symbol_HGNC
  awk '{OFS="\t"}{print $2,$1}' ./translators/HGNC_symbol > ./translators/symbol_HGNC

elif [ "$exec_mode" == "process_download" ] ; then
  source ~soft_bio_267/initializes/init_python

  mkdir -p ./input/upgraded/input_processed/
  mkdir -p ./input/downgraded/input_processed/
  touch ./input/upgraded/input_processed/info_process_file

  declare -A tag_filter 
  tag_filter[phenotype]='HP:'
  tag_filter[disease]='MONDO:'
  tag_filter[function]='GO:'
  tag_filter[pathway]='REACT:'
  tag_filter[interaction]='RO:0002434' # RO:0002434 <=> interacts with
  tag_filter[molecular_function]='GO:0003674'
  tag_filter[biological_process]='GO:0008150'
  tag_filter[cellular_component]='GO:0005575'

  # For upgraded #
  ################

  datatime="upgraded"
  # # PROCESS ONTOLOGIES #
  for sample in phenotype disease function ; do
    zgrep ${tag_filter[$sample]} ./input/$datatime/input_raw/gene_${sample}.all.tsv.gz | grep 'NCBITaxon:9606' | grep "HGNC:" | \
    aggregate_column_data -i - -x 1 -a 5 > ./input/$datatime/input_processed/$sample # | head -n 230
  done

  ## Creating paco files for hpo.
  semtools -i ./input/$datatime/input_processed/phenotype -o ./input/$datatime/input_processed/filtered_phenotype -O HPO -S "," -c -T HP:0000001
  cat ./input/$datatime/input_processed/filtered_phenotype | tr -s "|" "," > ./input/$datatime/input_processed/phenotype
  rm ./input/$datatime/input_processed/filtered_phenotype
  rm rejected_profs

  ## Creating paco files for each go branch.
  gene_ontology=( molecular_function cellular_component biological_process )
  for branch in ${gene_ontology[@]} ; do
    semtools -i ./input/$datatime/input_processed/function -o ./input/$datatime/input_processed/filtered_$branch -O GO -S "," -c -T ${tag_filter[$branch]}
    cat ./input/$datatime/input_processed/filtered_$branch | tr -s "|" "," > ./input/$datatime/input_processed/$branch
    rm ./rejected_profs
    rm ./input/$datatime/input_processed/filtered_$branch
  done
  rm ./input/$datatime/input_processed/function

  # PROCESS REACTIONS 
  zgrep "REACT:" ./input/$datatime/input_raw/gene_pathway.all.tsv.gz |  grep 'NCBITaxon:9606' | grep "HGNC:" | \
    cut -f 1,5 > ./input/$datatime/input_processed/pathway

  # PROCESS PROTEIN INTERACTIONS
  ## STRING 11.5 | 11.0
  cat ./input/$datatime/input_raw/string_data.txt | tr -s " " "\t" > string_data.txt
  head -n 1 string_data.txt > header
  standard_name_replacer -i string_data.txt -I ./translators/ProtEnsemble_HGNC -c 1,2 -u > tmp && rm string_data.txt
  cat header tmp > tmp_header
  generate_strings.py -i tmp_header -o ./input/$datatime/input_processed/
  rm tmp tmp_header

  ## HIPPO
  # current v2_2
  grep pubmed ./input/$datatime/input_raw/hippie.txt | cut -f 15,17,18 | awk '{OFS="\t"}{if (NF == 3) print $2,$3,$1}' \
  | standard_name_replacer -i - -I ./translators/symbol_HGNC -c 1,2 > ./input/$datatime/input_processed/hippie_ppi 

  # PROCESS GENETIC INTERACTIONS # | cut -f 1-100 | head -n 
  sed 's/([0-9]*)//1g' ./input/$datatime/input_raw/CRISPR_gene_effect | cut -d "," -f 2- | sed 's/,/\t/g' | sed 's/ //g' > ./input/$datatime/input_raw/CRISPR_gene_effect_symbol
  cut -f 1 -d "," ./input/$datatime/input_raw/CRISPR_gene_effect | tr -d "DepMap_ID"  | tr -s "\t" "\n" | sed '1d' >  ./input/$datatime/input_processed/DepMap_effect_rows
  standard_name_replacer -I ./translators/symbol_HGNC -i ./input/$datatime/input_raw/CRISPR_gene_effect_symbol -c 1 -u --transposed > ./input/$datatime/input_processed/genetic_interaction_effect_values
  head -n 1 ./input/$datatime/input_processed/genetic_interaction_effect_values | tr -s "\t" "\n" >  ./input/$datatime/input_processed/DepMap_effect_cols
  sed '1d' ./input/$datatime/input_processed/genetic_interaction_effect_values > ./input/$datatime/input_processed/DepMap_effect
  rm ./input/$datatime/input_raw/CRISPR_gene_effect_symbol ./input/$datatime/input_processed/genetic_interaction_effect_values

  # PROCESS GENETIC INTERACTIONS # | cut -f 1-100 | head -n 
  sed 's/([0-9]*)//1g' ./input/$datatime/input_raw/CRISPR_gene_exprs | cut -d "," -f 2- | sed 's/,/\t/g' | sed 's/ //g' > ./input/$datatime/input_raw/CRISPR_gene_exprs_symbol
  cut -f 1 -d "," ./input/$datatime/input_raw/CRISPR_gene_exprs | tr -d "DepMap_ID"  | tr -s "\t" "\n" | sed '1d' >  ./input/$datatime/input_processed/DepMap_exprs_rows
  standard_name_replacer -I ./translators/symbol_HGNC -i ./input/$datatime/input_raw/CRISPR_gene_exprs_symbol -c 1 -u --transposed > ./input/$datatime/input_processed/genetic_interaction_exprs_values
  head -n 1 ./input/$datatime/input_processed/genetic_interaction_exprs_values | tr -s "\t" "\n" >   ./input/$datatime/input_processed/DepMap_exprs_cols
  sed '1d' ./input/$datatime/input_processed/genetic_interaction_exprs_values > ./input/$datatime/input_processed/DepMap_exprs
  rm ./input/$datatime/input_raw/CRISPR_gene_exprs_symbol ./input/$datatime/input_processed/genetic_interaction_exprs_values

  # Translating to GENE-TF interaction.ls
  standard_name_replacer -i ./input/$datatime/input_raw/gene_TF -I ./translators/symbol_HGNC -c 1,2 -u | sed 's/HGNC:/TF:/2g' > ./input/$datatime/input_processed/gene_TF

  # Formatting data_columns
  cut -f 1,14 ./input/$datatime/input_raw/gene_hgncGroup | sed "s/\"//g" | tr -s "|" "," | awk '{if( $2 != "") print $0}' \
    | desaggregate_column_data -i "-" -x 2 | sed 's/\t/\tGROUP:/1g' | sed 1d > ./input/$datatime/input_processed/gene_hgncGroup

  # Formatting PS-Genes
  get_PS_gene_relation.py -i "/mnt/home/users/bio_267_uma/federogc/projects/GraphPrioritizer/input/downloaded_raw/phenotypic_series/series_data" -o "./input/$datatime/input_processed/PS_genes"
  desaggregate_column_data -i ./input/$datatime/input_processed/PS_genes -x 2 > ./input/$datatime/input_processed/tmp 
  standard_name_replacer -i ./input/$datatime/input_processed/tmp -I ./translators/symbol_HGNC -c 2 -u | awk 'BEGIN{FS="\t";OFS="\t"}{print $2,$1}' > ./input/$datatime/input_processed/gene_PS
  rm ./input/$datatime/input_processed/PS_genes ./input/$datatime/input_processed/tmp 

  # For downgraded #
  ##################

  datatime="downgraded"
  # PROCESS ONTOLOGIES #
  echo -e "in disease"
  zgrep ${tag_filter[disease]} ./input/$datatime/input_raw/gene_disease.9606.tsv.gz | grep 'NCBITaxon:9606' | grep "HGNC:" | \
  aggregate_column_data -i - -x 1 -a 5 > ./input/$datatime/input_processed/disease 

  tail -n +2 ./input/$datatime/input_raw/HPO_genes.txt | cut -f 1,4 | \
   aggregate_column_data -i - -x 2 -a 1 | standard_name_replacer -i - -I ./translators/symbol_HGNC -c 1 -u > ./input/$datatime/input_processed/phenotype

  echo "in go"
  gzip -d ./input/downgraded/input_raw/gene_functions.gaf.gz
  mv ./input/downgraded/input_raw/gene_functions.gaf ./input/downgraded/input_raw/gene_functions
  echo "remove header"
  tail -n +31 ./input/$datatime/input_raw/gene_functions | cut -f 3,5 | aggregate_column_data -i - -x 1 -a 2 > ./input/$datatime/input_processed/function
  standard_name_replacer -i ./input/$datatime/input_processed/function -I ./translators/symbol_HGNC -c 1 -u > tmp && rm ./input/$datatime/input_processed/function
  mv tmp ./input/$datatime/input_processed/function

  # Creating paco files for hpo.
  semtools -i ./input/$datatime/input_processed/phenotype -o ./input/$datatime/input_processed/filtered_phenotype -O ./input/$datatime/input_obo/hp.obo -S "," -c -T HP:0000001
  cat ./input/$datatime/input_processed/filtered_phenotype | tr -s "|" "," > ./input/$datatime/input_processed/phenotype
  rm ./input/$datatime/input_processed/filtered_phenotype
  rm rejected_profs

  semtools -i ./input/$datatime/input_processed/disease -o ./input/$datatime/input_processed/filtered_disease -O ./input/$datatime/input_obo/mondo.obo -S "," -c -T MONDO:0000001
  cat ./input/$datatime/input_processed/filtered_disease | tr -s "|" "," > ./input/$datatime/input_processed/disease
  rm ./input/$datatime/input_processed/filtered_disease
  rm rejected_profs

  # Creating paco files for each go branch.
  gene_ontology=( molecular_function cellular_component biological_process )
  for branch in ${gene_ontology[@]} ; do
    semtools -i ./input/$datatime/input_processed/function -o ./input/$datatime/input_processed/filtered_$branch -O ./input/$datatime/input_obo/go.obo -S "," -c -T ${tag_filter[$branch]}
    cat ./input/$datatime/input_processed/filtered_$branch | tr -s "|" "," > ./input/$datatime/input_processed/$branch
    rm ./rejected_profs
    rm ./input/$datatime/input_processed/filtered_$branch
  done
  rm ./input/$datatime/input_processed/function

  # PROCESS PROTEIN INTERACTIONS
  # STRING 11.5 | 11.0
  cat ./input/$datatime/input_raw/string_data.txt | tr -s " " "\t" > string_data.txt
  head -n 1 string_data.txt > header
  standard_name_replacer -i string_data.txt -I ./translators/ProtEnsemble_HGNC -c 1,2 -u > tmp && rm string_data.txt
  cat header tmp > tmp_header
  generate_strings.py -i tmp_header -o ./input/$datatime/input_processed/
  rm tmp tmp_header

  # DEPMAP
  cut -f 1,2,3 ./input/$datatime/input_raw/KimCoess_gene | standard_name_replacer -I ./translators/symbol_HGNC -i - -c 1,2 -u > ./input/$datatime/input_processed/KimCoess_gene
  # PROCESS GENETIC INTERACTIONS # | cut -f 1-100 | head -n 
  sed 's/([0-9]*)//1g' ./input/$datatime/input_raw/CRISPR_gene_effect | cut -d "," -f 2- | sed 's/,/\t/g' | sed 's/ //g' > ./input/$datatime/input_raw/CRISPR_gene_effect_symbol
  cut -f 1 -d "," ./input/$datatime/input_raw/CRISPR_gene_effect | tr -d "DepMap_ID"  | tr -s "\t" "\n" | sed '1d' >  ./input/$datatime/input_processed/DepMap_effect_rows
  standard_name_replacer -I ./translators/symbol_HGNC -i ./input/$datatime/input_raw/CRISPR_gene_effect_symbol -c 1 -u --transposed > ./input/$datatime/input_processed/genetic_interaction_effect_values
  head -n 1 ./input/$datatime/input_processed/genetic_interaction_effect_values | tr -s "\t" "\n" >  ./input/$datatime/input_processed/DepMap_effect_cols
  sed '1d' ./input/$datatime/input_processed/genetic_interaction_effect_values > ./input/$datatime/input_processed/DepMap_effect
  rm ./input/$datatime/input_raw/CRISPR_gene_effect_symbol ./input/$datatime/input_processed/genetic_interaction_effect_values

  # HIPPO
  current v2_2
  grep pubmed ./input/$datatime/input_raw/hippie.txt | standard_name_replacer -i - -I ./translators/symbol_HGNC -c 17,18 -u  >  ./input/$datatime/input_processed/tmp 
  cut -f 16,17,18 ./input/$datatime/input_processed/tmp | awk '{OFS="\t"}{print $2,$3,$1}'  > ./input/$datatime/input_processed/hippie_ppi 
  standard_name_replacer -i ./input/$datatime/input_raw/hippie.txt -I ./translators/symbol_HGNC -c 1,2 -u > ./input/$datatime/input_processed/hippie_ppi 

  # HGNC_group
  # Formatting data_columns
  cut -f 1,14 ./input/$datatime/input_raw/gene_hgncGroup | sed "s/\"//g" | tr -s "|" "," | awk '{if( $2 != "") print $0}' \
    | desaggregate_column_data -i "-" -x 2 | sed 's/\t/\tGROUP:/1g' | sed 1d > ./input/$datatime/input_processed/gene_hgncGroup

  # PROCESS REACTIONS 
  cut -f 2- ./input/$datatime/input_raw/ReactomePathways.gmt | sed 's/https:\/\/reactome.org\/content\/detail\//REACT:/g' \
    | sed "s/\t/,/2g" \
    | desaggregate_column_data -i - -x 2 \
    | cut -f 1,2 \
    | standard_name_replacer -i - -I ./translators/symbol_HGNC -c 2 -u \
    | awk '{OFS="\t"}{print $2,$1}' > ./input/$datatime/input_processed/pathway

elif [ "$exec_mode" == "dversion" ] ; then

  dversion=$2 
  if [ -s ./input/input_processed ] ; then
    rm ./input/input_processed
  fi 
  if [ -s ./input/input_obo ] ; then
    rm ./input/input_obo
  fi 
  ln -sf $input_path/input/$dversion/input_processed ./input/input_processed
  ln -sf $input_path/input/$dversion/input_obo ./input/input_obo

elif [ "$exec_mode" == "whitelist" ] ; then

#########################################################
# OPTIONAL STAGE : SELECT GENES FROM WHITELIST
#########################################################

  decleare -A gen_cols 
  gen_cols[disease]="1"
  gen_cols[phenotype]="1"
  gen_cols[molecular_function]="1"
  gen_cols[biological_process]="1"
  gen_cols[cellular_component]="1"
  gen_cols[string_ppi]="1,2"
  gen_cols[hippie_ppi]="1,2"
  gen_cols[string_ppi_textmining]="1,2"
  gen_cols[string_ppi_database]="1,2"
  gen_cols[string_ppi_experimental]="1,2"
  gen_cols[string_ppi_coexpression]="1,2"
  gen_cols[string_ppi_cooccurence]="1,2"
  gen_cols[string_ppi_fusion]="1,2"
  gen_cols[string_ppi_neighborhood]="1,2"
  gen_cols[kim_coess_gene]="1,2"
  gen_cols[pathway]="1"
  gen_cols[gene_TF]="1"
  gen_cols[gene_hgncGroup]="1"
  gen_cols[gene_PS]="1"

# TODO: Check this to put all layers new.
  . ~soft_bio_267/initializes/init_python

  cd ./input/input_processed
  mkdir -p whitelist

  for annot in $annotations ; do
    if [ -s $annot ] ; then
      filter_by_list -f $annot -c ${gen_cols[$annot]} -t $input_path/white_list/hgnc_white_list -o ./whitelist/ --prefix "" --metrics 
    fi
  done

  # Special section for DepMap info.
  ## Adding the colnames
  for type in exprs effect ; do
    if [ -s DepMap_${type} ] ; then
      cat DepMap_${type}_cols | tr -s "\t" "\n" >   ./whitelist/DepMap_${type}_cols
      cat ./whitelist/DepMap_${type}_cols DepMap_${type} > ./whitelist/DepMap_${type}
      ## Filtering by the colnames
      filter_by_list -f ./whitelist/DepMap_${type} -c "1" -t $input_path/white_list/hgnc_white_list --transposed --metrics 
      # Geting format: Values table, rownames, colnames for DepMap.
      head -n 1 ./whitelist/DepMap_${type} | tr -s "\t" "\n" >  ./whitelist/DepMap_${type}_cols
      sed -i '1d' ./whitelist/DepMap_${type} 
      cp DepMap_${type}_rows ./whitelist/DepMap_${type}_rows
    fi
  done

  mv filtered_* ./whitelist/
  rename -v 's/filtered_//' ./whitelist/*
  echo "Annotation files filtered"
  cd ../..

elif [ "$exec_mode" == "download_control" ] ; then #TODO: 07/11/23
  # All this section must be fixed
  mkdir $control_genes_folder/zampieri
  # mkdir $control_genes_folder/zampieri/data
  # mkdir $control_genes_folder/menche
  # mkdir $control_genes_folder/menche/data

  # wget https://github.com/seoanezonjic/kernels_testing/blob/master/initial_data/diseasome_from_paper.tsv -o $control_genes_folder/zampieri/data/zampieri_bench.tsv
  # wget https://github.com/menchelab/MultiOme/blob/main/data/table_disease_gene_assoc_orphanet_genetic.tsv -o $control_genes_folder/menche/data/menche_bench.tsv

elif [ "$exec_mode" == "process_control" ] ; then 

  $daemon_scripts/control_preparation.sh

elif [ "$exec_mode" == "get_control" ] ; then 

  benchmark=$2

  if [ -s ./control_pos ] ; then
    rm ./control_pos
  fi

  if [ -s ./control_neg ] ; then
    rm ./control_neg
  fi

  if [ $benchmark == "zampieri" ] ; then
    cp $control_genes_folder/zampieri/disease_gens ./control_pos
    cp $control_genes_folder/zampieri/non_disease_gens ./control_neg
  elif [ $benchmark == "menche" ] ; then
    cp $control_genes_folder/menche/disease_gens ./control_pos
  fi

elif [ "$exec_mode" == "get_production_seedgenes" ] ; then 

  translate_from=$add_opt
  cat ./production_seedgenes/* > production_seedgens

  if [ $translate_from == "symbol" ] ; then
    desaggregate_column_data -i production_seedgens -x 2 > disaggregated_production_seedgens
    standard_name_replacer -I ./translators/symbol_HGNC -i disaggregated_production_seedgens -c 2 -u | aggregate_column_data -i - -x 1 -a 2 > production_seedgens
    rm disaggregated_production_seedgens
  elif [ $translate_from == "ensemble" ] ; then
    desaggregate_column_data -i production_seedgens -x 2 > disaggregated_production_seedgens
    standard_name_replacer -I ./translators/Ensemble_HGNC -i disaggregated_production_seedgens -c 2 -u | aggregate_column_data -i - -x 1 -a 2 > production_seedgens
    rm disaggregated_production_seedgens
  fi

#########################################################
# STAGE 2 AUTOFLOW EXECUTION
#########################################################

elif [ "$exec_mode" == "kernels" ] ; then
  #######################################################
  #STAGE 2.1 PROCESS SIMILARITY AND OBTAIN KERNELS
  mkdir -p $output_folder/similarity_kernels

  if [ ! -z $2 ] ; then
    whitelist=$2
  fi

  for annotation in $annotations ; do 

      autoflow_vars=`echo " 
      \\$annotation=${annotation},
      \\$input_path=$input_path/input/,
      \\$net2custom=$net2custom,
      \\$kernels_varflow=$kernels_varflow,
      \\$whitelist=$whitelist
      " | tr -d [:space:]`

      process_type=`net2json_parser.py --net_id $annotation --json_path $net2custom | grep -P -w '^Process' | cut -f 2`
      echo $process_type
      net2json_parser.py --net_id $annotation --json_path $net2custom
      echo "Performing kernels without umap $annotation"
      AutoFlow -w $autoflow_scripts/sim_kern.af -V $autoflow_vars -o $output_folder/similarity_kernels/${annotation} -L $add_opt #-A "exclude:sr133,sr014,sr030"

  done

elif [ "$exec_mode" == "plot_sims" ] ; then
  # Plotting the graphs in the correct manner.
  mkdir -p plot_sims

  cat  $output_folder/similarity_kernels/*/*/ugot_path > $output_folder/similarity_kernels/ugot_path
  ugot_path="$output_folder/similarity_kernels/ugot_path"
  rawSim_paths=`awk '{print $0,NR}' $ugot_path | sort -k 5 -r -u | grep "raw_sim" | awk '{OFS="\t"}{print $2,$4}'`
  filter_sims=`echo $annotations | sed 's/ /\n/g'`
  rawSim_paths=`grep -F -f <(echo "$filter_sims") <(echo "$rawSim_paths")`
  echo -e "$rawSim_paths" >  $output_folder/similarity_kernels/rawSim_paths

  autoflow_vars=`echo "\\$rawSim_paths=$output_folder/similarity_kernels/rawSim_paths,\\$annotations_varflow=$annotations_varflow"`
  echo -e "$autoflow_vars"
  AutoFlow -w $autoflow_scripts/plot_sims.af -V $autoflow_vars -o $output_folder/plot_sims -L $add_opt 

elif [ "$exec_mode" == "ranking" ] ; then
  #########################################################
  # STAGE 2.2 OBTAIN RANKING FROM NON INTEGRATED KERNELS
  if [ -s $output_folder/rankings ] ; then
    rm -r $output_folder/rankings 
  fi
  mkdir -p $output_folder/rankings
  benchmark=$2 # menche or zampieri
  
  cat  $output_folder/similarity_kernels/*/*/ugot_path > $output_folder/similarity_kernels/ugot_path
  for annotation in $annotations ; do 
    for kernel in $kernels ; do 

      #ugot_path="$output_folder/similarity_kernels/ugot_path"
      ugot_path="$output_folder/similarity_kernels/ugot_path"
      folder_kernel_path=`awk '{print $0,NR}' $ugot_path | sort -k 5 -r -u | grep "${annotation}_$kernel" | awk '{print $4}'`
      echo ${folder_kernel_path}
      if [ ! -z ${folder_kernel_path} ] ; then # This kernel for this annotation is done? 

        autoflow_vars=`echo " 
        \\$param1=$annotation,
        \\$kernel=$kernel,
        \\$input_path=$input_path,
        \\$folder_kernel_path=$folder_kernel_path,
        \\$input_name='kernel_matrix_bin',
        \\$production_seedgens=$production_seedgens,
        \\$control_pos=$control_pos,
        \\$control_neg=$control_neg,
        \\$output_name='non_integrated_rank',
        \\$benchmark=$benchmark,
        \\$geneseeds=$input_path/geneseeds
        " | tr -d [:space:]`

        AutoFlow -w $autoflow_scripts/ranking.af -V $autoflow_vars -o $output_folder/rankings/ranking_${kernel}_${annotation} -m 60gb -t 4-00:00:00 -L $3 #-A "exclude:sr060" 
      fi

    done
  done


elif [ "$exec_mode" == "integrate" ] ; then 
  #########################################################
  # STAGE 2.3 INTEGRATE THE KERNELS
  . ~soft_bio_267/initializes/init_python

  rm -r $output_folder/integrations
  mkdir -p $output_folder/integrations
  #cat  $output_folder/similarity_kernels/*/*/ugot_path > $output_folder/similarity_kernels/ugot_path # What I got?
  
  echo -e "$integrated_annotations" | tr -s " " "\n" > uwant
  cat  $output_folder/similarity_kernels/*/*/ugot_path > $output_folder/similarity_kernels/ugot_path
  #filter_by_whitelist -f $output_folder/similarity_kernels/ugot_path -c "1" -t uwant -o $output_folder/similarity_kernels
  filter_by_list -f $output_folder/similarity_kernels/ugot_path -c "2" -t uwant -o $output_folder/similarity_kernels
  rm uwant

  for integration_type in ${integration_types} ; do 

      ugot_path="$output_folder/similarity_kernels/filtered_ugot_path"

      autoflow_vars=`echo "
      \\$integration_type=${integration_type},
      \\$kernels_varflow=${kernels_varflow},
      \\$ugot_path=$ugot_path
      " | tr -d [:space:]`

      AutoFlow -w $autoflow_scripts/integrate.af -V $autoflow_vars -o $output_folder/integrations/${integration_type} -m 60gb -t 4-00:00:00 -L $add_opt 

  done

elif [ "$exec_mode" == "integrated_ranking" ] ; then
  #########################################################
  # STAGE 2.4 OBTAIN RANKING FROM INTEGRATED KERNELS
  if [ -s $output_folder/integrated_rankings ] ; then
    rm -r $output_folder/integrated_rankings # To not mix executions.
  fi
  mkdir -p $output_folder/integrated_rankings
  cat  $output_folder/integrations/*/*/ugot_path > $output_folder/integrations/ugot_path # What I got?
  
  #echo -e "$annotations" | tr -s " " "\n" > uwant
  #cat  $output_folder/similarity_kernels/*/*/ugot_path > $output_folder/similarity_kernels/ugot_path
  #filter_by_whitelist.rb -f $output_folder/similarity_kernels/ugot_path -c "1;" -t uwant -o $output_folder/similarity_kernels

  benchmark=$2 # menche or zampieri

  for integration_type in ${integration_types} ; do 
    for kernel in $kernels ; do 

      ugot_path="$output_folder/integrations/ugot_path"
      folder_kernel_path=`awk '{print $0,NR}' $ugot_path | sort -k 5 -r -u | grep -w "${integration_type}_$kernel" | awk '{print $4}'`
      echo ${folder_kernel_path}
      if [ ! -z ${folder_kernel_path} ] ; then # This kernel for this integration_type is done? 

        autoflow_vars=`echo " 
        \\$param1=$integration_type,
        \\$kernel=$kernel,
        \\$input_path=$input_path,
        \\$folder_kernel_path=$folder_kernel_path,
        \\$input_name='general_matrix',
        \\$production_seedgens=$production_seedgens,
        \\$control_pos=$control_pos,
        \\$control_neg=$control_neg,
        \\$output_name='integrated_rank',
        \\$benchmark=$benchmark,
        \\$geneseeds=$input_path/geneseeds
        " | tr -d [:space:]`

        AutoFlow -w $autoflow_scripts/ranking.af -V $autoflow_vars -o $output_folder/integrated_rankings/ranking_${kernel}_${integration_type} -m 60gb -L -t 4-00:00:00 $3
      fi

    done
  done

#########################################################
# STAGE 3 OBTAIN REPORT FROM RESULTS
#########################################################

elif [ "$exec_mode" == "report" ] ; then 
  source ~soft_bio_267/initializes/init_ruby
  source ~soft_bio_267/initializes/init_python
  source ~soft_bio_267/initializes/init_R
  #report_type=$2
  html_name=$2
  check=$3
  
  # #################################
  # Setting up the report section #
  find $report_folder/ -mindepth 2 -delete
  find $output_folder/ -maxdepth 1 -type f -delete

  mkdir -p $report_folder/kernel_report
  mkdir -p $report_folder/ranking_report
  mkdir -p $report_folder/img

  declare -A original_folders
  original_folders[annotations_metrics]='similarity_kernels'
  original_folders[final_stats_by_steps]='similarity_kernels'
  original_folders[uncomb_kernel_metrics]='similarity_kernels'
  original_folders[comb_kernel_metrics]='integrations'

  original_folders[non_integrated_rank_summary]='rankings'
  original_folders[non_integrated_rank_measures]='rankings'
  original_folders[non_integrated_rank_cdf]='rankings'
  original_folders[non_integrated_rank_pos_cov]='rankings'
  original_folders[non_integrated_rank_positive_stats]='rankings'
  original_folders[non_integrated_rank_size_auc_by_group]='rankings'
  original_folders[non_integrated_rank_auc_by_groupIteration]='rankings'

  original_folders[integrated_rank_summary]='integrated_rankings'
  original_folders[integrated_rank_measures]='integrated_rankings'
  original_folders[integrated_rank_cdf]='integrated_rankings'
  original_folders[integrated_rank_pos_cov]='integrated_rankings'
  original_folders[integrated_rank_positive_stats]='integrated_rankings'
  original_folders[integrated_rank_size_auc_by_group]='integrated_rankings'
  
  # Here the data is collected from executed folders.
  for file in "${!original_folders[@]}" ; do
    original_folder=${original_folders[$file]}
    count=`find $output_folder/$original_folder -maxdepth 4 -mindepth 4 -name $file | wc -l`
    if [ "$count" -gt "0" ] ; then
      echo "$file"
      cat $output_folder/$original_folder/*/*/$file > $output_folder/$file
    fi
  done 


  ##########################
  # Processing all metrics #
  declare -A references
  references[annotations_metrics]='Net'
  references[final_stats_by_steps]='Net_Step,Net,Step'
  references[uncomb_kernel_metrics]='Sample,Net,Kernel'
  references[comb_kernel_metrics]='Sample,Integration,Kernel'

  references[non_integrated_rank_summary]='Sample,Net,Kernel'
  references[non_integrated_rank_pos_cov]='Sample,Net,Kernel'
  references[non_integrated_rank_positive_stats]='Sample,Net,Kernel,group_seed'

  references[integrated_rank_summary]='Sample,Integration,Kernel'
  references[integrated_rank_pos_cov]='Sample,Integration,Kernel'
  references[integrated_rank_positive_stats]='Sample,Integration,Kernel,group_seed'

  references[annotation_grade_metrics]='Gene_seed'

  # annotations_metrics uncomb_kernel_metrics comb_kernel_metrics
  for metric in annotations_metrics final_stats_by_steps uncomb_kernel_metrics comb_kernel_metrics ; do
    if [ -s $output_folder/$metric ] ; then
      create_metric_table $output_folder/$metric ${references[$metric]} $report_folder/kernel_report/parsed_${metric} 
    fi
  done

  if [ -s $output_folder/non_integrated_rank_auc_by_groupIteration ] ; then 
    echo -e "sample\tannot\tkernel\tseed\tauc" | \
     cat - $output_folder/non_integrated_rank_auc_by_groupIteration > $report_folder/ranking_report/non_integrated_rank_auc_by_groupIteration
  fi

  if [ -s $output_folder/non_integrated_rank_size_auc_by_group ] ; then 
    echo -e "sample\tannot\tkernel\tseed\tpos_cov\tauc" | \
     cat - $output_folder/non_integrated_rank_size_auc_by_group > $report_folder/ranking_report/non_integrated_rank_size_auc_by_group
  fi

  if [ -s $output_folder/integrated_rank_size_auc_by_group ] ; then 
    echo -e "sample\tmethod\tkernel\tseed\tpos_cov\tauc" | \
     cat - $output_folder/integrated_rank_size_auc_by_group > $report_folder/ranking_report/integrated_rank_size_auc_by_group
  fi

  for metric in non_integrated_rank_summary integrated_rank_summary non_integrated_rank_pos_cov integrated_rank_pos_cov non_integrated_rank_positive_stats integrated_rank_positive_stats ; do
    if [ -s $output_folder/$metric ] ; then
      echo "$output_folder/$metric"
      create_metric_table $output_folder/$metric ${references[$metric]} $report_folder/ranking_report/parsed_${metric} 
    fi
  done

  if [ -s $output_folder/non_integrated_rank_measures ] ; then
     echo -e "annot_kernel\tannot\tkernel\trank\tacc\ttpr\tfpr\tprec\trec" | \
     cat - $output_folder/non_integrated_rank_measures > $report_folder/ranking_report/non_integrated_rank_measures
  fi

  if [ -s $output_folder/integrated_rank_measures ] ; then
    echo -e "integration_kernel\tintegration\tkernel\trank\tacc\ttpr\tfpr\tprec\trec" | \
     cat - $output_folder/integrated_rank_measures > $report_folder/ranking_report/integrated_rank_measures
  fi

  if [ -s $output_folder/non_integrated_rank_cdf ] ; then
     echo -e "annot_kernel\tannot\tkernel\tcandidate\tscore\trank\tcummulative_frec\tgroup_seed"| \
     cat - $output_folder/non_integrated_rank_cdf > $report_folder/ranking_report/non_integrated_rank_cdf
  fi

  if [ -s $output_folder/integrated_rank_cdf ] ; then
     echo -e "integration_kernel\tintegration\tkernel\tcandidate\tscore\trank\tcummulative_frec\tgroup_seed"| \
     cat - $output_folder/integrated_rank_cdf > $report_folder/ranking_report/integrated_rank_cdf
  fi

  if [ -z "$check" ] ; then
    echo "---------------------------------------"
    echo " Now it is necessary some information of the process "
    echo "string version?"
    # 11.5 | 11.0
    read string_version
    echo "hippie version?"
    read hippie_version
    echo "whitelist used?"
    read whitelist
    name_dir=`date +%d_%m_%Y`
    mkdir ./report/HTMLs/$name_dir
    # Create preprocess file
    echo -e " String version:\t$string_version\nHippie version:\t$hippie_version\nWhitelist:\t$whitelist " > ./report/HTMLs/$name_dir/info_preprocess
    # Copy net2json
    cp ./net2json ./report/HTMLs/$name_dir/
  else 
    echo "Reports to check available"
  fi
  
  ##################
  # Obtaining HTMLS #
  report_html -t ./report/templates/kernel_report.py -d `ls $report_folder/kernel_report/* | tr -s [:space:] "," | sed 's/,*$//g'` -o "report_kernel$html_name"
  report_html -t ./report/templates/ranking_report.py -d `ls $report_folder/ranking_report/* | tr -s [:space:] "," | sed 's/,*$//g'` -o "report_algQuality$html_name"

  if [ -z "$check" ] ; then
    mv ./report_kernel$html_name.html ./report/HTMLs/$name_dir/
    mv ./report_algQuality$html_name.html ./report/HTMLs/$name_dir/
  fi

#########################################################
# STAGE TO CHECK AUTOFLOW IS RIGHT
#########################################################
elif [ "$exec_mode" == "check" ] ; then
  #STAGE 3 CHECK EXECUTION
  for folder in `ls $output_folder/$add_opt/` ; do 
    if [ -d $output_folder/$add_opt/$folder ] ; then
      echo "$folder"
      flow_logger -w -e $output_folder/$add_opt/$folder -r all
    fi
  done

elif [ "$exec_mode" == "recover" ]; then 
  #STAGE 4 RECOVER EXECUTION
  for folder in `ls $output_folder/$add_opt/` ; do 
    if [ -d $output_folder/$add_opt/$folder ] ; then
      echo "$folder"
      flow_logger -w -e $output_folder/$add_opt/$folder --sleep 0.1 -l -p  
    fi
  done
fi
