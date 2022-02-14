#!/usr/bin/env bash
source ~soft_bio_267/initializes/init_ruby

semtools.rb -i gene2go -o ./results.txt -O go.obo -s lin -S "," -k "GO:"

# Recodatorio de ayuda: Durante la reunion, con resnik no hubo problemas, pero si con lin.



