#!/usr/bin/env bash
export PATH=~soft_bio_267/programs/x86_64/scripts:$PATH
. ~soft_bio_267/initializes/init_ruby

idconverter.rb -d ../translators/symbol_HGNC -i data_coDep -c 0,1 > translated_coDep

