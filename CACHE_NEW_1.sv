`include "Packages.sv"  // Include the cache parameters package

module cache_simulator(input bit [31:0] address_ip,input bit [1:0] op_ip,output message,output busOp,output Snoopresult);
    // Use parameters from the cache_config_pkg package
    import cache_config_pkg::*; 

    cache_set_t cache [NUM_SETS-1:0];  // declaring array of 16,384 cache sets
    bit [31:0] address=address_ip;
    bit [1:0] opcode=op_ip;
     
    // Extract cache address parts
    task automatic get_cache_parts(
        input [31:0] address, 
        output [TAG_BITS-1:0] tag, 
        output [INDEX_BITS-1:0] index, 
        output [BLOCK_OFFSET_BITS-1:0] block_offset
    );
        block_offset = address[BLOCK_OFFSET_BITS-1:0];  // Least significant 6 bits
        index = address[BLOCK_OFFSET_BITS + INDEX_BITS-1:BLOCK_OFFSET_BITS];  // Next 14 bits
        tag = address[31:BLOCK_OFFSET_BITS + INDEX_BITS];  // Remaining bits
    endtask

    // Cache access task with integrated state handling
   /* task automatic cache_access(
        input [31:0] address, 
        input logic opcode
    );*/

      task automatic cache_access();
        logic [TAG_BITS-1:0] tag;
        logic [INDEX_BITS-1:0] index;
        logic [BLOCK_OFFSET_BITS-1:0] block_offset;
        logic hit;
        integer i;

        // Extract tag, index, and block offset
        get_cache_parts(address, tag, index, block_offset);

        // Check for hit in the set
        hit = 0; 

        foreach (cache[index].CACHE_INDEX[i]) begin
            if (cache[index].CACHE_INDEX[i].valid && (cache[index].CACHE_INDEX[i].tag == tag)) begin
                hit = 1;  // Cache hit
                break;
            end
        end

        if (hit) begin
            integer hit_count;
             hit_count=hit_count+1;
            $display("Total HIT count %0d",hit_count);
            
            // Handle hit scenarios based on opcode
            case(opcode)
                0: rd_req_from_l1_hit(index, tag);
                1: wr_req_from_l1_hit(index, tag);
                2: rd_req_instr_from_l1_hit(index, tag);
                3: snoop_rd_req_hit(index, tag);
                4: snoop_wr_req_hit(index, tag);
                5: snoop_rd_rwim_hit(index, tag);
                6: snoop_invalidate_hit(index, tag);
            endcase
        end 
        else begin
            integer miss_count;
               miss_count=miss_count+1;
            $display("Total MISS count %0d",miss_count);
            // Handle miss scenarios based on opcode
            case(opcode)
                0: rd_req_from_l1_miss(index, tag);
                1: wr_req_from_l1_miss(index, tag);
                2: rd_req_instr_miss(index, tag);
                3: snoop_rd_req_miss(index, tag);
                4: snoop_wr_req_miss(index, tag);
                5: snoop_rd_rwim_miss(index, tag);
                6: snoop_invalidate_miss(index, tag);
            endcase
        end
    endtask

    // Hit scenario tasks
    task automatic rd_req_from_l1_hit(input [13:0] index_bits, input [11:0] tag_bits);
    begin
    integer i;
    bit index=index_bits;
    bit [14:0] local_PLRU = cache[index].plru_tree; // Accessing PLRU from the cache set
    bit [3:0] selected_victim = victim_cache(local_PLRU);
    
				if (cache[index].CACHE_INDEX[i].MESI_BITS == S)begin
					message = SENDLINE;
				end
			    else if (cache[index].CACHE_INDEX[i].MESI_BITS == M)begin
					message = SENDLINE; 
				end
				else if (cache[index].CACHE_INDEX[i].MESI_BITS == E)begin
				    message = SENDLINE;
				end
       end    
    endtask

    task automatic wr_req_from_l1_hit(input [13:0] index_bits, input [11:0] tag_bits);
       begin
     integer i;
    bit index=index_bits;
                if (cache[index].CACHE_INDEX[i].MESI_BITS == S)begin
					busOp = INVALIDATE;
					message = GETLINE;
					cache[index].CACHE_INDEX[i].MESI_BITS = M;
				end
			    else if (cache[index].CACHE_INDEX[i].MESI_BITS == M)begin
				end
				else if (cache[index].CACHE_INDEX[i].MESI_BITS == E)begin
				    message = GETLINE;
					cache[index].CACHE_INDEX[i].MESI_BITS = M;
				end
        end 
     endtask

    task automatic rd_req_instr_from_l1_hit(input [13:0] index_bits, input [11:0] tag_bits);
       begin
    integer i;
    bit index=index_bits;
				if (cache[index].CACHE_INDEX[i].MESI_BITS == S)begin
					message = SENDLINE;
				end
			    else if (cache[index].CACHE_INDEX[i].MESI_BITS == M)begin
					message = SENDLINE; 
				end
				else if (cache[index].CACHE_INDEX[i].MESI_BITS == E)begin
				    message = SENDLINE;
				end
       end
    endtask

    task automatic snoop_rd_req_hit(input [13:0] index_bits, input [11:0] tag_bits);
      begin
    integer i;
    bit index=index_bits;
				if (cache[index].CACHE_INDEX[i].MESI_BITS == S) begin
					message = SENDLINE;
				end
				else if (cache[index].CACHE_INDEX[i].MESI_BITS == M)begin
					busOp = WRITE;
					message =GETLINE;
					cache[index].CACHE_INDEX[i].MESI_BITS = S;
				end
				else if (cache[index].CACHE_INDEX[i].MESI_BITS == E)begin
                                        message =SENDLINE;
                                        cache[index].CACHE_INDEX[i].MESI_BITS = S; 
				end
       end  
    endtask

    task automatic snoop_wr_req_hit(input [13:0] index_bits, input [11:0] tag_bits);//TA
      begin
    integer i;
    bit index=index_bits;
				if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
					message = SENDLINE;
				end			
      end  
    endtask

    task automatic snoop_rd_rwim_hit(input [13:0] index_bits, input [11:0] tag_bits);//busrdx
     begin
    integer i;
    bit index=index_bits;

				if (cache[index].CACHE_INDEX[i].MESI_BITS == S) begin
					message = INVALIDATELINE;
					cache[index].CACHE_INDEX[i].MESI_BITS = I;
				end
				else if (cache[index].CACHE_INDEX[i].MESI_BITS == M)begin
					busOp = WRITE;
					message =INVALIDATELINE;
					cache[index].CACHE_INDEX[i].MESI_BITS = I;
				end
				else if (cache[index].CACHE_INDEX[i].MESI_BITS == E)begin
					message = INVALIDATELINE;
                                end
      end  
    endtask

    task automatic snoop_invalidate_hit(input [13:0] index_bits, input [11:0] tag_bits);//busupgr
     begin
    integer i;
    bit index=index_bits;

            if (cache[index].CACHE_INDEX[i].MESI_BITS == S) begin
					message = INVALIDATELINE;
				cache[index].CACHE_INDEX[i].MESI_BITS = I;
			end
       end   
    endtask

    // Miss scenario tasks
    task automatic rd_req_from_l1_miss(input [13:0] index_bits, input [11:0] tag_bits);
       begin
    integer i;
    bit index=index_bits;

				if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
					busOp = READ;
				    message = SENDLINE;
					//get snoop result
					cache[index].CACHE_INDEX[i].MESI_BITS = S;					
				end
				else if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
					busOp = READ;
				    message = SENDLINE;
					//get snoop result
					cache[index].CACHE_INDEX[i].MESI_BITS = E;
				end
      end 
    endtask

    task automatic wr_req_from_l1_miss(input [13:0] index_bits, input [11:0] tag_bits);
       begin
    integer i;
    bit index=index_bits;

				if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
					busOp =RWIM;
					message = GETLINE;
					cache[index].CACHE_INDEX[i].MESI_BITS = M;
				end	
      end 
    endtask

    task automatic rd_req_instr_miss(input [13:0] index_bits, input [11:0] tag_bits);
    begin
    integer i;
    bit index=index_bits;
				if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
					busOp = READ;
				    message = SENDLINE;
					//get snoop result
					cache[index].CACHE_INDEX[i].MESI_BITS = S;					
				end
				else if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
					busOp = READ;
				    message = SENDLINE;
					//get snoop result
					cache[index].CACHE_INDEX[i].MESI_BITS = E;
				end
     end    
    endtask

    task automatic snoop_rd_req_miss(input [13:0] index_bits, input [11:0] tag_bits);
    begin
    integer i;
    bit index=index_bits;

				if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
				    Snoopresult = NOHIT;
				end
     end
    
    endtask

    task automatic snoop_wr_req_miss(input [13:0] index_bits, input [11:0] tag_bits);
       begin
    integer i;
    bit index=index_bits;

				if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
				end
        end
    endtask

    task automatic snoop_rd_rwim_miss(input [13:0] index_bits, input [11:0] tag_bits);
      begin
    integer i;
    bit index=index_bits;

				if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
				end
      end  
    endtask

    task automatic snoop_invalidate_miss(input [13:0] index_bits, input [11:0] tag_bits);
      begin
    integer i;
    bit index=index_bits;

				if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
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
        index = 2 * index + 1;        
       end 
      else ////access way is right
       begin
        PLRU[index] = 1; 
        access[i]=1;
        index = 2 * index + 2;        
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


endmodule
