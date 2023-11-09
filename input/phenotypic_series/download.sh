#! /usr/bin/env bash
agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:53.0) Gecko/20100101 Firefox/107.0"
#wget 'https://omim.org/phenotypicSeriesTitles/all?format=tsv' -O 'phen_serie.tsv' --no-check-certificate --user-agent="$agent"
grep PS phen_serie.tsv | cut -f 2 > ids
mkdir series_data
while read -r line;
do
   filepath=series_data/$line.tsv
   if [[ ! -s "$filepath" ]] ; then
	   wget "https://omim.org/phenotypicSeries/$line?format=tsv" -O $filepath --no-check-certificate --user-agent="$agent"
	   sleep 2
   fi
done < ids
