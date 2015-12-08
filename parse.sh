#!/bin/bash

# Load vars that are shared by sweep and parse: APP_NAME, APP, tag, cores
. ./script_config

# Zip up configurations by alternating [<core> <freq> ... ]
jobs=()
for (( i=0; i<${#cores[@]}; i++ ))
do
        for (( j=0; j<${#freqs[@]}; j++ ))
        do
                jobs+=(${cores[i]})
                jobs+=(${freqs[j]})
        done
done
let "num_sims=${#jobs[@]}/2"

# Go into every folder and run python script
for (( i=0;i<$num_sims;i++)); do

	# Extract core and freq from jobs
	let "index=${i}*2"
	let "index_plus_one=${index}+1"
	this_core=${jobs[${index}]}
	this_freq=${jobs[${index_plus_one}]}
	
	# Build output dir
	output_dir="${APP_NAME}_${this_core}cores_${this_freq}GHz${tag}"

	# Run command
	CMD="python tools/parse_output.py --results-dir=${output_dir}"
	eval $CMD

done

# Compile csv
rm -f results.csv
touch results.csv

# Count fields
num_fields=`eval "cat results/${output_dir}/stats.out | wc -l"`

# Write fields
fields=""
for (( j=1;j<$num_fields+1;j++)); do
	line=`eval "sed '${j}q;d' results/${output_dir}/stats.out | cut -f1 -d\"=\""`
	fields=${fields}${line},
done
echo ${fields} >> results.csv

# Write data
data=""
for (( i=0;i<$num_sims;i++)); do
	# Extract core and freq from jobs
	let "index=${i}*2"
        let "index_plus_one=${index}+1"
        this_core=${jobs[${index}]}
        this_freq=${jobs[${index_plus_one}]}

	for (( j=1;j<$num_fields+1;j++)); do
		line=`eval "sed '${j}q;d' results/${APP_NAME}_${this_core}cores_${this_freq}GHz${tag}/stats.out | cut -f2 -d \"=\" | tr -d \'[[:space:]]\'"`
		data=${data}${line},
	done
	echo ${data} >> results.csv
	data=""
done
