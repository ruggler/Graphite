# Arg 1 = cores
# Arg 2 = freq
# Arg 3 = machine name


## Edit config
if [[ "$4" = "corefreq" ]];
then
	# Set cores
	CMD="sed -i '/total_cores = /c\total_cores = $1' carbon_sim.cfg"
	eval $CMD
	
	# Set freq
	CMD="sed -i '/domains = /c\domains = \"<$2, CORE, L1_ICACHE, L1_DCACHE, L2_CACHE, DIRECTORY, NETWORK_USER, NETWORK_MEMORY>\"' carbon_sim.cfg"
	eval $CMD
elif [[ "$4" = "l1dstress" ]];
then
	# Set l1d latency 
	CMD="sed -i '/L1D_data_latency/c\data_access_time = $1	# In cycles L1D_data_latency' carbon_sim.cfg"
	eval $CMD
	
	# Set l1d line size
	CMD="sed -i '/L1D_line_size/c\cache_line_size = $2		# In Bytes L1D_line_size' carbon_sim.cfg"
	eval $CMD
fi
	
# Set Machine name
CMD="sed -i '/process0/c\process0 = \"$3\"' carbon_sim.cfg"
eval $CMD
	
