`include "Packages.sv"  // Include the cache parameters package

module cache_simulator();
// Use parameters from the cache_config_pkg package
import cache_config_pkg::*; 

cache_set_t cache [NUM_SETS-1:0];  // declaring array of 16,384 cache sets
bit [31:0] address;
bit [1:0] opcode;

//rbharadw


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

case(opcode)

0:begin
task rd_req_from_l1(input [13:0]index_bits,input [11:0]tag_bits);
begin
				if (cache[index][i].MESI_BITS == S)begin
					message = SENDLINE;
				end
			    else if (cache[index][i].MESI_BITS == M)begin
					message = SENDLINE; 
				end
				else if (cache[index][i].MESI_BITS == E)begin
				    message = SENDLINE;
				end
end
endtask;
end

1:begin
task  wr_req_from_l1(input [13:0]index_bits,input [11:0]tag_bits);
begin
                if (cache[index][i].MESI_BITS == S)begin
					busOp = INVALIDATE;
					message = GETLINE;
					cache[index][i].MESI_BITS = M;
				end
			    else if (cache[index][i].MESI_BITS == M)begin
				end
				else if (cache[index][i].MESI_BITS == E)begin
				    message = GETLINE;
					cache[index][i].MESI_BITS = M;
				end
end
endtask
end

2:begin
task  rd_req_instr from_l1(input [13:0]index_bits,input [11:0]tag_bits);
begin
				if (cache[index][i].MESI_BITS == S)begin
					message = SENDLINE;
				end
			    else if (cache[index][i].MESI_BITS == M)begin
					message = SENDLINE; 
				end
				else if (cache[index][i].MESI_BITS == E)begin
				    message = SENDLINE;
				end
end
endtask;
end

3:begin
task  snoop_rd_req(input [13:0]index_bits,input [11:0]tag_bits);
begin
				if (cache[index][i].MESI_BITS == S) begin
					message = SENDLINE;
				end
				else if (cache[index][i].MESI_BITS == M)begin
					busOp = WRITE;
					message =GETLINE;
					cache[index][i].MESI_BITS = S;
				end
				else if (cache[index][i].MESI_BITS == E)begin
				end
end
endtask;
end

4:begin
task  snoop_wr_req(input [13:0]index_bits,input [11:0]tag_bits);
begin
				if (cache[index][i].MESI_BITS == I) begin
					message = SENDLINE;
				end			
end
endtask;
end

5:begin
task  snoop_rd_rwim(input [13:0]index_bits,input [11:0]tag_bits);
begin
				if (cache[index][i].MESI_BITS == S) begin
					message = INVALIDATELINE;
					cache[index][i].MESI_BITS = I;
				end
				else if (cache[index][i].MESI_BITS == M)begin
					busOp = WRITE;
					message =INVALIDATELINE;
					cache[index][i].MESI_BITS = I;
				end
				else if (cache[index][i].MESI_BITS == E)begin
					message = INVALIDATELINE;
                end
end
endtask;
end

6:begin
task  snoop_invalidate(input [13:0]index_bits,input [11:0]tag_bits);
begin
            if (cache[index][i].MESI_BITS == S) begin
					message = INVALIDATELINE;
				cache[index][i].MESI_BITS = I;
			end
end
endtask;
end

//7 and 8 for reset and prin_all to be implemented
endcase
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
	
case(opcode)

0:begin
task  rd_req_from_l1(input [13:0]index_bits,input [11:0]tag_bits);
begin
				if (cache[index][i].MESI_BITS == I) begin
					busOp = READ;
				    message = SENDLINE;
					//get snoop result
					cache[index][i].MESI_BITS = S;					
				end
				else if (cache[index][i].MESI_BITS == I) begin
					busOp = READ;
				    message = SENDLINE;
					//get snoop result
					cache[index][i].MESI_BITS = E;
				end
end
endtask
end

1:begin
task  wr_req_from_l1(input [13:0]index_bits,input [11:0]tag_bits);
begin
				if (cache[index][i].MESI_BITS == I) begin
					busOp =RWIM;
					message = GETLINE;
					cache[index][i].MESI_BITS = M;
				end	
end
endtask
end

2:begin
task  rd_req_instr(input [13:0]index_bits,input [11:0]tag_bits);
begin
				if (cache[index][i].MESI_BITS == I) begin
					busOp = READ;
				    message = SENDLINE;
					//get snoop result
					cache[index][i].MESI_BITS = S;					
				end
				else if (cache[index][i].MESI_BITS == I) begin
					busOp = READ;
				    message = SENDLINE;
					//get snoop result
					cache[index][i].MESI_BITS = E;
				end
end
endtask
end

3:begin
task  snoop_rd_req(input [13:0]index_bits,input [11:0]tag_bits);
begin
				if (cache[index][i].MESI_BITS == I) begin
				    Snoopresult = NOHIT;
				end
end
endtask
end

4:begin
task  snoop_wr_req(input [13:0]index_bits,input [11:0]tag_bits);
begin
				if (cache[index][i].MESI_BITS == I) begin
				end
end
endtask
end

5:begin
task  snoop_rd_rwim(input [13:0]index_bits,input [11:0]tag_bits);
begin
				if (cache[index][i].MESI_BITS == I) begin
				end
end
endtask
end

6:begin
task  snoop_invalidate(input [13:0]index_bits,input [11:0]tag_bits);
begin
				if (cache[index][i].MESI_BITS == I) begin
				end
end
endtask
end

endcase	
	
end
endtask
endmodule
