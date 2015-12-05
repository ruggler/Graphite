## Read back config to get values
# Count cores
parsed_cores=`cat carbon_sim.cfg | grep "total_cores = " | awk -F"= " '{print $2}'`

# Count freq
parsed_freq=`cat carbon_sim.cfg | grep "domains = " | awk -F "<" '{print $2}' | awk -F "," '{print $1}'`

# Make threads equal to cores minus one (for mandelbrot)
let "mandel_threads = ${parsed_cores} - 1"

## Set output dir
output_dir=${APP_NAME}_${parsed_cores}cores_${parsed_freq}GHz${tag}

## Export them
export mandel_threads
export output_dir
