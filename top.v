`include "FSM/FSM_V2.v"
`include "src/LCD.v"
`include "FSM/RANG.v"

module top (
    input clk,
    input reset,
    input ready_i,
    input [2:0]color, 
    output reg [7:0] data,
    output reg buzzer,
    output reg [6:0] mpun,
    output reg [6:0] apun
  );

  wire Clk;
  wire Reset;
  wire [2:0] Color;
  wire [2:0] DataFSM;
  wire [7:0] Pun;
  wire Buzzer;  
  wire [7:0] Mpun;
  wire [7:0] Apun;
  wire Ready;
  wire Rs;
  wire Rw;
  wire Enable;
  wire [7:0] Data;
  

  FSM_V2 #(2, 3, 2, 10, 50, 50) fsm( 
        .clk(Clk),.reset(Reset),.color(Color),.pun(Pun),.buzzer(Buzzer),.data(DataFSM)
  );
  
  LCD1604_controller lcd(
        .clk(Clk),.reset(Reset),.ready_i(Ready),.mensaje(DataFSM),.rs(Rs),.rw(Rw),.enable(Enable),.data(Data)
  );
endmodule