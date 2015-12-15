## Read back config to get values
# Count cores
parsed_cores=`cat carbon_sim.cfg | grep "total_cores = " | awk -F"= " '{print $2}'`

# Count freq
parsed_freq=`cat carbon_sim.cfg | grep "domains = " | awk -F "<" '{print $2}' | awk -F "," '{print $1}'`

# Count L1D Line Size
parsed_L1D_line_size=`cat carbon_sim.cfg | grep "L1D_line_size" | awk -F"= " '{print $2}' | awk -F" " '{print $1}'`

# Count L1D data latency
parsed_L1D_data_latency=`cat carbon_sim.cfg | grep "L1D_data_latency" | awk -F"= " '{print $2}' | awk -F" " '{print $1}'`

# Make threads equal to cores minus one (for mandelbrot and compute_MT1)
let "num_threads = ${parsed_cores} - 1"

## Set output dir
if [[ "$sweep_type" = "corefreq" ]];
then
	id1=${parsed_cores}cores
	id2=${parsed_freq}GHz
elif [[ "$sweep_type" = "l1dstress" ]];
then
	id1=${parsed_L1D_line_size}bytes
	id2=${parsed_L1D_data_latency}cycles
fi
output_dir=${APP_NAME}_${id1}_${id2}${tag}

## Export them
export num_threads
export output_dir
