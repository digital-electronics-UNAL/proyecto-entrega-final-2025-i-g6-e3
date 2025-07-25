`timescale 1ns / 1ps
`include "top.v"

module FSM_tb();
    reg clk;            
    reg reset;
    reg ready;
    reg [2:0] color;
    wire [7:0] data;
    wire buzzer;

    top uut (
        .clk(clk),
        .Reset(reset),
        .ready_i(ready),
        .Color(color),
        .Data(data),
        .Buzzer(buzzer)
    );

    initial begin
        clk = 0;
        reset = 1;
        ready = 1;
    end

    always #10 clk = ~clk;

    initial begin: TEST_CASE
        $dumpfile("top_tb.vcd");
        $dumpvars(-1, uut);
        #(1000000) $finish;
    end


endmodule