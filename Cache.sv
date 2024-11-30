//CACHE SPEC SUMMARY:
//CACHE SIZE: 16 MB
//LINE_SIZE : 64 bytes
//SET_ASSOCIATIVITY: 16-way
//Number of SETS = CACHE_SIZE / (LINE_SIZE * SET_ASSOCIATIVITY) : 16,384 sets
//Number of CACHE LINES : 262,144 lines
//ADDR : 32-bit address):
//TAG : 12 bits
//INDEX : 14 bits
//BLOCK OFFSET : 6 bits
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Cache Simulator Module: cache_simulator.sv

`include "Packages.sv"  // Include the cache parameters package

module cache_simulator();
// Use parameters from the cache_config_pkg package
import cache_config_pkg::*; 

    cache_set_t cache [NUM_SETS-1:0];  // declaring array of 16,384 cache sets

    string default_file = "rwims.din"; // Signals for reading input file
    string input_file; //string input_filename = "input.txt";
    bit [31:0] address;
    bit [1:0] opcode;
    integer status;
    string line;
    integer file;

// Initialize cache: Set all blocks as invalid
initial begin
    foreach (cache[index]) begin
        foreach (cache[index].CACHE_INDEX[i]) begin
            cache[index].CACHE_INDEX[i].valid = 0;
        end
    end
end

   initial begin
        // Check if the user provided a file name via $value$plusargs
        if (!$value$plusargs("trace_file=%s", input_file)) begin
            // No input file specified, use default
            input_file = default_file;
        end
         
        // Attempt to open the file
        file = $fopen(input_file, "r");
        if (file == 0) begin
            $display("Error: Could not open the trace file '%s'.", input_file);
            $finish;
            end
        else begin
            $display("Successfully opened the trace file '%s'.", input_file);
        end 

        // Process each line in the file
        while (!$feof(file)) begin
            $fscanf(file, "%b %h\n", opcode, address);
            if (opcode ==0) begin
                cache_access(address, 0);  // Load operation
            end else if (opcode == "1") begin
                cache_access(address, 1);  // Store operation
            end else begin
                $display("Unknown opcode: %s", opcode);
            end
        end
        $fclose(file);
    end

// Function to extract tag, index, and block offset from the address
    task get_cache_parts(input [31:0] address, output [TAG_BITS-1:0] tag, output [INDEX_BITS-1:0] index, output [BLOCK_OFFSET_BITS-1:0] block_offset);
        begin
            block_offset = address[BLOCK_OFFSET_BITS-1:0];  // Least significant 6 bits
            index = address[BLOCK_OFFSET_BITS + INDEX_BITS-1:BLOCK_OFFSET_BITS];  // Next 14 bits
            tag = address[31:BLOCK_OFFSET_BITS + INDEX_BITS];  // Remaining bits
        end
    endtask

    // Check cache for hit or miss
    task cache_access(input [31:0] address, input logic opcode);
        logic [TAG_BITS-1:0] tag;
        logic [INDEX_BITS-1:0] index;
        logic [BLOCK_OFFSET_BITS-1:0] block_offset;
        logic hit;
        integer i;

        // Extract tag, index, and block offset
        get_cache_parts(address, tag, index, block_offset);


// Check for hit in the set
hit = 0; 

foreach (cache[index]) begin
    foreach (cache[index].CACHE_INDEX[i]) begin
        if (cache[index].CACHE_INDEX[i].valid && (cache[index].CACHE_INDEX[i].tag == tag)) begin
            hit = 1;  // Cache hit
            break;
        end
    end
end

if (hit) begin
            $display("Cache HIT for %s address 0x%h", opcode ? "STORE" : "LOAD", address);
end
 
else begin
            $display("Cache MISS for %s address 0x%h", opcode ? "STORE" : "LOAD", address);

foreach (cache[index]) begin
    foreach (cache[index].CACHE_INDEX[i]) begin
        if (!cache[index].CACHE_INDEX[i].valid) begin
            cache[index].CACHE_INDEX[i].valid = 1;  // Mark the block as valid
            cache[index].CACHE_INDEX[i].tag = tag; // Assign the tag
            break;
            end
        end
    end
end
endtask


endmodule

