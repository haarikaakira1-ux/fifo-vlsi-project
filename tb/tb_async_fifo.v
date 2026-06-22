`timescale 1ns/1ps
module tb_async_fifo;

parameter DEPTH = 16;
parameter WIDTH = 8;

reg wr_clk, rd_clk;
reg wr_rst_n, rd_rst_n;
reg wr_en, rd_en;
reg [WIDTH-1:0] din;
wire [WIDTH-1:0] dout;
wire full, empty;

async_fifo #(.DEPTH(DEPTH),.WIDTH(WIDTH)) dut(
    .wr_clk(wr_clk),.rd_clk(rd_clk),
    .wr_rst_n(wr_rst_n),.rd_rst_n(rd_rst_n),
    .wr_en(wr_en),.rd_en(rd_en),
    .din(din),.dout(dout),
    .full(full),.empty(empty));

always #5  wr_clk = ~wr_clk;
always #7  rd_clk = ~rd_clk;

reg [WIDTH-1:0] ref_queue [0:255];
integer q_head, q_tail, errors, i;

task write_fifo;
input [WIDTH-1:0] data;
begin
    @(negedge wr_clk);
    wr_en = 1; din = data;
    @(posedge wr_clk); #1;
    if (!full) begin
        ref_queue[q_tail % DEPTH] = data;
        q_tail = q_tail + 1;
    end
    wr_en = 0;
end
endtask

task read_fifo;
begin
    @(negedge rd_clk);
    rd_en = 1;
    @(posedge rd_clk); #1;
    if (!empty) begin
        if (dout !== ref_queue[q_head % DEPTH]) begin
            $display("ERROR: got %0h expected %0h",
                dout, ref_queue[q_head % DEPTH]);
            errors = errors + 1;
        end
        q_head = q_head + 1;
    end
    rd_en = 0;
end
endtask

task drain_fifo;
begin
    repeat(DEPTH+4) begin
        @(negedge rd_clk);
        rd_en = !empty;
        @(posedge rd_clk); #1;
        if(rd_en && !empty) q_head = q_head + 1;
        rd_en = 0;
    end
    repeat(6) @(posedge rd_clk);
end
endtask

initial begin
    $dumpfile("sim/async_fifo.vcd");
    $dumpvars(0, tb_async_fifo);

    wr_clk=0; rd_clk=0;
    wr_rst_n=0; rd_rst_n=0;
    wr_en=0; rd_en=0; din=0;
    q_head=0; q_tail=0; errors=0;

    repeat(4) @(posedge wr_clk);
    wr_rst_n=1; rd_rst_n=1;

    // Test 1: Fill FIFO
    $display("Test 1: Fill FIFO");
    for(i=0; i<DEPTH; i=i+1)
        write_fifo(i*2 + 5);
    repeat(4) @(posedge wr_clk);
    if(!full) begin
        $display("FAIL: full not set"); errors=errors+1;
    end else $display("PASS: Full flag correct");

    // Test 2: Write to full
    $display("Test 2: Write to full");
    write_fifo(8'hFF);
    $display("PASS: Overflow protected");

    // Test 3: Drain FIFO
    $display("Test 3: Drain FIFO");
    for(i=0; i<DEPTH; i=i+1)
        read_fifo;
    repeat(6) @(posedge rd_clk);
    if(!empty) begin
        $display("FAIL: empty not set"); errors=errors+1;
    end else $display("PASS: Empty flag correct");

    // Test 4: Simultaneous RW
    $display("Test 4: Simultaneous RW");
    write_fifo(8'hAA);
    write_fifo(8'hBB);
    read_fifo;
    read_fifo;
    $display("PASS: Simultaneous RW done");

    // Test 5: Burst write then read
    $display("Test 5: Burst write then read");
    drain_fifo;
    q_head=0; q_tail=0;
    for(i=0; i<8; i=i+1)
        write_fifo(8'h10 + i);
    repeat(4) @(posedge rd_clk);
    for(i=0; i<8; i=i+1)
        read_fifo;
    $display("PASS: Burst done");

    #200;
    if(errors==0)
        $display("\n==== ALL TESTS PASSED ====");
    else
        $display("\n==== %0d ERRORS FOUND ====", errors);

    $finish;
end

always @(posedge wr_clk)
    if(wr_rst_n && full && wr_en)
        $display("ASSERT: Write to full at %0t", $time);

always @(posedge rd_clk)
    if(rd_rst_n && empty && rd_en)
        $display("ASSERT: Read from empty at %0t", $time);

endmodule
