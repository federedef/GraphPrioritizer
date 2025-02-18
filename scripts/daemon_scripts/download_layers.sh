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
gzip -d ./input/downloaded_raw/gene_effect.csv.gz
cp ./input/downloaded_raw/gene_effect.csv ./input/downgraded/input_raw/CRISPR_gene_effect 
gzip ./input/downloaded_raw/gene_effect.csv
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