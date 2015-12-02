#!/bin/bash

# Specify app to run
APP_NAME="mandelbrot"
APP="${APP_NAME}_app_test"
APP_FLAGS="64 64"

# Tag to stick at the end of all results files in this sweep
tag="_beastmode"

# Specify number of cores to have in each simulation
cores=(2 4 8 16 24 32 48 64) 

# Specify available machines
MACHINES=( 'rsg-vm0.stanford.edu' 'rsg-vm1.stanford.edu' 'rsg-vm2.stanford.edu' 'rsg-vm3.stanford.edu' )
# Count number of machines available
num_machines=${#MACHINES[@]}

# Make sure we are only running one process
sed -i '/num_processes =/c\num_processes = 1' carbon_sim.cfg

# Clean the servers
CMD="pkill -9 -f ${APP_NAME}"
eval $CMD
sleep 2 


# Initialize counters
machine_num=-1
iter_num=-1

while [ ${#cores[@]} -gt 0 ]; do
	# Inc counter and wrap
	let "machine_num = (machine_num + 1) % $num_machines"
	num_sims=${#cores[@]}
	let "iter_num = (iter_num + 1) % $num_sims"

	# Check if there is a sim running on this machine
	this_pid=${pids[${machine_num}]}
	if [[ -z "$this_pid" ]]
	then
		pid_text=""
	else
		CMD="ps -p $this_pid | grep -v PID"
		pid_text=`eval ${CMD}`
	fi
	
	if [[ -z "$pid_text" ]]
	then
		# Set config to run on specific machine	
		CMD="sed -i '/process0/c\process0 = \"${MACHINES[${machine_num}]}\"' carbon_sim.cfg"
		eval $CMD
	
		# Set number of cores
		CMD="sed -i '/total_cores = /c\total_cores = ${cores[${iter_num}]}' carbon_sim.cfg"
		eval $CMD

		# Figure out how many threads to set mandelbrot to
		let "num_threads = ${cores[${iter_num}]} - 1"
	
		# Build output dir
		output_dir="${APP_NAME}_${cores[${iter_num}]}cores${tag}"

		# Run command
		CMD="make ${APP} AF=\"${APP_FLAGS} ${num_threads}\" O=\"${output_dir}\" &"
		eval $CMD
		pids[$machine_num]=$!	
	
		# Remove this job from list and reindex
		unset cores[${iter_num}]
		cores=( "${cores[@]}" )

		sleep 4
	
	else
		echo "PID ${this_pid} still running (${MACHINES[${machine_num}]})"
		sleep 10
	fi

		
done
