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