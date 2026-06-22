`timescale 1ns/1ps
module tb_sram_ctrl;
    reg clk, rst_n, cs, we, oe;
    reg [7:0] addr;
    reg [7:0] data_in;
    wire [7:0] data;

    assign data = (we) ? data_in : 8'bz;

    sram_ctrl dut(.clk(clk),.rst_n(rst_n),.cs(cs),.we(we),.oe(oe),.addr(addr),.data(data));

    initial clk=0; always #5 clk=~clk;

    task write_mem;
        input [7:0] a, d;
        begin
            @(posedge clk); #1;
            cs=1; we=1; oe=0; addr=a; data_in=d;
            @(posedge clk); #1;
            cs=0; we=0;
        end
    endtask

    task read_mem;
        input [7:0] a;
        begin
            @(posedge clk); #1;
            cs=1; we=0; oe=1; addr=a;
            @(posedge clk); #1;
            $display("Read addr=%0d data=%0d", a, data);
            cs=0; oe=0;
        end
    endtask

    initial begin
        $dumpfile("sim/sram.vcd");
        $dumpvars(0, tb_sram_ctrl);
        rst_n=0; cs=0; we=0; oe=0; addr=0; data_in=0;
        #20; rst_n=1;

        write_mem(8'd0,  8'd170);
        write_mem(8'd1,  8'd85);
        write_mem(8'd10, 8'd255);

        read_mem(8'd0);
        read_mem(8'd1);
        read_mem(8'd10);

        $display("-- SRAM DONE --");
        $finish;
    end
endmodule
