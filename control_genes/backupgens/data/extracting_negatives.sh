#!/usr/bin/env bash

grep -w 'All 6\|no *' Big_Papi | awk '{FS="\t";OFS="\t"}{if ( $7 <= 0.05) print $1,$2}'
