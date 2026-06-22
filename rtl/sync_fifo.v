module sync_fifo #(
    parameter DEPTH = 16,
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst_n,       // active low reset
    input  wire             wr_en,
    input  wire             rd_en,
    input  wire [WIDTH-1:0] din,
    output reg  [WIDTH-1:0] dout,
    output wire             full,
    output wire             empty,
    output wire             almost_full,  // 1 slot left
    output wire             almost_empty, // 1 slot remaining
    output reg  [$clog2(DEPTH):0] count  // number of valid entries
);

    // Memory array
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // Pointers
    reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;

    // Flag logic
    assign full         = (count == DEPTH);
    assign empty        = (count == 0);
    assign almost_full  = (count == DEPTH - 1);
    assign almost_empty = (count == 1);

    // Write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
            dout   <= 0;
        end else if (rd_en && !empty) begin
            dout   <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Count logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
        end else begin
            case ({wr_en & !full, rd_en & !empty})
                2'b10: count <= count + 1; // write only
                2'b01: count <= count - 1; // read only
                2'b11: count <= count;     // simultaneous RW
                default: count <= count;
            endcase
        end
    end

endmodule
