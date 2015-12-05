#!/bin/bash

# Load vars that are shared by sweep and parse: APP_NAME, APP, tag, cores
. ./script_config

# Count number of simulations to do
num_sims=${#cores[@]}

for (( i=0;i<$num_sims;i++)); do
	
	# Build output dir
	output_dir="${APP_NAME}_${cores[${i}]}cores${tag}"

	# Run command
	CMD="python tools/parse_output.py --results-dir=${output_dir}"
	eval $CMD

done

# Compile csv
rm -f results.csv
touch results.csv

# Count fields
num_fields=`eval "cat results/${APP_NAME}_${cores[1]}cores${tag}/stats.out | wc -l"`

# Write fields
fields=""
for (( j=1;j<$num_fields+1;j++)); do
	line=`eval "sed '${j}q;d' results/${APP_NAME}_${cores[$((num_sims-1))]}cores${tag}/stats.out | cut -f1 -d\"=\""`
	fields=${fields}${line},
done
echo ${fields} >> results.csv

# Write data
data=""
for (( i=0;i<$num_sims;i++)); do
	for (( j=1;j<$num_fields+1;j++)); do
		line=`eval "sed '${j}q;d' results/${APP_NAME}_${cores[${i}]}cores${tag}/stats.out | cut -f2 -d \"=\" | tr -d \'[[:space:]]\'"`
		data=${data}${line},
	done
	echo ${data} >> results.csv
	data=""
done
