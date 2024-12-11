`include "Packages.sv"  // Include the cache parameters package
import cache_config_pkg::*;

module cache_simulator;
 
    string default_file = "./default.din";// Default trace file

    // trace file variables
    string input_file;
    integer file;
    string line;
    integer status;
     //Cache simulator variables
    cache_set_t cache [NUM_SETS-1:0];  // declaring array of 16,384 cache set
    integer opcode='b0;
    logic [31:0] address='b0;
    logic [TAG_BITS-1:0] tag;
    logic [INDEX_BITS-1:0] index='b0;
    logic [BLOCK_OFFSET_BITS-1:0] block_offset='b0;
    logic signed [4:0] block_line;
    integer read_count='b0;
    integer write_count='b0;
    real miss_count='b0;
    integer hit=0;
    real hit_count='b0;
    real hit_ratio='b0;
    Snoopresult result;
 
    initial begin
   
        if (!$value$plusargs("trace_file=%s", input_file)) begin  // No input file,use default 
            input_file = default_file;
        end
 
        file = $fopen(input_file, "r");
        if (file == 0) begin
            $display("Error: Could not open the trace file '%s'.", input_file);
            $finish;
        end 
        else begin
            $display("Successfully opened the trace file '%s'.", input_file);
        end
 
        while (!$feof(file)) begin // Read the file line by line 
            line = "";
            if ($fgets(line, file)) begin
                status = $sscanf(line, "%d %h", opcode, address); //$sscanf returns the number of successful conversions
                cache_function();
                `ifdef DEBUG
                $display("addr %h ,op %d",address,opcode);
                `endif
            end
        end

		if (status == 2) begin // Successfully parsed the line
            $display("Sucessfully parsed");
        end

		$display("Cache hit ratio = %0f",hit_ratio);
		$display("Number of cache reads= %0d",read_count);
		$display("Number of cache writes = %0d",write_count);
		$display("Number of cache hits %0f",hit_count);
		$display("Number of cache misss %0f",miss_count);

        $fclose(file);
        $display("Finished reading the file.");
    end


function void cache_function();
	hit=0;
	block_offset = address[BLOCK_OFFSET_BITS-1:0];  // Least significant 6 bits
	index = address[BLOCK_OFFSET_BITS + INDEX_BITS-1:BLOCK_OFFSET_BITS];  //index 14 bits
	tag = address[31:BLOCK_OFFSET_BITS + INDEX_BITS];  //tag 12 bits


	foreach (cache[index].CACHE_INDEX[i]) begin
		if (cache[index].CACHE_INDEX[i].MESI_BITS != I) begin
			if(cache[index].CACHE_INDEX[i].tag == tag) begin
				hit = 1; 
				block_line = i;
				break;
			end
		end
	end

	if (opcode == 9) begin
			foreach (cache[index].CACHE_INDEX[i]) begin
			if (cache[index].CACHE_INDEX[i].MESI_BITS != I) begin
			
			$display("index=0x%h , line=0x%h ,tag=0x%h, block_offset=0x%h, MESI=%s PLRU=0x%b",index,i,cache[index].CACHE_INDEX[i].tag,block_offset,cache[index].CACHE_INDEX[i].MESI_BITS.name(),cache[index].PLRU);
			
			end
else begin
i=block_line;
$display("index=0x%h , line=0x%h ,tag=0x%h, block_offset=0x%h, MESI=%s PLRU=0x%b",index,i,cache[index].CACHE_INDEX[i].tag,block_offset,cache[index].CACHE_INDEX[i].MESI_BITS.name(),cache[index].PLRU);
end
		end
		end else if (opcode ==  8) begin
			reset();
		end else
	if (hit) begin 

	case(opcode)


	0://rd req from l1 hit
	begin
			hit_count=hit_count+1;

				if (cache[index].CACHE_INDEX[block_line].MESI_BITS == S)
                                begin

					MessageToCache(SENDLINE);
                                        updatePLRU(block_line);
                `ifdef NORMAL
                $display("Tag and state are as follows tag:%0h , updated_mesi_state:Shared",cache[index].CACHE_INDEX[block_line].tag); 
                `endif
 
                                         
				end
			    else if (cache[index].CACHE_INDEX[block_line].MESI_BITS == M)
                               begin
					MessageToCache(SENDLINE);
                                        updatePLRU(block_line);
                `ifdef NORMAL
                $display("Tag and state are as follows tag:%0h , updated_mesi_state:Modified",cache[index].CACHE_INDEX[block_line].tag); 
                `endif
                                                                    
				end
			    else if (cache[index].CACHE_INDEX[block_line].MESI_BITS == E)
                                begin
				    MessageToCache(SENDLINE);
                                     updatePLRU(block_line);
                `ifdef NORMAL
                $display("Tag and state are as follows tag:%0h , updated_mesi_state:Exclusive",cache[index].CACHE_INDEX[block_line].tag); 
                `endif
                                    
				end
                                        read_count = read_count+1;
	end

	1://wr req from l1 hit       
	begin
	hit_count=hit_count+1;
                if (cache[index].CACHE_INDEX[block_line].MESI_BITS == S)
                               begin
					
					MessageToCache(GETLINE);
					cache[index].CACHE_INDEX[block_line].MESI_BITS = M;
                                        updatePLRU(block_line);
                                        `ifdef NORMAL
                                           $display("Tag and state are as follows tag:%0h , updated_mesi_state:Modified",cache[index].CACHE_INDEX[block_line].tag); 
                                           `endif
                                        BusOperation(INVALIDATE);
				end
			    else if (cache[index].CACHE_INDEX[block_line].MESI_BITS == M)
                                begin
                                        updatePLRU(block_line);
                                        `ifdef NORMAL
                                           $display("Tag and state are as follows tag:%0h , updated_mesi_state:Modified",cache[index].CACHE_INDEX[block_line].tag); 
                                           `endif
				end

				else if (cache[index].CACHE_INDEX[block_line].MESI_BITS == E)
                                begin
				    MessageToCache(GETLINE);
					cache[index].CACHE_INDEX[block_line].MESI_BITS = M;
                                        updatePLRU(block_line);
                                        `ifdef NORMAL
                                           $display("Tag and state are as follows tag:%0h , updated_mesi_state:Modified",cache[index].CACHE_INDEX[block_line].tag); 
                                           `endif

                                        
				end
                                      write_count = write_count+1;
	end 

	2://rd req instr from l1 hit
	begin
	hit_count=hit_count+1;
				if (cache[index].CACHE_INDEX[block_line].MESI_BITS == S)
                                begin
					MessageToCache(SENDLINE); 
                                        updatePLRU(block_line);
                                        `ifdef NORMAL
                                           $display("Tag and state are as follows tag:%0h , updated_mesi_state:Shared",cache[index].CACHE_INDEX[block_line].tag); 
                                           `endif

				end
			    else if (cache[index].CACHE_INDEX[block_line].MESI_BITS == M)
                                begin
					MessageToCache(SENDLINE);
                                        updatePLRU(block_line); 
                                        `ifdef NORMAL
                                           $display("Tag and state are as follows tag:%0h , updated_mesi_state:Modified",cache[index].CACHE_INDEX[block_line].tag); 
                                           `endif

                                        
				end
				else if (cache[index].CACHE_INDEX[block_line].MESI_BITS == E)
                                begin
				    MessageToCache(SENDLINE);
                                        updatePLRU(block_line);
                                        `ifdef NORMAL
                                           $display("Tag and state are as follows tag:%0h , updated_mesi_state:Exclusive",cache[index].CACHE_INDEX[block_line].tag); 
                                           `endif

                                    
				end
                                        read_count = read_count+1;
	end

	3://snoop rd req hit
	begin
				if (cache[index].CACHE_INDEX[block_line].MESI_BITS == S)
                                begin
					 
                                 result=HIT; //put snoop
                                `ifdef NORMAL
                                   $display("SnoopResult: Address %h, SnoopResult: %s", address,result ); 
                                   $display("Tag and state are as follows tag:%0h , updated_mesi_state:Shared",cache[index].CACHE_INDEX[block_line].tag);

                                 `endif				
                                 end

				else if (cache[index].CACHE_INDEX[block_line].MESI_BITS == M)
                                 begin
					
					MessageToCache(GETLINE);
					cache[index].CACHE_INDEX[block_line].MESI_BITS = S; 
                                        BusOperation(WRITE);
                                        result=HITM; //put snoop
                                `ifdef NORMAL
                                   $display("SnoopResult: Address %h, SnoopResult: %s", address,result );
                                   $display("Tag and state are as follows tag:%0h , updated_mesi_state:Shared",cache[index].CACHE_INDEX[block_line].tag);

                                 `endif
				end
				else if (cache[index].CACHE_INDEX[block_line].MESI_BITS == E)
                                begin
                                        
                                        cache[index].CACHE_INDEX[block_line].MESI_BITS = S;
                                        result=HIT; //put snoop
                                `ifdef NORMAL
                                   $display("SnoopResult: Address %h, SnoopResult: %s", address,result );
                                   $display("Tag and state are as follows tag:%0h , updated_mesi_state:Shared",cache[index].CACHE_INDEX[block_line].tag);

                                 `endif
                                        
				end
	end


	5://snoop rd rwim hit
	begin
				if (cache[index].CACHE_INDEX[block_line].MESI_BITS == S)
			        begin
					
					cache[index].CACHE_INDEX[block_line].MESI_BITS = I;
                                   MessageToCache(INVALIDATELINE);
                                   result=HIT; //put snoop

                                `ifdef NORMAL
                                   $display("SnoopResult: Address %h, SnoopResult: %s", address,result);
                                   $display("Tag and state are as follows tag:%0h , updated_mesi_state:Invalid",cache[index].CACHE_INDEX[block_line].tag);

                                 `endif     
                                 
				end

				else if (cache[index].CACHE_INDEX[block_line].MESI_BITS == M)
 				begin
					
					MessageToCache(GETLINE);	
					cache[index].CACHE_INDEX[block_line].MESI_BITS = I; 
                                        BusOperation(WRITE);
                                        MessageToCache(INVALIDATELINE);
                                        result=HITM; //put snoop

                                `ifdef NORMAL
                                   $display("SnoopResult: Address %h, SnoopResult: %s", address,result );
                                   $display("Tag and state are as follows tag:%0h , updated_mesi_state:Invalid",cache[index].CACHE_INDEX[block_line].tag);

                                 `endif
				end

				else if (cache[index].CACHE_INDEX[block_line].MESI_BITS == E)
                                begin

                                        cache[index].CACHE_INDEX[block_line].MESI_BITS = I;
                                   MessageToCache(INVALIDATELINE);
                                   result=HIT; //put snoop

                                `ifdef NORMAL
                                   $display("SnoopResult: Address %h, SnoopResult: %s", address,result );
                                   $display("Tag and state are as follows tag:%0h , updated_mesi_state:Invalid",cache[index].CACHE_INDEX[block_line].tag);
                                 `endif
                                end
	end 

	6://snoop invalidate hit
	begin
            if (cache[index].CACHE_INDEX[block_line].MESI_BITS == S) 
                                begin
					MessageToCache(INVALIDATELINE);
				        cache[index].CACHE_INDEX[block_line].MESI_BITS = I;
                                   result=HIT; //put snoop
                                `ifdef NORMAL
                                   $display("SnoopResult: Address %h, SnoopResult: %s", address,result );
                                   $display("Tag and state are as follows tag:%0h , updated_mesi_state:Invalid",cache[index].CACHE_INDEX[block_line].tag);
                                 `endif
		               	end
	end

	endcase
	end

	else 
	begin
		block_line = -1;
		
		foreach (cache[index].CACHE_INDEX[i]) 
			begin

			if (cache[index].CACHE_INDEX[i].MESI_BITS == I) 
			begin

			 block_line=i;
			 break;

			end
		end



		case(opcode)
		0://rd req from l1 miss
		begin
		miss_count=miss_count+1;
			GetSnoopResult_funct();

			if(result==NOHIT) begin
					if (block_line == -1) begin
						MessageToCache(EVICTLINE);
						block_line=victim_way();
					end
				    MessageToCache(SENDLINE);	
				    cache[index].CACHE_INDEX[block_line].MESI_BITS = E;
					cache[index].CACHE_INDEX[block_line].tag=tag;
                    updatePLRU(block_line);
                        `ifdef NORMAL
                            $display("Tag and state are as follows tag:%0h , updated_mesi_state:Exclusive",cache[index].CACHE_INDEX[block_line].tag); 
                        `endif

                    BusOperation(READ);
                    read_count = read_count+1; 
            end


			else begin
					if (block_line == -1) begin
						MessageToCache(EVICTLINE);
						block_line=victim_way();
					end
					MessageToCache(SENDLINE);
			        cache[index].CACHE_INDEX[block_line].MESI_BITS = S;
					cache[index].CACHE_INDEX[block_line].tag=tag;
                    updatePLRU(block_line);
                        `ifdef NORMAL
                            $display("Tag and state are as follows tag:%0h , updated_mesi_state:Shared",cache[index].CACHE_INDEX[block_line].tag); 
                        `endif
                    BusOperation(READ);
                    read_count = read_count+1; 
					
			end
		end

		1://wr req from l1 miss
		begin
		miss_count=miss_count+1;
				
					if (block_line == -1) begin
						MessageToCache(EVICTLINE);
						block_line=victim_way();
					end
					MessageToCache(SENDLINE);
					cache[index].CACHE_INDEX[block_line].MESI_BITS = M;
					cache[index].CACHE_INDEX[block_line].tag=tag;
                    updatePLRU(block_line);
                    `ifdef NORMAL
                          $display("Tag and state are as follows tag:%0h , updated_mesi_state:Modified",cache[index].CACHE_INDEX[block_line].tag); 
                    `endif
                    BusOperation(RWIM);
                    write_count = write_count+1;
                                        
			
		end 

		2://rd req instr miss
		begin
		miss_count=miss_count+1;
		GetSnoopResult_funct();

		if(result==NOHIT) begin
		if (block_line == -1) begin
						MessageToCache(EVICTLINE);
						block_line=victim_way();
					end
				    MessageToCache(SENDLINE);	
				    cache[index].CACHE_INDEX[block_line].MESI_BITS = E;
					cache[index].CACHE_INDEX[block_line].tag=tag;
                                    updatePLRU(block_line);
                                        `ifdef NORMAL
                                           $display("Tag and state are as follows tag:%0h , updated_mesi_state:Exclusive",cache[index].CACHE_INDEX[block_line].tag); 
                                           `endif

                                    BusOperation(READ);
                                    read_count = read_count+1; 
        end


		else begin
		if (block_line == -1) begin
						MessageToCache(EVICTLINE);
						block_line=victim_way();
					end
					MessageToCache(SENDLINE);
			                cache[index].CACHE_INDEX[block_line].MESI_BITS = S;
							cache[index].CACHE_INDEX[block_line].tag=tag;
                                        updatePLRU(block_line);
                                        `ifdef NORMAL
                                           $display("Tag and state are as follows tag:%0h , updated_mesi_state:Shared",cache[index].CACHE_INDEX[block_line].tag); 
                                           `endif

                                        BusOperation(READ);
                                        read_count = read_count+1;				

		end

		end

		3://snoop rd req miss
		begin
                                   result=NOHIT; //put snoop
                                `ifdef NORMAL
                                   $display("SnoopResult: Address %h, SnoopResult: %s", address,result );
                                   $display("Tag and state are as follows tag:%0h , updated_mesi_state:Invalid",cache[index].CACHE_INDEX[block_line].tag);
                                 `endif	
		end

		4://snoop wr req miss
		begin
                                   result=NOHIT; //put snoop
                                `ifdef NORMAL
                                   $display("SnoopResult: Address %h, SnoopResult: %s", address,result );
                                   $display("Tag and state are as follows tag:%0h , updated_mesi_state:Invalid",cache[index].CACHE_INDEX[block_line].tag);

                                 `endif
		end

		5://snoop rd rwim miss
		begin
                                   result=NOHIT; //put snoop
                                `ifdef NORMAL
                                   $display("SnoopResult: Address %h, SnoopResult: %s", address,result );
                                   $display("Tag and state are as follows tag:%0h , updated_mesi_state:Invalid",cache[index].CACHE_INDEX[block_line].tag);

                                 `endif
		end  
		6://snoop rd rwim miss
		begin
                                   result=NOHIT; //put snoop
                                `ifdef NORMAL
                                   $display("SnoopResult: Address %h, SnoopResult: %s", address,result );
                                   $display("Tag and state are as follows tag:%0h , updated_mesi_state:Invalid",cache[index].CACHE_INDEX[block_line].tag);

                                 `endif
		end  

		endcase
	end

	hit_ratio= hit_count/(hit_count+miss_count);

endfunction

function automatic void updatePLRU(logic signed [4:0] j);
int plru_index = 0;

bit [3:0] BL = j;
BL [0] = block_line[3];
BL [1] = block_line[2];
BL [2] = block_line[1];
BL [3] = block_line[0];

    for (int i = 3; i >=0; i--) begin
    if (BL[i]== 1'b0)begin
    cache[index].PLRU[plru_index]=BL[i];
    plru_index = (2 * plru_index) + 1;
    end
    
    else begin
    cache[index].PLRU[plru_index]=BL[i];
    plru_index=(2*plru_index)+2;  
    end
end
endfunction

function logic signed [4:0] victim_way();
    int plru_index;
    bit [3:0]victim;
	plru_index = 0;

    for (int i = 3; i >=0; i--) begin
      if (cache[index].PLRU[plru_index] == 0) //when access way is left victim way is right so we update inverted values
       begin
        //cache[index].PLRU[plru_index] = 1;
        victim[i]=1;
        plru_index = 2 * plru_index + 2;        
       end 
      else ////when access way is right victim way is left so we update inverted values
       begin
        //cache[index].PLRU[plru_index] = 0; 
        victim[i]=0;
        plru_index = (2 * plru_index) + 1;        
       end
    end
    return victim;
  endfunction

function void GetSnoopResult_funct();
    if (address[1:0] == 2'b00)
        result = HIT;
    else if (address[1:0] == 2'b01)
        result = HITM;
    else
        result = NOHIT;
endfunction

function void BusOperation(busOp BusOP);
`ifdef NORMAL
 $display("BusOp: %0s, Address: %0h, Snoop Result: %0s",BusOP,address,result);

 
`endif
endfunction

function void MessageToCache(message Message);
`ifdef NORMAL
$display("L2: %s %h\n", Message, address);


`endif
endfunction

function void reset();

read_count='b0;
write_count='b0;
miss_count='b0;
hit=0;
hit_count='b0;


    
        for (int j=0;j<NUM_SETS;j++) begin
        for(int i=0;i<16;i++)begin
            cache[j].CACHE_INDEX[i].tag=0;
            cache[j].CACHE_INDEX[i].MESI_BITS=I;
            cache[j].PLRU=0;
        end
        end
  
endfunction

endmodule
