#!/bin/bash

# Load vars that are shared between sweep and parse: APP_NAME, APP, APP_FLAGS, tag, cores
. ./script_config

# Make sure we are only running one process
sed -i '/num_processes =/c\num_processes = 1' carbon_sim.cfg

# Clean the servers
echo "Killing apps that were running previously"
CMD="pkill -9 -f ${APP_NAME}"
eval $CMD
sleep 2

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

# Remove "exempt" jobs
for (( i=0; i<${#exempt[@]}/2; i++ ))
do
	field1=${exempt[2*i]}
	field2=${exempt[2*i+1]}
	found=0
	for (( j=0; j<${#jobs[@]}/2; j++ ))
	do
		if [[ ${jobs[2*j]} = $field1 && ${jobs[2*j+1]} = $field2 ]];
		then
			unset jobs[2*j]
			unset jobs[2*j+1]
			jobs=( "${jobs[@]}" )
			found=1
		fi
	done
	if [[ $found -eq 1 ]];
	then
		echo "Removed ${field1} ${field2} from jobs list"
	else
		echo "Could not find ${field1} ${field2} in jobs list"
	fi
done

# Initialize counters
machine_num=-1
iter_num=-1

# Initialize core diagnostics
machine_stats=()
for (( i=0; i<$num_machines; i++ ))
do
	machine_stats+=(-1)
done

while [ ${#jobs[@]} -gt 0 ]; do
	# Inc counter and wrap
	let "machine_num = (machine_num + 1) % $num_machines"
	let "num_sims=${#jobs[@]}/2"
	let "iter_num = (iter_num + 1) % $num_sims"

	# Extract machine, core, and freq from jobs
	this_machine=${MACHINES[${machine_num}]}
	let "index=${iter_num}*2"
	let "index_plus_one=${index}+1"
	this_par1=${jobs[index]}
	this_par2=${jobs[index_plus_one]}

	# Check if there is a sim running on this machine
	this_pid=${pids[${machine_num}]}
	if [[ -z "$this_pid" ]]
	then
		pid_text=""
	else
		CMD="ps -p $this_pid | grep -v PID"
		pid_text=`eval ${CMD}`
	fi

	# If this machine relinquished its graphite run ps #, then launch new one	
	if [[ -z "$pid_text" ]]
	then
		# Handle config file edits and parsing
		./edit_cfg.sh ${this_par1} ${this_par2} ${this_machine} ${sweep_type}	
		source ./read_cfg.sh

		# Run command and plug the pid into the pids array for future monitoring
		CMD="make ${APP} AF=\"${APP_FLAGS} ${num_threads}\" O=\"${output_dir}\" &"
		eval $CMD
		pids[$machine_num]=$!	
	
		# Update machine stats
		let "new_stat = ${machine_stats[${machine_num}]} + 1"
		machine_stats[${machine_num}]=$new_stat
		
		# Remove this job from list and reindex
		unset jobs[${index}]
		unset jobs[${index_plus_one}]
		jobs=( "${jobs[@]}" )

		sleep 4
	
	else
		echo "Tried to run ${this_par1}, ${this_par2} sim on ${this_machine}, but blocked by PID ${this_pid}. Machine stats: ${machine_stats[@]}" | tee -a log
		date | tee -a log
		sleep 12
	fi

		
done


