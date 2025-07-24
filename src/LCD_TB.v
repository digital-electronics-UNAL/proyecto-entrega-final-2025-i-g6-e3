`timescale 1ns / 1ps
`include "src/LCD.v"

module LCD1604_controller_TB();
    reg clk;
    reg rst;
    reg ready_i; 
    reg [3:0] mensaje;

    LCD1604_controller #(4, 64, 16, 8, 50) uut (
        .clk(clk),
        .reset(rst),
        .ready_i(ready_i),
        .mensaje(mensaje)
    );

    initial begin
        clk = 0;
        rst = 1;
        ready_i = 1;
        #10 rst = 0;
        mensaje = 4'b0000;
        #10 rst = 1;
    end

    always #10 clk = ~clk;

    initial begin: TEST_CASE
        $dumpfile("LCD_TB.vcd");
        $dumpvars(-1, uut);
        #(1460000) $finish;
    end
endmodule