#!/bin/bash

# Load vars that are shared between sweep and parse: APP_NAME, APP, APP_FLAGS, tag, cores
. ./script_config

# Make sure we are only running one process
sed -i '/num_processes =/c\num_processes = 1' carbon_sim.cfg

# Clean the servers
echo "Killing apps that were running previously"
CMD="pkill -9 -f ${APP_NAME}"
eval $CMD
sleep 3

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

# Initialize counters
machine_num=-1
iter_num=-1

while [ ${#jobs[@]} -gt 0 ]; do
	# Inc counter and wrap
	let "machine_num = (machine_num + 1) % $num_machines"
	let "num_sims=${#jobs[@]}/2"
	let "iter_num = (iter_num + 1) % $num_sims"

	# Extract machine, core, and freq from jobs
	this_machine=${MACHINES[${machine_num}]}
	let "index=${iter_num}*2"
	let "index_plus_one=${index}+1"
	this_core=${jobs[index]}
	this_freq=${jobs[index_plus_one]}

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
		./edit_cfg.sh ${this_core} ${this_freq} ${this_machine}	
		source ./read_cfg.sh

		# Run command and plug the pid into the pids array for future monitoring
		CMD="make ${APP} AF=\"${APP_FLAGS} ${mandel_threads}\" O=\"${output_dir}\" &"
		eval $CMD
		pids[$machine_num]=$!	
	
		# Remove this job from list and reindex
		unset jobs[${index}]
		unset jobs[${index_plus_one}]
		jobs=( "${jobs[@]}" )

		sleep 4
	
	else
		echo "Tried to run ${this_core}-core, ${this_freq}-GHz sim on ${this_machine}, but PID ${this_pid} of previous sim is still running there."
		sleep 10
	fi

		
done


