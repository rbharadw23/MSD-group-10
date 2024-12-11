package cache_config_pkg;

    // Cache configuration parameters
    parameter int CACHE_SIZE = 16 * 1024 * 1024;  // 16 MB cache size
    parameter int LINE_SIZE = 64;  // 64-byte cache line size
    parameter int SET_ASSOCIATIVITY = 16;  // 16-way set associative
    parameter int NUM_SETS = CACHE_SIZE / (LINE_SIZE * SET_ASSOCIATIVITY);  // Number of sets 16,384
    parameter int BLOCK_OFFSET_BITS = 6;  // log2(LINE_SIZE) -> 64 bytes = 2^6 = 6 bits
    parameter int INDEX_BITS = 14;  // log2(NUM_SETS) -> 16384 sets = 2^14 = 14 bits
    parameter int TAG_BITS = 12;  // ADDR 32 BITS - (BLOCK_OFFSET_BITS + INDEX_BITS) = 12 bits

typedef enum logic [1:0] {M,E,S,I} mesistate;
typedef enum { READ, WRITE, INVALIDATE, RWIM } busOp;
typedef enum { NOHIT, HIT, HITM } Snoopresult;
typedef enum { GETLINE, SENDLINE, INVALIDATELINE, EVICTLINE } message;

   typedef struct {
        logic [TAG_BITS-1:0] tag;  // Tag field
         mesistate MESI_BITS=I;
    } cache_block_t;

 typedef struct { 
logic [14:0] PLRU;
cache_block_t CACHE_INDEX [SET_ASSOCIATIVITY-1:0];
} cache_set_t;  //15PLRU bits per each set

endpackage : cache_config_pkg
