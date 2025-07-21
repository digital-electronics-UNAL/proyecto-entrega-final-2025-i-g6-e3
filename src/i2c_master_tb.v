//tb (test banch) banco de puebas
`timescale 1ns/1ps
`include "src/i2c_master.v"

module i2c_master_tb(); // parentesis vacio porque no tiene entradas ni salidas

    reg Clk;           // Reloj del sistema
    reg Rst;           // Reset global
    reg Start;         // Señal de inicio de transacción
    reg Rw;            // 0 = write , 1 = read
    reg [6:0] Addr;    // Dirección del esclavo (0x29)
    reg [7:0] Reg_addr;// Dirección del registro a leer o escribir
    reg [7:0] Data_in; // Dato a escribir si rw = 0

    wire [7:0] Data_out;// Dato leído si rw = 1
    wire Done;          // Señal que indica fin de transacción
    reg Sda;           // Línea de datos bidireccional
    wire Scl;           // Línea de reloj (salida)

    // Simular el sensor TCS3472 (esclavo)
    reg Sda_slave = 1'b1;  // Pull-up

    initial begin
    Sda <= (Sda_slave == 0) ? 1'b0 : 1'b1;  // Drive solo cuando el esclavo responde
    end

    i2c_master uut (
       .clk(Clk),
       .rst(Rst),
       .start(Start),
       .rw(Rw),
       .addr(Addr),
       .reg_addr(Reg_addr),
       .data_in(Data_in),
       .data_out(),
       .done(),
       .sda(),
       .scl()
  );

  // Reloj: 50 MHz → periodo 20 ns
  always #10 Clk = ~Clk;

initial begin

        // Inicialización
    Clk = 0;
    Rst = 1;
    Start = 1;
    Rw = 1;               // Modo lectura
    Addr = 7'h29;         // Dirección 0x29
    Reg_addr = 8'h16;     // Registro RED (0x16)
    Data_in = 8'h00;
    Sda_slave = 1'b1;     // Inicialmente en alta impedancia (pull-up)
    Sda <= (Sda_slave == 0) ? 1'b0 : 1'b1;  // Drive solo cuando el esclavo responde


    #100;
    Rst = 0;

    // Secuencia de prueba
    #100;
    Start = 1;
    #40;
    Start = 1;

    // Simular ACK del esclavo después de la dirección
    wait(uut.fsm_state == 3);  // Esperar estado WAIT_ACK_1
    #100;
    Sda_slave = 1'b0;  // ACK
    Sda <= (Sda_slave == 0) ? 1'b0 : 1'b1;  // Drive solo cuando el esclavo responde
    #100;
    Sda_slave = 1'b1;
    Sda <= (Sda_slave == 0) ? 1'b0 : 1'b1;  // Drive solo cuando el esclavo responde

    // Simular ACK después del registro
    wait(uut.fsm_state == 7);  // Esperar estado WAIT_ACK_2
    #100;
    Sda_slave = 1'b0;  // ACK
    Sda <= (Sda_slave == 0) ? 1'b0 : 1'b1;  // Drive solo cuando el esclavo responde
    #100;
    Sda_slave = 1'b1;
    Sda <= (Sda_slave == 0) ? 1'b0 : 1'b1;  // Drive solo cuando el esclavo responde

    // Simular datos del sensor (ejemplo: valor RED = 0xABCD)
    wait(uut.fsm_state == 8);  // Esperar estado READ_BYTE_1
    fork
      begin
        // Primer byte (MSB): 0xAB
        #100 Sda_slave = 1'b1; // Bit 7
        #100 Sda_slave = 1'b0; // Bit 6
        #100 Sda_slave = 1'b1; // Bit 5
        #100 Sda_slave = 1'b0; // Bit 4
        #100 Sda_slave = 1'b1; // Bit 3
        #100 Sda_slave = 1'b0; // Bit 2
        #100 Sda_slave = 1'b1; // Bit 1
        #100 Sda_slave = 1'b1; // Bit 0
      end
    join

    // Esperar finalización
    wait(Done == 1);
    #1000;
    $finish;
end

    initial begin
        $dumpfile("i2c_master_tb.vcd");
        $dumpvars(-1,uut);
      #9000000 $finish;
    end

endmodule