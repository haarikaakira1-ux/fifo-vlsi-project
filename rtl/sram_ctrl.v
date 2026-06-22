module sram_ctrl #(
    parameter ADDR_W = 8,
    parameter DATA_W = 8
)(
    input clk, rst_n,
    input cs, we, oe,
    input  [ADDR_W-1:0] addr,
    inout  [DATA_W-1:0] data
);
    reg [DATA_W-1:0] mem [0:(1<<ADDR_W)-1];
    reg [DATA_W-1:0] data_out;
    reg output_en;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= 0;
            output_en <= 0;
        end else if (cs) begin
            if (we)
                mem[addr] <= data;
            output_en <= oe && !we;
            data_out  <= mem[addr];
        end else
            output_en <= 0;
    end

    assign data = output_en ? data_out : {DATA_W{1'bz}};
endmodule
