`timescale 1ns/1ps
`include "src/i2c_refactor.v"

module i2c_refactor_tb;

    // Señales de control
    reg Clk;
    reg Rst;
    reg Start;
    reg Rw;
    reg [6:0] Addr;
    reg [7:0] Reg_addr;
    reg [7:0] Data_in;

    wire [7:0] Data_out;
    wire Done;

    // Línea I2C bidireccional
    wire Sda;
    wire Scl;

    // Simulación de esclavo (TCS3472)
    reg drive_slave_sda;
    reg sda_slave_out;

    // SDA controlada por el esclavo solo cuando drive_slave_sda = 1
    assign Sda = drive_slave_sda ? sda_slave_out : 1'bz;

    // Instancia del módulo maestro
    i2c_refactor uut (
        .clk(Clk),
        .rst(Rst),
        .start(Start),
        .rw(Rw),
        .addr(Addr),
        .reg_addr(Reg_addr),
        .data_in(Data_in),
        .data_out(Data_out),
        .done(Done),
        .sda(Sda),
        .scl(Scl)
    );

    // Generador de reloj: 50 MHz
    always #10 Clk = ~Clk;

    initial begin
        // Inicialización
        Clk = 0;
        Rst = 1;
        Start = 0;
        Rw = 1;                // Modo lectura
        Addr = 7'h29;          // Dirección I2C del sensor
        Reg_addr = 8'h16;      // Registro RED bajo
        Data_in = 8'h00;

        drive_slave_sda = 0;
        sda_slave_out = 1;

        #100;
        Rst = 0;

        // Iniciar lectura
        #100;
        Start = 1;
        #40;
        Start = 0;

        // Simular ACK después de dirección
        wait(uut.fsm_state == 3); // WAIT_ACK_1
        #100;
        sda_slave_out = 0; // ACK
        drive_slave_sda = 1;
        #100;
        drive_slave_sda = 0;

        // Simular ACK después del registro
        wait(uut.fsm_state == 7); // WAIT_ACK_2
        #100;
        drive_slave_sda = 1;
        sda_slave_out = 0; // ACK
        #100;
        drive_slave_sda = 0;

        // Simular lectura de byte bajo del canal rojo (ej. 0xCD)
        wait(uut.fsm_state == 9); // READ_BYTE_LOW (ajusta si tu módulo usa otro nombre)
        fork
            begin
                // Bit 7 to Bit 0 of 0xCD = 11001101
                #50 sda_slave_out = 1; drive_slave_sda = 1;  // bit 7
                #100 sda_slave_out = 1;                     // bit 6
                #100 sda_slave_out = 0;                     // bit 5
                #100 sda_slave_out = 0;                     // bit 4
                #100 sda_slave_out = 1;                     // bit 3
                #100 sda_slave_out = 1;                     // bit 2
                #100 sda_slave_out = 0;                     // bit 1
                #100 sda_slave_out = 1;                     // bit 0
                #100 drive_slave_sda = 0;                   // liberar línea
            end
        join

        // Esperar finalización
        wait(Done == 1);
        #1000;
        $finish;
    end

    // Dump de simulación
    initial begin
        $dumpfile("i2c_refactor_tb.vcd");
        $dumpvars(-1, i2c_refactor_tb);
        #900000 $finish;
    end

endmodule