#!/bin/bash

# Specify app to run
APP_NAME="mandelbrot"
APP="${APP_NAME}_app_test"
APP_FLAGS="64 64"

# Specify number of cores to have in each simulation
cores=(32)
# Count number of simulations to de
num_sims=${#cores[@]}

# Specify available machines
MACHINES=( 'rsg-vm0.stanford.edu' 'rsg-vm1.stanford.edu' 'rsg-vm2.stanford.edu' 'rsg-vm3.stanford.edu' )
# Count number of machines available
num_machines=${#MACHINES[@]}

# Make sure we are only running one process
sed -i '/num_processes =/c\num_processes = 1' carbon_sim.cfg

for (( i=0;i<$num_sims;i++)); do
	# Figure out which machine to run this sim on
	let "machine_num = i % $num_machines" 
	# Set config to run on this machine
	CMD="sed -i '/process0/c\process0 = \"${MACHINES[${machine_num}]}\"' carbon_sim.cfg"
	eval $CMD
	
	# Set number of cores
	CMD="sed -i '/total_cores = /c\total_cores = ${cores[${i}]}' carbon_sim.cfg"
	eval $CMD

	# Figure out how many threads to set mandelbrot to
	let "num_threads = ${cores[${i}]} - 1"
	
	# Build output dir
	output_dir="${APP_NAME}_${cores[${i}]}cores"

	# Clean the remote server first
	CMD="ssh ${MACHINES[${machine_num}]} pkill -9 -f ${APP_NAME}"
	eval $CMD
	sleep 1

	# Run command
	CMD="make ${APP} AF=\"${APP_FLAGS} ${num_threads}\" O=\"${output_dir}\" &"
	echo $CMD
	eval $CMD

	sleep 2
done
