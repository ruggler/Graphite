# Arg 1 = cores
# Arg 2 = freq
# Arg 3 = machine name


## Edit config
# Set cores
CMD="sed -i '/total_cores = /c\total_cores = $1' carbon_sim.cfg"
eval $CMD

# Set freq
CMD="sed -i '/domains = /c\domains = \"<$2, CORE, L1_ICACHE, L1_DCACHE, L2_CACHE, DIRECTORY, NETWORK_USER, NETWORK_MEMORY>\"' carbon_sim.cfg"
eval $CMD

# Set Machine name
CMD="sed -i '/process0/c\process0 = \"$3\"' carbon_sim.cfg"
eval $CMD

