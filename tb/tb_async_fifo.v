`timescale 1ns/1ps
module tb_async_fifo;
    parameter WIDTH = 8, DEPTH = 16;

    reg wclk, rclk, wrst_n, rrst_n;
    reg wr_en, rd_en;
    reg [WIDTH-1:0] wdata;
    wire [WIDTH-1:0] rdata;
    wire wfull, rempty;

    async_fifo #(DEPTH, WIDTH, 4) dut (
        .wclk(wclk), .wrst_n(wrst_n), .wr_en(wr_en), .wdata(wdata), .wfull(wfull),
        .rclk(rclk), .rrst_n(rrst_n), .rd_en(rd_en), .rdata(rdata), .rempty(rempty)
    );

    // Different clock frequencies
    initial wclk = 0;
    always #5  wclk = ~wclk;  // 100 MHz write clock
    initial rclk = 0;
    always #7  rclk = ~rclk;  // ~71 MHz read clock

    integer i, errors;
    initial begin
        $dumpfile("sim/async_fifo.vcd");
        $dumpvars(0, tb_async_fifo);
        errors = 0;

        // Reset
        wrst_n=0; rrst_n=0; wr_en=0; rd_en=0; wdata=0;
        #50; wrst_n=1; rrst_n=1; #20;

        // Write 8 items
        $display("-- Writing 8 items --");
        for (i=0; i<8; i=i+1) begin
            @(posedge wclk); #1;
            wr_en=1; wdata=i*10;
        end
        @(posedge wclk); #1; wr_en=0;
        #100;

        // Read 8 items
        $display("-- Reading 8 items --");
        for (i=0; i<8; i=i+1) begin
            @(posedge rclk); #1;
            rd_en=1;
        end
        @(posedge rclk); #1; rd_en=0;
        #100;

        // Fill to full
        $display("-- Fill to full --");
        @(posedge wclk); wr_en=1;
        repeat(16) @(posedge wclk);
        wr_en=0; #20;
        $display("wfull=%b (expect 1)", wfull);

        #200;
        $display("-- DONE: errors=%0d --", errors);
        $finish;
    end
endmodule
