`include "Packages.sv"  // Include the cache parameters package
import cache_config_pkg::*;

module cache_simulator;
 
    string default_file = "rwims.din";// Default trace file

    // trace file variables
    string input_file;
    integer file;
    string line;
    integer status;

     //Cache simulator variables
    cache_set_t cache [NUM_SETS-1:0];  // declaring array of 16,384 cache set
    integer opcode='b0;
    logic [31:0] address='b0;
    logic [TAG_BITS-1:0] tag='b0;
    logic [INDEX_BITS-1:0] index='b0;
    logic [BLOCK_OFFSET_BITS-1:0] block_offset='b0;
    bit [3:0] way_map[15:0];
    bit [3:0] block_line;
    integer read_count='b0;
    integer write_count='b0;
    integer miss_count='b0;
    integer hit='b0;
    integer hit_count='b0;
    integer hit_ratio='b0;
    int plru_index=0; //PLRU index
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
                //$display("addr %h ,op %d",address,opcode);
                end
            end

                if (status == 2) begin // Successfully parsed the line
                    $display("Sucessfully parsed");
                end

hit_ratio=hit_count/(hit_count+miss_count);
$display("Cache hit ratio = %0d",hit_ratio);
$display("Number of cache reads= %0d",read_count);
$display("Number of cache writes = %0d",write_count);
$display("Number of cache hits %0d",hit_count);
$display("Number of cache misss %0d",miss_count);

        $fclose(file);
        $display("Finished reading the file.");
    end


function void cache_function();
begin

block_offset = address[BLOCK_OFFSET_BITS-1:0];  // Least significant 6 bits
index = address[BLOCK_OFFSET_BITS + INDEX_BITS-1:BLOCK_OFFSET_BITS];  //index 14 bits
tag = address[31:BLOCK_OFFSET_BITS + INDEX_BITS];  //tag 12 bits

hit = 0; 

foreach (cache[index].CACHE_INDEX[i]) begin
         if (cache[index].CACHE_INDEX[i].MESI_BITS != I && (cache[index].CACHE_INDEX[i].tag == tag)) begin
                hit = 1;  // Cache hit 
                block_line=i;
                break;
        end
end


if (hit) begin 
             hit_count=hit_count+1;


//add mesi hit conditions

case(opcode)

8://reset
begin
reset();
end

0://rd req from l1 hit
begin


				if (cache[index].CACHE_INDEX[block_line].MESI_BITS == S)begin
					MessageToCache(SENDLINE);
                                        updatePLRU(); 
                                         
				end
			    else if (cache[index].CACHE_INDEX[block_line].MESI_BITS == M)begin
					MessageToCache(SENDLINE);
                                        updatePLRU();
                                                                    
				end
				else if (cache[index].CACHE_INDEX[block_line].MESI_BITS == E)begin
				    MessageToCache(SENDLINE);
                                     updatePLRU();
                                    
				end
                                        read_count = read_count+1;
end

1://wr req from l1 hit       
begin
                if (cache[index].CACHE_INDEX[block_line].MESI_BITS == S)begin
					
					MessageToCache(GETLINE);
					cache[index].CACHE_INDEX[block_line].MESI_BITS = M;
                                        updatePLRU();
                                        BusOperation(INVALIDATE);
				end
			    else if (cache[index].CACHE_INDEX[block_line].MESI_BITS == M)begin
                                        updatePLRU(); 
				end

				else if (cache[index].CACHE_INDEX[block_line].MESI_BITS == E)begin
				    MessageToCache(GETLINE);
					cache[index].CACHE_INDEX[block_line].MESI_BITS = M;
                                        updatePLRU();
                                        
				end
                                      write_count = write_count+1;
end 

2://rd req instr from l1 hit
begin
				if (cache[index].CACHE_INDEX[block_line].MESI_BITS == S)begin
					MessageToCache(SENDLINE); 
                                        updatePLRU();
				end
			    else if (cache[index].CACHE_INDEX[block_line].MESI_BITS == M)begin
					MessageToCache(SENDLINE);
                                        updatePLRU(); 
                                        
				end
				else if (cache[index].CACHE_INDEX[block_line].MESI_BITS == E)begin
				    MessageToCache(SENDLINE);
                                        updatePLRU();
                                    
				end
                                        read_count = read_count+1;
end

3://snoop rd req hit
begin
				if (cache[index].CACHE_INDEX[block_line].MESI_BITS == S) begin
					 
                                        result=HIT; //put snoop
                                   $display("SnoopResult: Address %h, SnoopResult: %d\n?", address,result ); 
				end

				else if (cache[index].CACHE_INDEX[block_line].MESI_BITS == M)begin
					
					MessageToCache(GETLINE);
					cache[index].CACHE_INDEX[block_line].MESI_BITS = S; 
                                        BusOperation(WRITE);
                                    result=HITM; //put snoop
                                   $display("SnoopResult: Address %h, SnoopResult: %d\n?", address,result );
				end
				else if (cache[index].CACHE_INDEX[block_line].MESI_BITS == E)begin
                                        
                                        cache[index].CACHE_INDEX[block_line].MESI_BITS = S;
                                        result=HIT; //put snoop
                                   $display("SnoopResult: Address %h, SnoopResult: %d\n?", address,result );
                                        
				end
end


5://snoop rd rwim hit
begin
				if (cache[index].CACHE_INDEX[block_line].MESI_BITS == S) begin
					
					cache[index].CACHE_INDEX[block_line].MESI_BITS = I;
                                   result=HIT; //put snoop
                                   $display("SnoopResult: Address %h, SnoopResult: %d\n?", address,result );
                                       
				end
				else if (cache[index].CACHE_INDEX[block_line].MESI_BITS == M)begin
					
					MessageToCache(GETLINE);	
					cache[index].CACHE_INDEX[block_line].MESI_BITS = I; 
                                        BusOperation(WRITE);
                                        MessageToCache(INVALIDATELINE);
                                   result=HITM; //put snoop
                                   $display("SnoopResult: Address %h, SnoopResult: %d\n?", address,result );
				end

				else if (cache[index].CACHE_INDEX[block_line].MESI_BITS == E)begin

                                        cache[index].CACHE_INDEX[block_line].MESI_BITS = I;
                                   result=HIT; //put snoop
                                   $display("SnoopResult: Address %h, SnoopResult: %d\n?", address,result );
                                end
end 

6://snoop invalidate hit
begin
            if (cache[index].CACHE_INDEX[block_line].MESI_BITS == S) begin
					MessageToCache(INVALIDATELINE);
				        cache[index].CACHE_INDEX[block_line].MESI_BITS = I;
                                   result=HIT; //put snoop
                                   $display("SnoopResult: Address %h, SnoopResult: %d\n?", address,result );
			end
end
endcase
end

else begin
         miss_count=miss_count+1;

foreach (cache[index].CACHE_INDEX[i]) begin
         if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
         block_line=way_map[i];
         cache[index].CACHE_INDEX[block_line].tag=tag;
         end
        else begin
        block_line=victim_way();
        cache[index].CACHE_INDEX[block_line].tag=tag;
        end
end



case(opcode)
0://rd req from l1 miss
begin
GetSnoopResult_funct();

if(result==NOHIT) begin
				    MessageToCache(SENDLINE);	
				    cache[index].CACHE_INDEX[block_line].MESI_BITS = E;
                                    updatePLRU();
                                    BusOperation(READ);
                                    read_count = read_count+1; 
             end


else begin
					MessageToCache(SENDLINE);
			                cache[index].CACHE_INDEX[block_line].MESI_BITS = S;
                                        updatePLRU();
                                        BusOperation(READ);
                                        read_count = read_count+1; 					

             end
end

1://wr req from l1 miss
begin
				
					//busOp =RWIM;
					MessageToCache(SENDLINE);
					cache[index].CACHE_INDEX[block_line].MESI_BITS = M;
                                        updatePLRU();
                                        BusOperation(RWIM);
                                        write_count = write_count+1;
                                        
			
end 

2://rd req instr miss
begin
GetSnoopResult_funct();

if(result==NOHIT) begin
				    MessageToCache(SENDLINE);	
				    cache[index].CACHE_INDEX[block_line].MESI_BITS = E;
                                    updatePLRU();
                                    BusOperation(READ);
                                    read_count = read_count+1; 
             end


else begin
					MessageToCache(SENDLINE);
			                cache[index].CACHE_INDEX[block_line].MESI_BITS = S;
                                        updatePLRU();
                                        BusOperation(READ);
                                        read_count = read_count+1; 					

             end

end

3://snoop rd req miss
begin
                                   result=NOHIT; //put snoop
                                   $display("SnoopResult: Address %h, SnoopResult: %d\n?", address,result );	
end

4://snoop wr req miss
begin
                                   result=NOHIT; //put snoop
                                   $display("SnoopResult: Address %h, SnoopResult: %d\n?", address,result );;
end

5://snoop rd rwim miss
begin
                                   result=NOHIT; //put snoop
                                   $display("SnoopResult: Address %h, SnoopResult: %d\n?", address,result );
end  


/*6://snoop invalidate miss
begin
					MessageToCache(SENDLINE);
                                        //updatePLRU();
                                        BusOperation(READ);
end  only comes in shared state */

endcase
end


end
endfunction

initial
begin

way_map[0]=4'b0000;
way_map[1]=4'b0001;
way_map[2]=4'b0010;
way_map[3]=4'b0011;
way_map[4]=4'b0100;
way_map[5]=4'b0101;
way_map[6]=4'b0110;
way_map[7]=4'b0111;
way_map[8]=4'b1000;
way_map[9]=4'b1001;
way_map[10]=4'b1010;
way_map[11]=4'b1011;
way_map[12]=4'b1100;
way_map[13]=4'b1101;
way_map[14]=4'b1110;
way_map[15]=4'b1111;

end

function void updatePLRU();
//function automatic void updatePLRU(ref bit[14:0]PLRU,[3:0]find_way);

    for (int i = 3; i >=0; i--) begin
    if (block_line[i]==0)begin
    cache[index].PLRU[plru_index]=block_line[i];
    plru_index = (2 * plru_index) + 1;
    end
    
    else begin
    cache[index].PLRU[plru_index]=block_line[i];
    plru_index=(2*plru_index)+2;  
end
end
endfunction

function bit [3:0] victim_way();
//function automatic bit [3:0] victim_way(ref bit[14:0]PLRU);
    
    bit [3:0]victim;
    for (int i = 3; i >=0; i--) begin
      if (cache[index].PLRU[plru_index] == 0) //when access way is left victim way is right so we update inverted values
       begin
        cache[index].PLRU[plru_index] = 1;
        victim[i]=1;
        plru_index = 2 * plru_index + 2;        
       end 
      else ////when access way is right victim way is left so we update inverted values
       begin
        cache[index].PLRU[plru_index] = 0; 
        victim[i]=0;
        plru_index = (2 * plru_index) + 1;        
       end
    end
    return victim;
  endfunction

function Snoopresult GetSnoopResult_funct();
    if (address[1:0] == 2'b00)
        result = HIT;
    else if (address[1:0] == 2'b01)
        result = HITM;
    else
        result = NOHIT;
endfunction

function void BusOperation(busOp BusOP);
`ifdef NORMAL
 $display("BusOp: %0d, Address: %0h, Snoop Result: %0d",BusOP,address,result); 
`endif
endfunction

function void MessageToCache(message Message);
`ifdef NORMAL
$display("L2: %d %h\n", Message, Address);
`endif
endfunction

function void reset();
opcode='b0;
address='b0;
tag='b0;
index='b0;
block_offset='b0;
read_count='b0;
write_count='b0;
miss_count='b0;
hit='b0;
hit_count='b0;
hit_ratio='b0;

    
        foreach (cache[index].CACHE_INDEX[i]) begin
            cache[index].CACHE_INDEX[i].tag='b0;
            cache[index].CACHE_INDEX[i].MESI_BITS='b0;
            cache[index].PLRU='b0;
        end
  
endfunction

endmodule
