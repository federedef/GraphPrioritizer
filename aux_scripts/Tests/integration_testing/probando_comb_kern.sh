#!/usr/bin/env bash

source ~soft_bio_267/initializes/init_ruby
export PATH=/mnt/home/users/bio_267_uma/federogc/projects/backupgenes/aux_scripts:$PATH

version=$1
integration_type=$2

echo "Generating kernels to test"
./genera_kernels.rb -d 10000,10000,10000,10000


if [ $version == "old" ] ; then
	echo "Running old version with $integration_type "
	time kernel_combined.rb -i $integration_type -t " m1 m2 m3 m4 " -n " m1.lst m2.lst m3.lst m4.lst " -o general_matrix 
elif [ $version == "v2" ] ; then
	echo "Running new version  v2 with $integration_type "
	time kernel_combined_v2.rb -i $integration_type -t " m1 m2 m3 m4 " -n " m1.lst m2.lst m3.lst m4.lst " -o general_matrix 
elif [ $version == "v3" ] ; then
	echo "Running new version v3 with $integration_type "
	time kernel_combined_v3.rb -i $integration_type -t " m1 m2 m3 m4 " -n " m1.lst m2.lst m3.lst m4.lst " -o general_matrix 
fi

