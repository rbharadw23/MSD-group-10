module trace_reader;

    // Default trace file if no file name is specified
    string default_file = "rwims.din";

    string input_file;
    integer file;
    string line;
   
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
        end else begin
            $display("Successfully opened the trace file '%s'.", input_file);
        end

        // Read the file line by line
        while (!$feof(file)) begin
            // Read one line from the file
            line = "";
            if ($fgets(line, file)) begin
                // Parse or process the line (example: display the line)
                $display("Read line: %s", line);
            end
        end
       
        // Close the file after reading
        $fclose(file);
        $display("Finished reading the file.");
    end

endmodule
