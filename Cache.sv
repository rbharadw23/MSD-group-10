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

 task automatic rd_req_from_l1_hit(input [13:0] index, input [11:0] tag);
    begin
    integer i;
    //bit [13:0]index=index_bits;
    //bit [14:0] local_PLRU = cache[index].plru_tree; // Accessing PLRU from the cache set
    //bit [3:0] selected_victim = victim_cache(local_PLRU);
    
				if (cache[index].CACHE_INDEX[i].MESI_BITS == S)begin
					MessageToCache(SENDLINE,address); // if needed like this
                                        BusOperation(opcode,address,result); 
				end
			    else if (cache[index].CACHE_INDEX[i].MESI_BITS == M)begin
					MessageToCache(SENDLINE,address);
                                        BusOperation(opcode,address,result);                            
				end
				else if (cache[index].CACHE_INDEX[i].MESI_BITS == E)begin
				    MessageToCache(SENDLINE,address);
                                        BusOperation(opcode,address,result);
				end
       end    
    endtask

    task automatic wr_req_from_l1_hit(input [13:0] index, input [11:0] tag);
       begin
     integer i;
    //bit [13:0]index=index_bits;
                if (cache[index].CACHE_INDEX[i].MESI_BITS == S)begin
					//busOp = INVALIDATE;
					MessageToCache(GETLINE,address);
					cache[index].CACHE_INDEX[i].MESI_BITS = M;
                                        BusOperation(opcode,address,result);
				end
			    else if (cache[index].CACHE_INDEX[i].MESI_BITS == M)begin
                                        BusOperation(opcode,address,result);
				end
				else if (cache[index].CACHE_INDEX[i].MESI_BITS == E)begin
				    MessageToCache(GETLINE,address);
					cache[index].CACHE_INDEX[i].MESI_BITS = M;
                                        BusOperation(opcode,address,result);
				end
        end 
     endtask

    task automatic rd_req_instr_from_l1_hit(input [13:0] index, input [11:0] tag);
       begin
    integer i;
    //bit [13:0]index=index_bits;
				if (cache[index].CACHE_INDEX[i].MESI_BITS == S)begin
					MessageToCache(SENDLINE,address);
                                        BusOperation(opcode,address,result);
				end
			    else if (cache[index].CACHE_INDEX[i].MESI_BITS == M)begin
					MessageToCache(SENDLINE,address); 
                                        BusOperation(opcode,address,result);
				end
				else if (cache[index].CACHE_INDEX[i].MESI_BITS == E)begin
				    MessageToCache(SENDLINE,address);
                                        BusOperation(opcode,address,result);
				end
       end
    endtask

    task automatic snoop_rd_req_hit(input [13:0] index, input [11:0] tag);
      begin
    integer i;
   // bit [13:0]index=index_bits;
				if (cache[index].CACHE_INDEX[i].MESI_BITS == S) begin
					MessageToCache(SENDLINE,address);
                                        BusOperation(opcode,address,result);
				end
				else if (cache[index].CACHE_INDEX[i].MESI_BITS == M)begin
					//busOp = WRITE;
					MessageToCache(GETLINE,address);
					cache[index].CACHE_INDEX[i].MESI_BITS = S;
                                        BusOperation(opcode,address,result);
				end
				else if (cache[index].CACHE_INDEX[i].MESI_BITS == E)begin
                                        MessageToCache(SENDLINE,address);
                                        cache[index].CACHE_INDEX[i].MESI_BITS = S; 
                                        BusOperation(opcode,address,result);
				end
       end  
    endtask

    task automatic snoop_wr_req_hit(input [13:0] index, input [11:0] tag);//TA
      begin
    integer i;
    //bit [13:0]index=index_bits;
				if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
					MessageToCache(SENDLINE,address);
                                        BusOperation(opcode,address,result);
				end			
      end  
    endtask

    task automatic snoop_rd_rwim_hit(input [13:0] index, input [11:0] tag);//busrdx
     begin
    integer i;
    //bit [13:0]index=index_bits;

				if (cache[index].CACHE_INDEX[i].MESI_BITS == S) begin
					MessageToCache(INVALIDATELINE,address);
					cache[index].CACHE_INDEX[i].MESI_BITS = I;
                                        BusOperation(opcode,address,result);
				end
				else if (cache[index].CACHE_INDEX[i].MESI_BITS == M)begin
					//busOp = WRITE;
					MessageToCache(INVALIDATELINE,address);
					cache[index].CACHE_INDEX[i].MESI_BITS = I;
                                        BusOperation(opcode,address,result);
				end
				else if (cache[index].CACHE_INDEX[i].MESI_BITS == E)begin
					MessageToCache(INVALIDATELINE,address);
                                        BusOperation(opcode,address,result);
                                end
      end  
    endtask

    task automatic snoop_invalidate_hit(input [13:0] index, input [11:0] tag);//busupgr
     begin
    integer i;
    //bit [13:0]index=index_bits;

            if (cache[index].CACHE_INDEX[i].MESI_BITS == S) begin
					MessageToCache(INVALIDATELINE,address);
				cache[index].CACHE_INDEX[i].MESI_BITS = I;
                                        BusOperation(opcode,address,result);
			end
       end   
    endtask

    // Miss scenario tasks
    task automatic rd_req_from_l1_miss(input [13:0] index, input [11:0] tag);
       begin
    integer i;
    //bit [13:0]index=index_bits;

				if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
					//busOp = READ;
				    MessageToCache(SENDLINE,address);
					//get snoop result
					cache[index].CACHE_INDEX[i].MESI_BITS = S;
                                        BusOperation(opcode,address,result);					
				end
				else if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
					//busOp = READ;
				    MessageToCache(SENDLINE,address);
					//get snoop result
					cache[index].CACHE_INDEX[i].MESI_BITS = E;
                                        BusOperation(opcode,address,result);
				end
      end 
    endtask

    task automatic wr_req_from_l1_miss(input [13:0] index, input [11:0] tag);
       begin
    integer i;
   // bit [13:0]index=index_bits;

				if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
					//busOp =RWIM;
					MessageToCache(GETLINE,address);
					cache[index].CACHE_INDEX[i].MESI_BITS = M;
                                        BusOperation(opcode,address,result);
				end	
      end 
    endtask

    task automatic rd_req_instr_miss(input [13:0] index, input [11:0] tag);
    begin
    integer i;
    //bit [13:0]index=index_bits;
				if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
					//busOp = READ;
				    MessageToCache(SENDLINE,address);
					//get snoop result
					cache[index].CACHE_INDEX[i].MESI_BITS = S;
                                        BusOperation(opcode,address,result);					
				end
				else if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
					//busOp = READ;
				    MessageToCache(SENDLINE,address);
					//get snoop result
					cache[index].CACHE_INDEX[i].MESI_BITS = E;
                                        BusOperation(opcode,address,result);
				end
     end    
    endtask

    task automatic snoop_rd_req_miss(input [13:0] index, input [11:0] tag);
    begin
    integer i;
    //bit [13:0]index=index_bits;

				if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
                                        BusOperation(opcode,address,result);
				end
     end
    
    endtask

    task automatic snoop_wr_req_miss(input [13:0] index, input [11:0] tag);
       begin
    integer i;
    //bit [13:0]index=index_bits;

				if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
                                        BusOperation(opcode,address,result);
				end
        end
    endtask

    task automatic snoop_rd_rwim_miss(input [13:0] index, input [11:0] tag);
      begin
    integer i;
    //bit [13:0]index=index_bits;

				if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
                                        BusOperation(opcode,address,result);
				end
      end  
    endtask

    task automatic snoop_invalidate_miss(input [13:0] index, input [11:0] tag);
      begin
    integer i;
    //bit [13:0]index=index_bits;

				if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
                                        BusOperation(opcode,address,result);
				end
      end 
    endtask


function automatic bit [3:0] access_cache(ref bit[14:0]PLRU);
    int index=0; //PLRU index
    bit [3:0]access;
    for (int i = 3; i >=0; i--) begin
      if (PLRU[index] == 0) //access way is left
       begin
        PLRU[index] = 0;
        access[i]=0;
        index = (2 * index) + 1;        
       end 
      else ////access way is right
       begin
        PLRU[index] = 1; 
        access[i]=1;
        index = (2 * index) + 2;        
       end
    end
    return access;
  endfunction

function automatic bit [3:0] victim_cache(ref bit[14:0]PLRU);
    int index=0; //PLRU index
    bit [3:0]victim;
    for (int i = 3; i >=0; i--) begin
      if (PLRU[index] == 0) //when access way is left victim way is right so we update inverted values
       begin
        PLRU[index] = 1;
        victim[i]=1;
        index = 2 * index + 2;        
       end 
      else ////when access way is right victim way is left so we update inverted values
       begin
        PLRU[index] = 0; 
        victim[i]=0;
        index = 2 * index + 1;        
       end
    end
    return victim;
  endfunction

function automatic Snoopresult GetSnoopResult_funct(input bit [31:0] address);
    if (address[1:0] == 2'b00)
        return HIT;
    else if (address[1:0] == 2'b01)
        return HITM;
    else
        return NOHIT;
endfunction

function void BusOperation( input bit BusOp, input bit [31:0] Address,output Snoopresult SnoopResult);
    SnoopResult = GetSnoopResult_funct(Address);
    
    //if (NormalMode) begin
        $display("BusOp: %0d, Address: %0h, Snoop Result: %0d",BusOp, Address, SnoopResult);
    //end
endfunction

function void MessageToCache(bit Message, bit [31:0]Address);
//if (NormalMode)
$display("L2: %d %h\n", Message, Address);
endfunction
endmodule

