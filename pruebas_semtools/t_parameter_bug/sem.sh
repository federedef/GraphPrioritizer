#!/usr/bin/env bash
source ~soft_bio_267/initializes/init_ruby

# GO id for each branch.
# gene2molecular_function --> "GO:0003674"
# gene2biological_process --> "GO:0008150"
# gene2cellular_sublocation --> "GO:0005575"

for parental_node in GO:0003674 GO:0008150
do
  semtools.rb -i gene2go -o ./results.txt -O go.obo -s resnik -S "," -k "GO:" -r './' -c -T "$parental_node"
  mv gene2go_semantic_similarity_list ${parental_node}_similarity_list
done

# If we use different parental_nodes, the same list is obtained.
diff -s *_similarity_list







