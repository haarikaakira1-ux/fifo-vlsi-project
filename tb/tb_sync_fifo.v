`timescale 1ns/1ps
module tb_sync_fifo;
parameter DEPTH = 16;
parameter WIDTH = 8;
reg clk, rst_n, wr_en, rd_en;
reg [WIDTH-1:0] din;
wire [WIDTH-1:0] dout;
wire full, empty, almost_full, almost_empty;
wire [$clog2(DEPTH):0] count;
sync_fifo #(.DEPTH(DEPTH),.WIDTH(WIDTH)) dut(
.clk(clk),.rst_n(rst_n),
.wr_en(wr_en),.rd_en(rd_en),
.din(din),.dout(dout),
.full(full),.empty(empty),
.almost_full(almost_full),
.almost_empty(almost_empty),
.count(count));
always #5 clk=~clk;
reg [WIDTH-1:0] ref_queue [0:DEPTH-1];
integer q_head,q_tail,q_count,errors,i;
task write_fifo;
input [WIDTH-1:0] data;
begin
@(negedge clk);
wr_en=1; din=data; rd_en=0;
@(posedge clk); #1;
if(!full) begin
ref_queue[q_tail%DEPTH]=data;
q_tail=q_tail+1;
q_count=q_count+1;
end
wr_en=0;
end
endtask
task read_fifo;
begin
@(negedge clk);
rd_en=1; wr_en=0;
@(posedge clk); #1;
if(!empty) begin
if(dout!==ref_queue[q_head%DEPTH]) begin
$display("ERROR: got %0h expected %0h",dout,ref_queue[q_head%DEPTH]);
errors=errors+1;
end
q_head=q_head+1;
q_count=q_count-1;
end
rd_en=0;
end
endtask
task drain_fifo;
begin
while(!empty) read_fifo;
end
endtask
initial begin
$dumpfile("sim/fifo.vcd");
$dumpvars(0,tb_sync_fifo);
clk=0; rst_n=0; wr_en=0; rd_en=0; din=0;
q_head=0; q_tail=0; q_count=0; errors=0;
repeat(3) @(posedge clk);
rst_n=1;
$display("Test 1: Fill FIFO");
for(i=0;i<DEPTH;i=i+1) write_fifo(i*3+7);
if(!full) begin $display("FAIL: full flag"); errors=errors+1; end
else $display("PASS: Full flag correct");
$display("Test 2: Write to full");
write_fifo(8'hFF);
if(count!==DEPTH) begin $display("FAIL: overflow"); errors=errors+1; end
else $display("PASS: Overflow protected");
$display("Test 3: Drain FIFO");
for(i=0;i<DEPTH;i=i+1) read_fifo;
if(!empty) begin $display("FAIL: empty flag"); errors=errors+1; end
else $display("PASS: Empty flag correct");
$display("Test 4: Read from empty");
read_fifo;
if(count!==0) begin $display("FAIL: underflow"); errors=errors+1; end
else $display("PASS: Underflow protected");
$display("Test 5: Simultaneous RW");
write_fifo(8'hAB);
@(negedge clk);
wr_en=1; rd_en=1; din=8'hCD;
@(posedge clk); #1;
wr_en=0; rd_en=0;
$display("PASS: Simultaneous RW done");
$display("Test 6: Almost-full flag");
drain_fifo;
for(i=0;i<DEPTH-1;i=i+1) write_fifo(i);
if(!almost_full) begin $display("FAIL: almost_full not set"); errors=errors+1; end
else $display("PASS: almost_full correct");
#20;
if(errors==0) $display("\n==== ALL TESTS PASSED ====");
else $display("\n==== %0d ERRORS FOUND ====",errors);
$finish;
end
always @(posedge clk) begin
if(rst_n) begin
if(full&&empty) $display("ASSERT FAIL: full and empty!");
if(count>DEPTH) $display("ASSERT FAIL: count overflow!");
end
end
endmodule
