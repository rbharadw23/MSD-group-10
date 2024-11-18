import parameters_defn::*;
module cache (
    input  logic clk,
    input  logic reset,
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] write_data,
    input  logic read_en,
    input  logic write_en,
    output logic [DATA_WIDTH-1:0] read_data,
    output logic hit,
    output logic miss
);
    // Cache storage elements
    logic [TAG_BITS-1:0] tag_array[CACHE_LINES-1:0];
    logic [DATA_WIDTH-1:0] data_array[CACHE_LINES-1:0][LINE_SIZE/4-1:0];
    logic valid_array[CACHE_LINES-1:0];

    // Address breakdown
    logic [TAG_BITS-1:0] tag;
    logic [INDEX_BITS-1:0] index;
    logic [OFFSET_BITS-1:0] offset;

    assign tag = addr[ADDR_WIDTH-1:ADDR_WIDTH-TAG_BITS];
    assign index = addr[ADDR_WIDTH-TAG_BITS-1:OFFSET_BITS];
    assign offset = addr[OFFSET_BITS-1:0];

    // Cache read/write logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize the cache on reset
            for (int i = 0; i < CACHE_LINES; i++) begin
                valid_array[i] <= 0;
                tag_array[i] <= 0;
                for (int j = 0; j < LINE_SIZE/4; j++) begin
                    data_array[i][j] <= 0;
                end
            end
        end else begin
            // Cache hit check
            if (read_en || write_en) begin
                if (valid_array[index] && tag_array[index] == tag) begin
                    // Cache hit
                    hit <= 1;
                    miss <= 0;
                    if (read_en) begin
                        read_data <= data_array[index][offset >> 2];
                    end
                    if (write_en) begin
                        data_array[index][offset >> 2] <= write_data;
                    end
                end else begin
                    // Cache miss
                    hit <= 0;
                    miss <= 1;
                    if (write_en) begin
                        // Allocate new line on write miss
                        tag_array[index] <= tag;
                        valid_array[index] <= 1;
                        data_array[index][offset >> 2] <= write_data;
                    end
                end
            end
        end
    end

endmodule

