//`define DEBUG
module trace_reader;

    // Default trace file if no file name is specified
    string default_file = "rwims.din";

    // Declare variables
    string input_file;
    integer file;
    string line;
    intger opCode, hitCount, missCount, readCount, writeCount;       // To hold the first number (as decimal)
    logic [31:0] address;       // To hold the second field (as hex)
    integer status;
    
    integer line;

    logic [TAG_BITS-1:0] tag;
    logic [INDEX_BITS-1:0] index;
    logic [BLOCK_OFFSET_BITS-1:0] block_offset;

    cache_set_t cache [NUM_SETS-1:0];

    // User input trace file name or use default if none provided
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

        // Read the file line by line
        while (!$feof(file)) begin //if not of end of file is true
            // Read one line from the file
            line = "";
              if ($fgets(line, file)) begin
                // Attempt to parse the line into fields
                // Assuming the first part is a decimal number and the second is a hex number
                status = $sscanf(line, "%d %h", opCode, address); //$sscanf returns the number of successful conversions.

                cache_function();
          
                end
        end


`ifdef DEBUG
		$display("Parsed: opCode=%0d, address=%h", opCode, address);
 //silent execution - will get info in debug mode 

  `endif
            
            end

                if (status == 2) begin
                    // Successfully parsed the line
                    $display("Sucessfully parsed");

        end

        // Close the file after reading
        $fclose(file);
        $display("Finished reading the file.");
    
    
    cache_function() begin
        if(HIT) begin
            case(opCode)
            0: begin

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

            1: begin 
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

                2: begin
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

                3:begin
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

                4:begin
                    if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
					MessageToCache(SENDLINE,address);
                                        BusOperation(opcode,address,result);
				end			
            end 

                5:begin
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

                5:begin
                     if (cache[index].CACHE_INDEX[i].MESI_BITS == S) begin
					MessageToCache(INVALIDATELINE,address);
				cache[index].CACHE_INDEX[i].MESI_BITS = I;
                                        BusOperation(opcode,address,result);
			    end
            end 

                6:begin
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
           endcase

           else
            case(opCode)
                0: begin
                    if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
					//busOp =RWIM;
					MessageToCache(GETLINE,address);
					cache[index].CACHE_INDEX[i].MESI_BITS = M;
                                        BusOperation(opcode,address,result);
				end
                end

                1:begin
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

                3:begin
                    if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
                                        BusOperation(opcode,address,result);
				end
                end 

                4:begin
                   if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
                                        BusOperation(opcode,address,result);
				end
                end 
                
                5:begin
                    if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
                                        BusOperation(opcode,address,result);
				end
                 end  

                 6:begin
                    
				if (cache[index].CACHE_INDEX[i].MESI_BITS == I) begin
                                        BusOperation(opcode,address,result);
				end
                end 
            endcase
    end
    end
endmodule