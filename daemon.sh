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
export report_folder=$output_folder/report
export translators=$input_path/translators

# v1: disease phenotype molecular_function biological_process cellular_component string_ppi_combined hippie_ppi DepMap_effect_pearson DepMap_effect_spearman DepMap_Kim pathway gene_hgncGroup
# Custom variables.
annotations=" disease phenotype molecular_function biological_process cellular_component"
annotations+=" string_ppi_combined hippie_ppi"
annotations+=" string_ppi_textmining string_ppi_database string_ppi_experimental string_ppi_coexpression string_ppi_cooccurence string_ppi_fusion string_ppi_neighborhood"
annotations+=" DepMap_effect_pearson DepMap_effect_spearman DepMap_Kim"
annotations+=" pathway gene_hgncGroup"
#annotations="molecular_function biological_process cellular_component"
#annotations="molecular_function"
#annotations="phenotype biological_process string_ppi_textmining string_ppi_coexpression gene_hgncGroup"
#annotations+=" gene_TF gene_PS"
#annotations=" string_ppi_combined phenotype disease"
annotations="molecular_function biological_process cellular_component"


integrated_annotations="disease phenotype molecular_function biological_process cellular_component string_ppi_combined pathway gene_TF gene_hgncGroup DepMap_effect_pearson gene_PS"
integrated_annotations="string_ppi_textmining string_ppi_database string_ppi_experimental string_ppi_coexpression string_ppi_cooccurence string_ppi_fusion string_ppi_neighborhood"
integrated_annotations="phenotype biological_process string_ppi_textmining string_ppi_coexpression gene_hgncGroup"
integrated_annotations="phenotype biological_process string_ppi_textmining string_ppi_coexpression gene_hgncGroup"
integrated_annotations="phenotype molecular_function biological_process cellular_component hippie_ppi pathway gene_hgncGroup DepMap_effect_pearson"
# v1: integrated_annotations="phenotype molecular_function biological_process cellular_component DepMap_Kim hippie_ppi pathway gene_hgncGroup string_ppi_combined"
# v1.2: integrated_annotations="phenotype molecular_function biological_process cellular_component DepMap_Kim hippie_ppi pathway gene_hgncGroup"
# v2: "string_ppi_textmining string_ppi_database string_ppi_experimental string_ppi_coexpression string_ppi_cooccurence string_ppi_fusion string_ppi_neighborhood"
# v3: "biological_process phenotype string_ppi_textmining string_ppi_coexpression pathway gene_hgncGroup"
#integrated_annotations="biological_process phenotype string_ppi_textmining string_ppi_coexpression pathway gene_hgncGroup"
# v4: "phenotype string_ppi_textmining string_ppi_coexpression string_ppi_database string_ppi_experimental pathway gene_hgncGroup"
# v5: "phenotype string_ppi_textmining string_ppi_coexpression string_ppi_database string_ppi_experimental"
# vfinal: "phenotype string_ppi_textmining string_ppi_coexpression string_ppi_database string_ppi_experimental pathway gene_hgncGroup"
integrated_annotations="phenotype string_ppi_textmining string_ppi_coexpression string_ppi_database string_ppi_experimental pathway"

kernels="rf el node2vec raw_sim"
integration_types="mean integration_mean_by_presence median max"
net2custom=$input_path'/net2json' 
control_pos=$input_path'/control_pos'
control_neg=$input_path'/control_neg'
production_seedgens=$input_path'/production_seedgens'
whitelist="whitelist"

echo "$annotations"

kernels_varflow=`echo $kernels | tr " " ";"`
annotations_varflow=`echo $annotations | tr " " ";"`

. ~soft_bio_267/initializes/init_python

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

  # # Downloading ProtEnsemble_HGNC from STRING.
  # wget https://stringdb-static.org/download/protein.aliases.v11.5/9606.protein.aliases.v11.5.txt.gz -O ./translators/protein_aliases.v11.5.txt.gz
  # gzip -d translators/protein_aliases.v11.5.txt.gz
  # grep -w "Ensembl_HGNC_HGNC_ID" translators/protein_aliases.v11.5.txt | cut -f 1,2 > ./translators/ProtEnsemble_HGNC
  # rm ./translators/protein_aliases.v11.5.txt

  # # Downloading Ensemble_HGNC from BioMart

  # # TODO

  # # Downloading HGNC_symbol
  # wget http://ftp.ebi.ac.uk/pub/databases/genenames/hgnc/archive/monthly/tsv/hgnc_complete_set_2022-04-01.txt -O ./translators/HGNC_symbol
  # awk '{OFS="\t"}{print $2,$1}' ./translators/HGNC_symbol > ./translators/symbol_HGNC
  # awk '{FS="\t";OFS="\t"}{print $19,$1}' ./translators/HGNC_symbol > ./translators/entrez_HGNC

  # The other direction symbol_HGNC
  #awk '{OFS="\t"}{print $2,$1}' ./translators/HGNC_symbol > ./translators/symbol_HGNC

  # omim 2 text
  wget https://data.omim.org/downloads/Vigwxa9YRaCz7jdsYnIfUQ/mimTitles.txt -O ./translators/mimTitles
  grep -v "#" ./translators/mimTitles | cut -f 2,3 > tmp && mv tmp ./translators/mimTitles

elif [ "$exec_mode" == "process_download" ] ; then
  source ~soft_bio_267/initializes/init_python
  source $input_path/scripts/aux_scripts/aux_daemon.sh

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

  # # For upgraded #
  # ################
  # datatime="upgraded"
  # # Ontologies
  # # ----------
  # for sample in phenotype disease function ; do
  #   zgrep ${tag_filter[$sample]} ./input/$datatime/input_raw/gene_${sample}.all.tsv.gz | grep 'NCBITaxon:9606' | grep "HGNC:" | \
  #   aggregate_column_data -i - -x 1 -a 5 > ./input/$datatime/input_processed/$sample # | head -n 230
  # done
  # ## Creating paco files for hpo.
  # semtools -i ./input/$datatime/input_processed/phenotype -o ./input/$datatime/input_processed/filtered_phenotype -O HPO -S "," -c -T HP:0000001
  # cat ./input/$datatime/input_processed/filtered_phenotype | tr -s "|" "," > ./input/$datatime/input_processed/phenotype
  # rm ./input/$datatime/input_processed/filtered_phenotype
  # rm rejected_profs
  # ## Creating paco files for each go branch.
  # gene_ontology=( molecular_function cellular_component biological_process )
  # for branch in ${gene_ontology[@]} ; do
  #   semtools -i ./input/$datatime/input_processed/function -o ./input/$datatime/input_processed/filtered_$branch -O GO -S "," -c -T ${tag_filter[$branch]}
  #   cat ./input/$datatime/input_processed/filtered_$branch | tr -s "|" "," > ./input/$datatime/input_processed/$branch
  #   rm ./rejected_profs
  #   rm ./input/$datatime/input_processed/filtered_$branch
  # done
  # rm ./input/$datatime/input_processed/function
  # # Protein associations
  # # --------------------
  # ## STRING 11.5 
  # process_string $datatime
  # ## HIPPO current
  # process_hippie $datatime
  # # DEPMAP
  # # -----------
  # process_gen_int $datatime "effect"
  # process_gen_int $datatime "exprs"
  # # GENE-TF interaction.ls
  # # ----------------------
  # standard_name_replacer -i ./input/$datatime/input_raw/gene_TF -I ./translators/symbol_HGNC -c 1,2 -u | sed 's/HGNC:/TF:/2g' > ./input/$datatime/input_processed/gene_TF
  # # HGNC-groups
  # # -----------
  # process_hgnc_group $datatime
  # # Phenotypic Series
  # # -----------------
  # get_PS_gene_relation.py -i "/mnt/home/users/bio_267_uma/federogc/projects/GraphPrioritizer/input/downloaded_raw/phenotypic_series/series_data" -o "./input/$datatime/input_processed/PS_genes"
  # desaggregate_column_data -i ./input/$datatime/input_processed/PS_genes -x 2 > ./input/$datatime/input_processed/tmp 
  # standard_name_replacer -i ./input/$datatime/input_processed/tmp -I ./translators/symbol_HGNC -c 2 -u | awk 'BEGIN{FS="\t";OFS="\t"}{print $2,$1}' > ./input/$datatime/input_processed/gene_PS
  # rm ./input/$datatime/input_processed/PS_genes ./input/$datatime/input_processed/tmp 
  # # Reactions
  # # ---------
  # zgrep "REACT:" ./input/$datatime/input_raw/gene_pathway.all.tsv.gz |  grep 'NCBITaxon:9606' | grep "HGNC:" | \
  #   cut -f 1,5 > ./input/$datatime/input_processed/pathway

  # For downgraded #
  ##################
  datatime="downgraded"
  # Ontologies
  # ----------
  echo -e "in disease"
  zgrep ${tag_filter[disease]} ./input/$datatime/input_raw/gene_disease.9606.tsv.gz | grep 'NCBITaxon:9606' | grep "HGNC:" | \
  aggregate_column_data -i - -x 1 -a 5 > ./input/$datatime/input_processed/disease 

  tail -n +2 ./input/$datatime/input_raw/HPO_genes.txt | cut -f 1,4 | \
   aggregate_column_data -i - -x 2 -a 1 | standard_name_replacer -i - -I ./translators/symbol_HGNC -c 1 -u > ./input/$datatime/input_processed/phenotype

  echo "in go"
  gzip -d -c ./input/downgraded/input_raw/gene_functions.gaf.gz > ./input/downgraded/input_raw/gene_functions
  echo "remove header"
  tail -n +31 ./input/$datatime/input_raw/gene_functions | cut -f 3,5,7 | \
    grep -E -w "EXP|IDA|IPI|IMP|IGI|IEP|IC|HTP|HDA|HMP|HGI|HEP" | \
    cut -f 1,2 | aggregate_column_data -i - -x 1 -a 2 > ./input/$datatime/input_processed/function
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
    echo -e "$branch is:"
    wc -l ./input/$datatime/input_processed/$branch
    rm ./rejected_profs
    rm ./input/$datatime/input_processed/filtered_$branch
  done
  rm ./input/$datatime/input_processed/function

  # Protein associations
  # --------------------
  ## STRING 11.0
  #process_string $datatime
  ## HIPPIE from Paper
  standard_name_replacer -i ./input/$datatime/input_raw/hippie.txt -I ./translators/symbol_HGNC -c 1,2 -u > ./input/$datatime/input_processed/hippie_ppi 
  # DEPMAP
  # -----------
  ## from paper
  cut -f 1,2,3 ./input/$datatime/input_raw/KimCoess_gene | standard_name_replacer -I ./translators/symbol_HGNC -i - -c 1,2 -u > ./input/$datatime/input_processed/KimCoess_gene
  ## from DepMap
  process_gen_int $datatime "effect"
  # HGNC-groups
  # -----------
  process_hgnc_group $datatime
  # Reactions
  # ---------
  cut -f 2- ./input/$datatime/input_raw/ReactomePathways.gmt | sed 's/https:\/\/reactome.org\/content\/detail\//REACT:/g' \
    | sed "s/\t/,/2g" \
    | desaggregate_column_data -i - -x 2 \
    | cut -f 1,2 \
    | standard_name_replacer -i - -I ./translators/symbol_HGNC -c 2 -u \
    | awk '{OFS="\t"}{print $2,$1}' > ./input/$datatime/input_processed/pathway

elif [ "$exec_mode" == "dversion" ] ; then

  dversion=$2 
  modify_json.py -k "data_process;Data_version" -v "$dversion" -jp net2json
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
  # TODO update the whitelist in json
  #modify_json.py -k "data_process;Whitelist" -v  -jp net2json

  declare -A gen_cols 
  gen_cols[disease]="1"
  gen_cols[phenotype]="1"
  gen_cols[molecular_function]="1"
  gen_cols[biological_process]="1"
  gen_cols[cellular_component]="1"
  gen_cols[string_ppi_combined_score]="1,2"
  gen_cols[hippie_ppi]="1,2"
  gen_cols[string_ppi_textmining]="1,2"
  gen_cols[string_ppi_database]="1,2"
  gen_cols[string_ppi_experimental]="1,2"
  gen_cols[string_ppi_coexpression]="1,2"
  gen_cols[string_ppi_cooccurence]="1,2"
  gen_cols[string_ppi_fusion]="1,2"
  gen_cols[string_ppi_neighborhood]="1,2"
  gen_cols[KimCoess_gene]="1,2"
  gen_cols[pathway]="1"
  gen_cols[gene_TF]="1"
  gen_cols[gene_hgncGroup]="1"
  gen_cols[gene_PS]="1"

  # TODO: Check this to put all layers new.
  . ~soft_bio_267/initializes/init_python

  cd ./input/input_processed
  if [ -s whitelist ] ; then 
    rm -r whitelist
  fi

  mkdir -p whitelist

  for source in "${!gen_cols[@]}" ; do
    if [ -s $source ] ; then
      filter_by_list -f $source -c ${gen_cols[$source]} -t $input_path/white_list/hgnc_white_list -o ./whitelist/ --prefix "" --metrics 
    fi
  done

  # Special section for DepMap info.
  ## Adding the colnames
  for type in exprs effect ; do
    if [ -s DepMap_${type} ] ; then
      cat DepMap_${type}_cols | tr -s "\n" "\t" | sed 's/$/\n/'> ./whitelist/DepMap_${type}_cols
      cat ./whitelist/DepMap_${type}_cols DepMap_${type} > ./whitelist/DepMap_${type}
      ## Filtering by the colnames
      filter_by_list -f ./whitelist/DepMap_${type} -c "1" -t $input_path/white_list/hgnc_white_list -o ./whitelist/ --prefix "" --transposed --metrics 
      # Geting format: Values table, rownames, colnames for DepMap.
      head -n 1 ./whitelist/DepMap_${type} | tr -s "\t" "\n" >  ./whitelist/DepMap_${type}_cols
      sed -i '1d' ./whitelist/DepMap_${type} 
      cp DepMap_${type}_rows ./whitelist/DepMap_${type}_rows
    fi
  done

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

  # if [ ! -z $2 ] ; then
  #   whitelist=$2
  # fi

  whitelist="true"

  # update net2json
  embeddings=`echo $kernels | tr -s " " "," | awk '{print "["$0"]"}'`
  modify_json.py -k "data_process;Embeddings" -v "$embeddings" -jp net2json

  for annotation in $annotations ; do 

      autoflow_vars=`echo " 
      \\$annotation=${annotation},
      \\$input_path=$input_path/input/,
      \\$net2custom=$net2custom,
      \\$kernels_varflow=$kernels_varflow,
      \\$whitelist=$whitelist,
      \\$translators=$translators
      " | tr -d [:space:]`

      process_type=`net2json_parser.py --net_id $annotation --json_path $net2custom | grep -P -w '^Process' | cut -f 2`
      echo $process_type
      net2json_parser.py --net_id $annotation --json_path $net2custom
      echo "Performing kernels without umap $annotation"
      AutoFlow -w $autoflow_scripts/sim_kern.af -V $autoflow_vars -o $output_folder/similarity_kernels/${annotation}  -L $add_opt #-A "exclude=sr133,sr014,sr030" -n bc -A "reservation:nuevos_nodos"

  done

  cp ./net2json $output_folder/similarity_kernels/net2json

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
  benchmark=$2 # menche or zampieri
  mkdir -p $output_folder/rankings
  if [ -s $output_folder/rankings/$benchmark ] ; then
    rm -r $output_folder/rankings/$benchmark
  fi
  mkdir -p $output_folder/rankings/$benchmark

  # update net2json
  annot=`echo $annotations | tr -s " " "," | awk '{print "["$0"]"}'`
  modify_json.py -k "data_process;layers2process" -v "$annot" -jp net2json
  
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

        AutoFlow -w $autoflow_scripts/ranking.af -V $autoflow_vars -n cal -o $output_folder/rankings/$benchmark/ranking_${kernel}_${annotation} -m 30gb -t 0-03:59:59 -L $3 #-A "exclude=sr060" 
      fi
      sleep 2

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

  # update net2json
  int_annot=`echo $integrated_annotations | tr -s " " "," | awk '{print "["$0"]"}'`
  modify_json.py -k "data_process;Integrated_layers" -v "$int_annot" -jp net2json

  for integration_type in ${integration_types} ; do 

      ugot_path="$output_folder/similarity_kernels/filtered_ugot_path"

      autoflow_vars=`echo "
      \\$integration_type=${integration_type},
      \\$kernels_varflow=${kernels_varflow},
      \\$ugot_path=$ugot_path
      " | tr -d [:space:]`
      # -n bc -A "reservation:nuevos_nodos"
      AutoFlow -w $autoflow_scripts/integrate.af -V $autoflow_vars -o $output_folder/integrations/${integration_type} -n cal -m 60gb -t 0-02:00:00 -L $add_opt 

  done

elif [ "$exec_mode" == "integrated_ranking" ] ; then
  #########################################################
  # STAGE 2.4 OBTAIN RANKING FROM INTEGRATED KERNELS
  benchmark=$2 # menche or zampieri
  mkdir -p $output_folder/integrated_rankings
  if [ -s $output_folder/integrated_rankings/$benchmark ] ; then
    rm -r $output_folder/integrated_rankings/$benchmark # To not mix executions.
  fi
  mkdir -p $output_folder/integrated_rankings/$benchmark
  cat  $output_folder/integrations/*/*/ugot_path > $output_folder/integrations/ugot_path # What I got?
  
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
        #-n bc -A "reservation:nuevos_nodos"
        AutoFlow -w $autoflow_scripts/ranking.af -V $autoflow_vars -n cal -o $output_folder/integrated_rankings/$benchmark/ranking_${kernel}_${integration_type} -m 30gb -t 0-03:59:59 -L $3
      fi
      sleep 1

    done
  done

#########################################################
# STAGE 3 OBTAIN REPORT FROM RESULTS
#########################################################

elif [ "$exec_mode" == "report" ] ; then 
  source ~soft_bio_267/initializes/init_ruby
  source ~soft_bio_267/initializes/init_python
  source ~soft_bio_267/initializes/init_R
  save=$2
  #interested_layers="biological_process phenotype string_ppi_textmining string_ppi_coexpression pathway gene_hgncGroup"
  #interested_layers=" string_ppi_combined string_ppi_textmining string_ppi_database string_ppi_experimental string_ppi_coexpression string_ppi_cooccurence string_ppi_fusion string_ppi_neighborhood"
  interested_layers=$annotations
  #interested_layers="string_ppi_combined string_ppi_textmining string_ppi_database"

  for html_name in "menche" "zampieri"; do
    #Setting up the report section #
    find $report_folder/$html_name -mindepth 2 -delete
    find $output_folder -maxdepth 1 -type f -delete
    mkdir -p $report_folder/$html_name/kernel_report
    mkdir -p $report_folder/$html_name/ranking_report
    $daemon_scripts/process_data_for_report.sh $html_name $save "$interested_layers"
    # Obtaining HTMLs
    report_html -t ./report/templates/kernel_report.py -c ./report/templates/css --css_cdn https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css -d `ls $report_folder/$html_name/kernel_report/* | tr -s [:space:] "," | sed 's/,*$//g'` -o "report_layer_building$html_name"
    report_html -t ./report/templates/ranking_report.py -c ./report/templates/css --css_cdn https://maxcdn.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css -d `ls $report_folder/$html_name/ranking_report/* | tr -s [:space:] "," | sed 's/,*$//g'` -o "report_algQuality$html_name"
    if [ ! -z "$save" ] ; then
      name_dir=`date +%d_%m_%Y`
      mv ./report_layer_building$html_name.html ./report/HTMLs/$name_dir/
      mv ./report_algQuality$html_name.html ./report/HTMLs/$name_dir/
    fi
  done

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
