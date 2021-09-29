#!/usr/bin/env bash


$exec_mode=$1

if [ "$exec_mode" == "download" ] ; then
    #STAGE 1 DOWNLOADING REFERENCE 
elif [ "$exec_mode" == "autoflow" ] ; then
	#STAGE 2 AUTOFLOW EXECUTION
	AutoFlow -w autoflow_template.af -V ontologia,kenertype,red -O
elif [ "$exec_mode" == "report" ] ; then 
	#STAGE 3 GENERATE REPORT fROM RESULTS
fi


