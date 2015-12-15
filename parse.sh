#!/bin/bash

# Load vars that are shared by sweep and parse: APP_NAME, APP, tag, cores
. ./script_config

# Zip up configurations by alternating [<core> <freq> ... ] or [<latency> <linesize> ... ]
jobs=()
if [[ "$sweep_type" = "corefreq" ]];
then
        for (( i=0; i<${#cores[@]}; i++ ))
        do
                for (( j=0; j<${#freqs[@]}; j++ ))
                do
                        jobs+=(${cores[i]})
                        jobs+=(${freqs[j]})
                done
        done
elif [[ "$sweep_type" = "l1dstress" ]];
then
        for (( i=0; i<${#latencies[@]}; i++ ))
        do
                for (( j=0; j<${#linesizes[@]}; j++ ))
                do
                        jobs+=(${latencies[i]})
                        jobs+=(${linesizes[j]})
                done
        done
else
	echo "ERROR: sweep_type not recognized"
	exit
fi

let "num_sims=${#jobs[@]}/2"

# Go into every folder and run python script
for (( i=0; i<$num_sims;i++)); do

	# Extract core and freq from jobs
	let "index=${i}*2"
	let "index_plus_one=${index}+1"
	id1=${jobs[${index}]}
	id2=${jobs[${index_plus_one}]}
	
	# Build output dir
	if [[ "$sweep_type" = "corefreq" ]];
	then
	        id1=${id1}cores
	        id2=${id2}GHz
	elif [[ "$sweep_type" = "l1dstress" ]];
	then
	        id1=${id1}bytes
	        id2=${id2}cycles
	fi
	output_dir=${APP_NAME}_${id1}_${id2}${tag}

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
	id1=${jobs[${index}]}
	id2=${jobs[${index_plus_one}]}
	
	# Build output dir
	if [[ "$sweep_type" = "corefreq" ]];
	then
	        id1=${id1}cores
	        id2=${id2}GHz
	elif [[ "$sweep_type" = "l1dstress" ]];
	then
	        id1=${id1}bytes
	        id2=${id2}cycles
	fi
	output_dir=${APP_NAME}_${id1}_${id2}${tag}

	for (( j=1;j<$num_fields+1;j++)); do
		line=`eval "sed '${j}q;d' results/${output_dir}/stats.out | cut -f2 -d \"=\" | tr -d \'[[:space:]]\'"`
		data=${data}${line},
	done
	echo ${data} >> results.csv
	data=""
done
