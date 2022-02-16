#!/usr/bin/env bash
source ~soft_bio_267/initializes/init_ruby

/mnt/home/users/bio_267_uma/federogc/software/semtools/bin/semtools.rb -d GO

/mnt/home/users/bio_267_uma/federogc/software/semtools/bin/semtools.rb -i gene2go -o ./results.txt -O GO -n -S ","
