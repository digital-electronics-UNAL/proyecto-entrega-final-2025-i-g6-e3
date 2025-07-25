`include "FSM/FSM_V2.v"
`include "src/LCD.v"
`include "FSM/RANG.v"
`include "FSM/LSFR.v"

module top (
    input clk,
    input Reset,
    input ready_i,
    input  [2:0] Color, 
    output [7:0] Data,
    output Buzzer
  );
  
  wire [2:0] DataFSM;
  wire [7:0] Pun; 
  wire [7:0] Mpun;
  wire [7:0] Apun;
  wire Rs;
  wire Rw;
  wire Enable;
  wire [1:0] rnd;  


  FSM_V2 #(2, 3, 2, 10, 50, 50) fsm( 
        .clk(clk),.reset(Reset),.color(Color),.pun(Pun),.buzzer(Buzzer),.data(DataFSM),.rnd(rnd)
  );

  LFSR lfsr(
        .clk(clk),.rst(Reset),.rnd(rnd)
  );
  

  LCD1604_controller lcd(
        .clk(clk),.reset(Reset),.ready_i(1'b1),.mensaje(DataFSM),.rs(Rs),.rw(Rw),.enable(Enable),.data(Data)
  );
endmodule