// Módulo I2C Master para comunicación con TCS3472
module i2c_refactor (
    input wire clk,           // Reloj del sistema
    input rst,           // Reset global
    input wire start,         // Señal de inicio de transacción
    input wire rw,            // 0 = write , 1 = read
    input wire [6:0] addr,    // Dirección del esclavo (0x29)
    input wire [7:0] reg_addr,// Dirección del registro a leer o escribir
    input wire [7:0] data_in, // Dato a escribir si rw = 0
    output reg [7:0] data_out,// Dato leído si rw = 1
    output reg done,          // Señal que indica fin de transacción
    inout sda,           // Línea de datos bidireccional
    output scl           // Línea de reloj (salida)

);

//FSM
localparam IDLE = 4'd0;
localparam START = 4'd1;
localparam SEND_ADDR_WRITE = 4'd2;
localparam WAIT_ACK_1 = 4'd3;
localparam SEND_REG_ADR = 4'd4;
localparam RESTART = 4'd5;
localparam SEND_ADDR_READ = 4'd6;
localparam WAIT_ACK_2 = 4'd7;
localparam READ_BYTE_1 = 4'd8;  
localparam STOP = 4'd9; 
localparam DONE = 4'd10;

//Registros internos
reg [4:0] fsm_state; 
reg [4:0] next_state; 
reg clk_10us; 
reg [7:0] shift_reg; //Guarda el byte que se va a enviar o el que se está recibiendo
reg [3:0] bit_cnt; //Cuenta los bits enviados o leídos (0 a 7)
reg scl_reg; //Valor actual de SCL
reg [15:0] clk_div_cnt; //Contador para dividir CLK y hacer SCL lento
reg [15:0] clk_div_cnt_2;
reg scl_reg_prev;
reg sda_out; //Bit que queremos colocar en la línea SDA
reg sda_out_en; //Controla si SDA está en salida (1) o lectura (0)
wire scl_tick; //Pulso generado cada vez que SCL debe cambiar
reg ack_recept;

assign scl = scl_reg;
assign sda = sda_out_en ? sda_out : 1'bz;

//Constantes de configuración
localparam START_CONSTANT = 8'h14;
localparam ADDR_WRITE = 8'b01010010;
localparam ADDR_READ = 8'b01010011;
localparam READ_RED = 8'h16;
localparam READ_BLUE = 8'h18;
localparam READ_GREEN = 8'h1A;

//Reloj lento para SCL
parameter CLK_DIV = 250; //50 MHz → 100 kHz scl

always @(posedge clk or posedge rst) begin 
    if (rst) begin
        clk_div_cnt <= 0;
        clk_div_cnt_2  <= 0;
        scl_reg <= 1;
    end else begin 
        if (clk_div_cnt == CLK_DIV - 1) begin
            clk_div_cnt <= 0;
            scl_reg <= ~scl_reg; //alterna el reloj SCL
            clk_div_cnt_2 <= clk_div_cnt_2 + 1;
            if (clk_div_cnt_2 == 2*CLK_DIV -1)begin
                clk_div_cnt_2 <= 0;
            end
        end else begin
            clk_div_cnt <= clk_div_cnt + 1;
            clk_div_cnt_2 <= clk_div_cnt_2 + 1;
        end
    end 
end
//Logica del cambio de estado y reset de la FSM:
always @(posedge clk or posedge rst) begin
    if (rst)
        fsm_state <= IDLE;
    else begin
        fsm_state <= next_state;
    end
end


assign scl_tick = (clk_div_cnt_2 == 2*CLK_DIV - 1);

always @(*) begin
    case (fsm_state)
        IDLE: next_state <= (start)? START : IDLE;
        START: next_state <= SEND_ADDR_WRITE;
        SEND_ADDR_WRITE: next_state <= (scl_tick)? (bit_cnt==7)? WAIT_ACK_1 : SEND_ADDR_WRITE : SEND_ADDR_WRITE;
        WAIT_ACK_1: next_state <=  (scl_tick)? (sda == 0)? SEND_REG_ADR : WAIT_ACK_1 : WAIT_ACK_1;
        SEND_REG_ADR: next_state <= (scl_tick)? (bit_cnt == 0)?  RESTART : SEND_REG_ADR : SEND_REG_ADR;
        RESTART: next_state <= (scl_tick)? SEND_ADDR_READ : RESTART;
        SEND_ADDR_READ: next_state <= (scl_tick)? (bit_cnt == 0)?  WAIT_ACK_2 : SEND_ADDR_READ : SEND_ADDR_READ;
        WAIT_ACK_2: next_state <=(scl_tick)? (sda == 0)? READ_BYTE_1 : STOP : WAIT_ACK_2;
        READ_BYTE_1: next_state <= (scl_tick)? (bit_cnt == 0)?  STOP : READ_BYTE_1 : READ_BYTE_1;
        STOP: next_state <= (scl_tick)? DONE : STOP;
        DONE: next_state <= IDLE; // Regresa al estado IDLE
        default: next_state <= IDLE; // En caso de estado desconocido, regresa a IDLE
    endcase
end

always @(posedge clk)begin
    if (rst) begin
        clk_div_cnt <= 0;
        next_state <= IDLE; // SCL en alto al inicio
    end else begin 
            case(fsm_state)
            IDLE: begin
                done = 0;
                sda_out = 1;
                sda_out_en = 1;
            end
            START: begin
                sda_out = 0;
                sda_out_en = 1; 
                shift_reg = ADDR_WRITE;
                bit_cnt = 0; 
            end
            SEND_ADDR_WRITE: begin
                sda_out_en = 1;
                sda_out = shift_reg[bit_cnt]; // enviamos bit actual por SDA
                if (scl_tick) begin
                    if (bit_cnt == 7) begin
                        sda_out_en = 0; // liberar SDA para ACK
                        ack_recept = sda;
                    end else begin 
                        bit_cnt = bit_cnt + 1; // siguiente bit
                    end 
                end
            end
            WAIT_ACK_1: begin
                sda_out_en = 0; // liberar SDA (entrada)
                ack_recept = sda;
                if (scl_tick) begin
                    if (ack_recept == 0) begin //ACK
                        shift_reg = reg_addr;
                        bit_cnt = 0;
                    end 
                end
            end
            SEND_REG_ADR: begin
                sda_out_en = 1;
                sda_out = shift_reg[bit_cnt];
                if (scl_tick) begin
                    if (bit_cnt == 7) begin
                        sda_out_en = 0;
                    end else begin
                        bit_cnt = bit_cnt + 1;
                    end
                end
            end
            RESTART: begin
                sda_out_en = 1;
                sda_out = 1;
                if (scl_tick) begin
                    sda_out = 0; // SDA baja mientras SCL está alto
                    shift_reg = ADDR_READ; // cargar dirección de lectura
                    bit_cnt = 7;
                end
            end
            SEND_ADDR_READ: begin
                sda_out_en = 1;
                sda_out = shift_reg[bit_cnt]; 
                if (scl_tick) begin
                    if (bit_cnt == 0) begin
                        sda_out_en = 0; 
                    end else begin 
                        bit_cnt = bit_cnt - 1; 
                    end 
                end           
            end
            WAIT_ACK_2: begin
                sda_out_en = 0; 
            end
            READ_BYTE_1: begin
                sda_out_en = 0; //SDA en lectura
                if (scl_tick) begin
                    shift_reg[bit_cnt] = sda; // leer bit entrante
                    if (bit_cnt == 0) begin
                        bit_cnt = 7;
                        data_out = shift_reg; // guardar byte recibido
                        sda_out_en = 1;
                        sda_out = 1; // enviar NACK
                    end else begin 
                        bit_cnt = bit_cnt - 1;
                    end
                end
            end
            STOP: begin
                sda_out_en = 1;
                sda_out = 0;
                if (scl_tick) begin
                    sda_out = 1; // SDA sube mientras SCL está alto
                end
            end
            DONE: begin
                done = 1;
            end
        endcase
    end
end
endmodule