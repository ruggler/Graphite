#!/usr/bin/env python

import re
import sys
import numpy
from optparse import OptionParser

global output_file_contents
global num_cores

def searchKey(key, line):
   global num_cores
   key += "(.*)"
   match_key = re.search(key, line)
   if match_key:
      counts = line.split('|')
      event_counts = counts[1:num_cores+1]
      for i in range(0, num_cores):
         if (len(event_counts[i].split()) == 0):
            event_counts[i] = "0.0"
      return map(lambda x: float(x), event_counts)
   return None

def rowSearch1(heading, key):
   global output_file_contents
   heading_found = False
   for line in output_file_contents:
      if heading_found:
         value = searchKey(key, line)
         if value:
            return value
      else:
         heading_found = (re.search(heading, line) != None)

   print "\033[91mERROR: \033[0mCould not find key [%s,%s]" % (heading, key)
   sys.exit(1)

def rowSearch2(heading, sub_heading, key):
   global output_file_contents
   heading_found = False
   sub_heading_found = False
   for line in output_file_contents:
      if heading_found:
         if sub_heading_found:
            value = searchKey(key, line)
            if value:
               return value
         else:
            sub_heading_found = (re.search(sub_heading, line) != None)
      else:
         heading_found = (re.search(heading, line) != None)

   print "\033[91mERROR: \033[0mCould not find key [%s,%s,%s]" % (heading, sub_heading, key)
   sys.exit(1)

def getTime(key):
   global output_file_contents

   key += "\s+([0-9]+)\s*"
   for line in output_file_contents:
      match_key = re.search(key, line)
      if match_key:
         return float(match_key.group(1))
   print "\033[91mERROR: \033[0mCould not find key [%s]" % (key)
   sys.exit(2)

parser = OptionParser()
parser.add_option("--results-dir", dest="results_dir", help="Graphite Results Directory")
#parser.add_option("--num-cores", dest="num_cores", type="int", help="Number of Cores")
(options,args) = parser.parse_args()
options.results_dir = 'results/%s' % options.results_dir

# Read Results Files
try:
   output_file_contents = open("%s/sim.out" % (options.results_dir), 'r').readlines()
except IOError:
   print "\033[91mERROR: \033[0mCould not open file (%s/sim.out)" % (options.results_dir)
   sys.exit(3)

print "Parsing simulation output file: %s/sim.out" % (options.results_dir)
# Having it check the cfg for num_cores rather than having user input it
#num_cores = options.num_cores
cfg_text = open("%s/carbon_sim.cfg" % (options.results_dir), 'r').readlines()
for line in cfg_text:
   if (line.find("total_cores = ") != -1):
      num_cores = line[ line.find("total_cores = ") + 14 : len(line) ] ;
      num_cores = int(num_cores)
      break
# Fix lines below in case we set the num cores with command line
#command_text = open("%s/command" % (options.results_dir), 'r').readlines()
#for line in command_text:
#   if (line.find("CORES=")):
#      num_cores = line[ line.find("CORES=") + 6 : line.find("CORES=") + 10]

# See if this was a power sim
pwr_model = False
for line in cfg_text:
   if (line.find("enable_power_modeling = true")>-1):
      pwr_model = True
      break

# Total Instructions
target_instructions = sum(rowSearch1("Core Summary", "Total Instructions"))

# Completion Time - In nanoseconds
target_time = max(rowSearch1("Core Summary", "Completion Time \(in nanoseconds\)"))


# Host Time
host_time = getTime("Shutdown Time \(in microseconds\)")
host_initialization_time = getTime("Start Time \(in microseconds\)")
host_working_time = getTime("Stop Time \(in microseconds\)") - getTime("Start Time \(in microseconds\)")
host_shutdown_time = getTime("Shutdown Time \(in microseconds\)") - getTime("Stop Time \(in microseconds\)")

# Energy - In joules
if (pwr_model == True):
   core_energy = "%f" % sum(rowSearch2("Tile Energy Monitor Summary", "Core", "Total Energy \(in J\)"))
   cache_hierarchy_energy = "%f" % sum(rowSearch2("Tile Energy Monitor Summary", "Cache Hierarchy \(L1-I, L1-D, L2\)", "Total Energy \(in J\)"))
   networks_energy = "%f" % sum(rowSearch2("Tile Energy Monitor Summary", "Networks \(User, Memory\)", "Total Energy \(in J\)"))
   target_energy = "%f" % (float(core_energy) + float(cache_hierarchy_energy) + float(networks_energy))
   edp = float(host_time) * (float(target_energy)) / 1000000
   edp = "%f" % edp
else:
   print "No energy data found."
   core_energy = "N/A";
   cache_hierarchy_energy = "N/A";
   networks_energy = "N/A";
   target_energy = "N/A";
   edp = "N/A";

# Average Frequency (GHz) over all cores
avg_freq = sum(rowSearch1("Core Summary", "Average Frequency \(in GHz\)"))/num_cores

# Get MPKI on each core
instr_per_core = rowSearch1("Core Summary", "Total Instructions")
L1I_access_per_core = rowSearch2("Cache Summary", "Cache L1-I", "Cache Accesses")
L1D_access_per_core = rowSearch2("Cache Summary", "Cache L1-D", "Cache Accesses")
L2_access_per_core = rowSearch2("Cache Summary", "Cache L2", "Cache Accesses")
L1I_miss_per_core = rowSearch2("Cache Summary", "Cache L1-I", "Cache Misses")
L1D_miss_per_core = rowSearch2("Cache Summary", "Cache L1-D", "Cache Misses")
L2_miss_per_core = rowSearch2("Cache Summary", "Cache L2", "Cache Misses")
# Catch any denoms with 0
L1I_access_per_core = [1 if x == 0 else x for x in L1I_access_per_core]
L1D_access_per_core = [1 if x == 0 else x for x in L1D_access_per_core]
L2_access_per_core = [1 if x == 0 else x for x in L2_access_per_core]
instr_per_core = [1 if x == 0 else x for x in instr_per_core]
# Compute things per core
L1I_missrate_per_core = [a/b for a,b in zip(L1I_miss_per_core, L1I_access_per_core)]
L1D_missrate_per_core = [a/b for a,b in zip(L1D_miss_per_core, L1D_access_per_core)]
L2_missrate_per_core = [a/b for a,b in zip(L2_miss_per_core, L2_access_per_core)] 
L1I_apki_per_core = [1000*a/b for a,b in zip(L1I_access_per_core, instr_per_core)]
L1D_apki_per_core = [1000*a/b for a,b in zip(L1D_access_per_core, instr_per_core)]
L2_apki_per_core = [1000*a/b for a,b in zip(L2_access_per_core, instr_per_core)]
# Summaries of miss rate and apki
L1I_avg_missrate = 100*sum(L1I_miss_per_core) / sum(L1I_access_per_core)
L1D_avg_missrate = 100*sum(L1D_miss_per_core) / sum(L1D_access_per_core)
L2_avg_missrate = 100*sum(L2_miss_per_core) / sum(L2_access_per_core)
L1I_avg_apki = 100*sum(L1I_access_per_core) / sum(instr_per_core)
L1D_avg_apki = 100*sum(L1D_access_per_core) / sum(instr_per_core)
L2_avg_apki = 100*sum(L2_access_per_core) / sum(instr_per_core)

# Write event counters to a file
stats_file = open("%s/stats.out" % (options.results_dir), 'w')

# Useful things
stats_file.write("Num-Cores = %i\n" % (num_cores))
stats_file.write("Frequency (GHz) = %f\n" % (avg_freq))
stats_file.write("Target-Time (s) = %f\n" % (target_time/1000000000))
stats_file.write("Target-Energy (J)= %s\n" % (target_energy))
stats_file.write("EDP (us*J) = %s\n" % edp)
stats_file.write("Average L1I Miss Rate = %f\n" % L1I_avg_missrate)
stats_file.write("Average L1D Miss Rate = %f\n" % L1D_avg_missrate)
stats_file.write("Average L2 Miss Rate = %f\n" % L2_avg_missrate)
stats_file.write("Average L1I Accesses per K-Instr = %f\n" % L1I_avg_apki)
stats_file.write("Average L1D Accesses per K-Instr = %f\n" % L1D_avg_apki)
stats_file.write("Average L2 Accesses per K-Instr = %f\n" % L2_avg_apki)

 
#for i in range(0,num_cores):
#   stats_file.write("L1I Miss Rate @ Core: %i = %f\n" % (i, L1I_missrate_per_core[i]))
#for i in range(0,num_cores):
#   stats_file.write("L1D Miss Rate @ Core: %i = %f\n" % (i, L1D_missrate_per_core[i]))
#for i in range(0,num_cores):
#   stats_file.write("L2 Miss Rate @ Core: %i = %f\n" % (i, L2_missrate_per_core[i]))

#for i in range(0,num_cores):
#   stats_file.write("L1I Accesses / k-Instr @ Core: %i = %f\n" % (i, L1I_apki_per_core[i]))
#for i in range(0,num_cores):
#   stats_file.write("L1D Accesses / k-Instr @ Core: %i = %f\n" % (i, L1D_apki_per_core[i]))
#for i in range(0,num_cores):
#   stats_file.write("L2 Accesses / k-Instr @ Core: %i = %f\n" % (i, L2_apki_per_core[i]))

# Less useful things
stats_file.write("Target-Instructions = %e\n" % (target_instructions))
#stats_file.write("Target-Core-Energy = %s\n" % (core_energy))
#stats_file.write("Target-Cache-Hierarchy-Energy = %s\n" % (cache_hierarchy_energy))
#stats_file.write("Target-Networks-Energy = %s\n" % (networks_energy))
#stats_file.write("Host-Time = %f\n" % (host_time/1000000))
#stats_file.write("Host-Initialization-Time = %f\n" % (host_initialization_time/1000000))
#stats_file.write("Host-Working-Time = %f\n" % (host_working_time/1000000))
#stats_file.write("Host-Shutdown-Time = %f\n" % (host_shutdown_time/1000000))
stats_file.close()

print "\033[92mSUCCESS: \033[0m Wrote stats file: %s/stats.out" % (options.results_dir)

