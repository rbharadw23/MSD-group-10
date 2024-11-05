//`define DEBUG
module trace_reader;

    // Default trace file if no file name is specified
    string default_file = "rwims.din";

    // Declare variables
    string input_file;
    integer file;
    string line;
    bit [31:0] field1;       // To hold the first number (as decimal)
    bit [31:0] field2;       // To hold the second field (as hex)
    integer status;

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
                status = $sscanf(line, "%d %h", field1, field2); //$sscanf returns the number of successful conversions.
`ifndef DEBUG

                if (status == 2) begin
                    // Successfully parsed the line
                    $display("Parsed: field1=%0d, field2=%h", field1, field2);

          
                end
`else
		$display("Error parsed line: %s", line);
 
                /*else begin
                    $display("Error parsing line: %s", line);
                end*/
  `endif
            
            end

        end

        // Close the file after reading
        $fclose(file);
        $display("Finished reading the file.");
    end

endmodule