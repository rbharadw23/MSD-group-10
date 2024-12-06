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
    logic [1:0] opcode;
    logic [31:0] address;
    logic [TAG_BITS-1:0] tag;
    logic [INDEX_BITS-1:0] index;
    logic [BLOCK_OFFSET_BITS-1:0] block_offset;
    bit [3:0] way_map;
    integer block_line;
    integer read_count;
    integer write_count;
    integer miss_count;
    integer hit;
    integer hit_count;
    integer hit_ratio; 
 
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
                end
            end

                if (status == 2) begin // Successfully parsed the line
                    $display("Sucessfully parsed");
                end

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
block_line=i;
         if (cache[index].CACHE_INDEX[i].MESI_BITS != I && (cache[index].CACHE_INDEX[i].tag == tag)) begin
                hit = 1;  // Cache hit 
                break;
        end
end


if (hit) begin 
             hit_count=hit_count+1;

//add mesi hit conditions
end

else begin
         miss_count=miss_count+1;

//add mesi miss conditions
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

function automatic void updatePLRU(ref bit[14:0]PLRU,[3:0]way_map);

    int index=0; //PLRU index
    for (int i = 3; i >=0; i--) begin
    if (way_map[i]==0)begin
    PLRU[index]=way_map[i];
    index = (2 * index) + 1;
    end
    
    else begin
    PLRU[index]=way_map[i];
    index=(2*index)+2;   
end
end
endfunction

function automatic bit [3:0] victim_way(ref bit[14:0]PLRU);
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

