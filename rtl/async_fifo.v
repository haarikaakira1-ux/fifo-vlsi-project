// Async FIFO - Clifford Cummings style (dual clock, Gray code pointers)
module async_fifo #(
    parameter DEPTH = 16,
    parameter WIDTH = 8,
    parameter ADDR  = 4
)(
    // Write domain
    input  wclk, wrst_n, wr_en,
    input  [WIDTH-1:0] wdata,
    output wfull,
    // Read domain
    input  rclk, rrst_n, rd_en,
    output reg [WIDTH-1:0] rdata,
    output rempty
);
    // Memory
    reg [WIDTH-1:0] mem [0:DEPTH-1];

    // Write domain pointers
    reg [ADDR:0] wbin, wptr_gray;
    // Read domain pointers
    reg [ADDR:0] rbin, rptr_gray;

    // Synchronizers (2FF)
    reg [ADDR:0] wptr_sync1, wptr_sync2;
    reg [ADDR:0] rptr_sync1, rptr_sync2;

    // Binary to Gray
    function [ADDR:0] bin2gray;
        input [ADDR:0] bin;
        bin2gray = (bin >> 1) ^ bin;
    endfunction

    // Gray to Binary
    function [ADDR:0] gray2bin;
        input [ADDR:0] gray;
        integer i;
        begin
            gray2bin[ADDR] = gray[ADDR];
            for (i = ADDR-1; i >= 0; i = i-1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    // Write logic
    wire [ADDR-1:0] waddr = wbin[ADDR-1:0];
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wbin <= 0; wptr_gray <= 0;
        end else if (wr_en && !wfull) begin
            mem[waddr] <= wdata;
            wbin      <= wbin + 1;
            wptr_gray <= bin2gray(wbin + 1);
        end
    end

    // Read logic
    wire [ADDR-1:0] raddr = rbin[ADDR-1:0];
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rbin <= 0; rptr_gray <= 0; rdata <= 0;
        end else if (rd_en && !rempty) begin
            rdata     <= mem[raddr];
            rbin      <= rbin + 1;
            rptr_gray <= bin2gray(rbin + 1);
        end
    end

    // Synchronize write pointer to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) {rptr_sync2, rptr_sync1} <= 0;
        else         {wptr_sync2, wptr_sync1} <= {wptr_sync1, wptr_gray};
    end

    // Synchronize read pointer to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) {rptr_sync2, rptr_sync1} <= 0;
        else         {rptr_sync2, rptr_sync1} <= {rptr_sync1, rptr_gray};
    end

    // Full/Empty flags
    assign wfull  = (wptr_gray == {~rptr_sync2[ADDR:ADDR-1], rptr_sync2[ADDR-2:0]});
    assign rempty = (rptr_gray == wptr_sync2);

endmodule
