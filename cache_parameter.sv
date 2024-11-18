package parameters_defn;

parameter CACHE_LINES=64;  			// in bytes
parameter ADDR_WIDTH=32;
parameter DATA_WIDTH=32;
parameter LINE_SIZE=16;
parameter OFFSET_BITS=6;
parameter INDEX_BITS=4;
parameter TAG_BITS= ADDR_WIDTH - (OFFSET_BITS + INDEX_BITS);
  
endpackage
