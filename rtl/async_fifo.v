module async_fifo #(
    parameter DEPTH = 16,
    parameter WIDTH = 8
)(
    input  wire             wr_clk,
    input  wire             rd_clk,
    input  wire             wr_rst_n,
    input  wire             rd_rst_n,
    input  wire             wr_en,
    input  wire             rd_en,
    input  wire [WIDTH-1:0] din,
    output reg  [WIDTH-1:0] dout,
    output wire             full,
    output wire             empty
);
    localparam PTR_W = $clog2(DEPTH) + 1;
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_W-1:0] wr_ptr_bin, wr_ptr_gray;
    reg [PTR_W-1:0] rd_ptr_bin, rd_ptr_gray;
    reg [PTR_W-1:0] wr_ptr_gray_s1, wr_ptr_gray_s2;
    reg [PTR_W-1:0] rd_ptr_gray_s1, rd_ptr_gray_s2;
    function [PTR_W-1:0] bin2gray;
        input [PTR_W-1:0] bin;
        bin2gray = bin ^ (bin >> 1);
    endfunction
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_ptr_bin  <= 0;
            wr_ptr_gray <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr_bin[PTR_W-2:0]] <= din;
            wr_ptr_bin  <= wr_ptr_bin + 1;
            wr_ptr_gray <= bin2gray(wr_ptr_bin + 1);
        end
    end
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_ptr_bin  <= 0;
            rd_ptr_gray <= 0;
            dout        <= 0;
        end else if (rd_en && !empty) begin
            dout        <= mem[rd_ptr_bin[PTR_W-2:0]];
            rd_ptr_bin  <= rd_ptr_bin + 1;
            rd_ptr_gray <= bin2gray(rd_ptr_bin + 1);
        end
    end
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_ptr_gray_s1 <= 0;
            wr_ptr_gray_s2 <= 0;
        end else begin
            wr_ptr_gray_s1 <= wr_ptr_gray;
            wr_ptr_gray_s2 <= wr_ptr_gray_s1;
        end
    end
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_ptr_gray_s1 <= 0;
            rd_ptr_gray_s2 <= 0;
        end else begin
            rd_ptr_gray_s1 <= rd_ptr_gray;
            rd_ptr_gray_s2 <= rd_ptr_gray_s1;
        end
    end
    assign full  = (wr_ptr_gray == {~rd_ptr_gray_s2[PTR_W-1],
                                    ~rd_ptr_gray_s2[PTR_W-2],
                                     rd_ptr_gray_s2[PTR_W-3:0]});
    assign empty = (rd_ptr_gray == wr_ptr_gray_s2);
endmodule
