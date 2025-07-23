`timescale 1ns / 1ps
`include "FSM/FSM.v"

module FSM_tb();
    reg clk;            
    reg reset;
    reg [2:0] color;
    wire [3:0] data;
    wire buzzer;

    FSM #(2, 4, 2, 10, 50, 50) uut (
        .clk(clk),
        .reset(reset),
        .color(color),
        .data(data),
        .buzzer(buzzer)
    );

    initial begin
        clk = 0;
        reset = 1;
        color = 3'b100;
        #20
        color = 3'b001;
    end

    always #10 clk = ~clk;

    initial begin: TEST_CASE
        $dumpfile("FSM_tb.vcd");
        $dumpvars(-1, uut);
        #(100000) $finish;
    end


endmodule