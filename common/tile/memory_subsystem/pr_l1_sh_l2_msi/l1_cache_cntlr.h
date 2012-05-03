#pragma once

#include <string>
using std::string;

// Forward declaration
namespace PrL1ShL2MSI
{
   class MemoryManager;
}

#include "tile.h"
#include "cache.h"
#include "cache_line_info.h"
#include "address_home_lookup.h"
#include "shmem_msg.h"
#include "mem_component.h"
#include "semaphore.h"
#include "lock.h"
#include "fixed_types.h"
#include "shmem_perf_model.h"

namespace PrL1ShL2MSI
{
   class L1CacheCntlr
   {
   public:
      L1CacheCntlr(MemoryManager* memory_manager,
                   AddressHomeLookup* L2_cache_home_lookup,
                   UInt32 cache_line_size,
                   UInt32 L1_icache_size,
                   UInt32 L1_icache_associativity,
                   string L1_icache_replacement_policy,
                   UInt32 L1_icache_access_delay,
                   bool L1_icache_track_miss_types,
                   UInt32 L1_dcache_size,
                   UInt32 L1_dcache_associativity,
                   string L1_dcache_replacement_policy,
                   UInt32 L1_dcache_access_delay,
                   bool L1_dcache_track_miss_types,
                   float frequency);
      ~L1CacheCntlr();

      Cache* getL1ICache() { return _L1_icache; }
      Cache* getL1DCache() { return _L1_dcache; }

      bool processMemOpFromCore(MemComponent::Type mem_component,
            Core::lock_signal_t lock_signal,
            Core::mem_op_t mem_op_type, 
            IntPtr ca_address, UInt32 offset,
            Byte* data_buf, UInt32 data_length,
            bool modeled);
      void handleMsgFromCore(ShmemMsg* shmem_msg);
      void handleMsgFromL2Cache(tile_id_t sender, ShmemMsg* shmem_msg);

   private:
      MemoryManager* _memory_manager;
      Cache* _L1_icache;
      Cache* _L1_dcache;
      AddressHomeLookup* _L2_cache_home_lookup;

      // Synchronization between the app and sim threads
      Lock _L1_icache_lock;
      Lock _L1_dcache_lock;
      Semaphore _app_thread_sem;
      Semaphore _sim_thread_sem;

      // Outstanding msg info
      UInt64 _outstanding_shmem_msg_time;
      ShmemMsg _outstanding_shmem_msg;

      // Operations of L1-I/L1-D cache
      void getCacheLineInfo(MemComponent::Type mem_component, IntPtr address, PrL1CacheLineInfo* L1_cache_line_info);
      void setCacheLineInfo(MemComponent::Type mem_component, IntPtr address, PrL1CacheLineInfo* L1_cache_line_info);
      void readCacheLine(MemComponent::Type mem_component, IntPtr address, Byte* data_buf);
      void insertCacheLine(MemComponent::Type mem_component, IntPtr address, CacheState::Type cstate, Byte* data_buf);
      void invalidateCacheLine(MemComponent::Type mem_component, IntPtr address);

      void accessCache(MemComponent::Type mem_component,
                       Core::mem_op_t mem_op_type, 
                       IntPtr ca_address, UInt32 offset,
                       Byte* data_buf, UInt32 data_length);
      pair<bool, Cache::MissType> operationPermissibleinL1Cache(MemComponent::Type mem_component, 
                                                                IntPtr address, Core::mem_op_t mem_op_type,
                                                                UInt32 access_num);

      Cache* getL1Cache(MemComponent::Type mem_component);
      ShmemMsg::Type getShmemMsgType(Core::mem_op_t mem_op_type);

      // Specific msg handling
      void processExRepFromL2Cache(tile_id_t sender, ShmemMsg* shmem_msg);
      void processShRepFromL2Cache(tile_id_t sender, ShmemMsg* shmem_msg);
      void processUpgradeRepFromL2Cache(tile_id_t sender, ShmemMsg* shmem_msg);
      void processInvReqFromL2Cache(tile_id_t sender, ShmemMsg* shmem_msg);
      void processFlushReqFromL2Cache(tile_id_t sender, ShmemMsg* shmem_msg);
      void processWbReqFromL2Cache(tile_id_t sender, ShmemMsg* shmem_msg);

      tile_id_t getL2CacheHome(IntPtr address);

      // Utilities
      tile_id_t getTileId();
      UInt32 getCacheLineSize();
      MemoryManager* getMemoryManager()   { return _memory_manager; }
      ShmemPerfModel* getShmemPerfModel();

      // Locks since both app and sim threads work on this object
      void acquireLock(MemComponent::Type mem_component);
      void releaseLock(MemComponent::Type mem_component);
      
      // Synchronization operations between User and sim threads
      void wakeUpAppThread();
      void waitForAppThread();
      void wakeUpSimThread();
      void waitForSimThread();
   };
}
