module i2c(
    input wire clk,           // Reloj del sistema
    input rst,               // Reset global
    inout sda,           // Línea de datos bidireccional
    output scl,          // Línea de reloj (salida)
);

//Constantes de configuración
localparam START_CONSTANT = 8'h14;
localparam ADDR_WRITE = 8'b01010010;
localparam ADDR_READ = 8'b01010011;
localparam READ_RED = 8'h16;
localparam READ_BLUE = 8'h18;
localparam READ_GREEN = 8'h1A;

//FSM:
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

reg [7:0] sda_out;
reg sda_out_en ;

assign sda = sda_out_en ? sda_out : 1'bz; 
assign scl = 1;


//RELOJ PARA SCL:
//Parametros de reloj
reg [15:0] clk_div_cnt; //Contador para dividir CLK
reg scl_reg;//Valor actual de SCL
parameter CLK_DIV = 250;
//Logica del reloj:
always @(posedge clk or posedge rst) begin 
    if (rst) begin
        clk_div_cnt <= 0;
        scl_reg <= 1;
    end else begin 
        if (clk_div_cnt == CLK_DIV - 1) begin
            clk_div_cnt <= 0;
            scl_reg <= ~scl_reg; //alterna el reloj SCL
        end else begin
            clk_div_cnt <= clk_div_cnt + 1;
        end
    end 
end
//Logica del cambio de estado y reset de la FSM:
always @(posedge clk or posedge rst) begin
    if (rst)
        fsm_state <= IDLE;
    else if (scl_tick)
        fsm_state <= next_state;
end


always @(*) begin
    case (fsm_state)
        IDLE: begin
            next_state <= START;
        end
        START: begin
            next_state <= SEND_ADDR_WRITE;
        end
        SEND_ADDR_WRITE: begin
            next_state <= WAIT_ACK_1;
        end
        WAIT_ACK_1: begin
            next_state <= SEND_REG_ADR;
        end
        SEND_REG_ADR: begin
            next_state <= RESTART;
        end
        RESTART: begin
            next_state <= SEND_ADDR_READ;
        end
        SEND_ADDR_READ: begin
            next_state <= WAIT_ACK_2;
        end
        WAIT_ACK_2: begin
            next_state <= READ_BYTE_1;
        end
        READ_BYTE_1: begin
            next_state <= STOP;
        end
        STOP: begin
            next_state <= DONE;
        end
        DONE: begin
            next_state <= IDLE; // Regresa al estado IDLE
        end
        default: begin
            next_state <= IDLE; // En caso de estado desconocido, regresa a IDLE
        end
    endcase
end

always @(posedge clk)begin
    if (reset==0) begin
        clk_div_cnt <= 0;
        next_state <= IDLE; // SCL en alto al inicio
    end else begin 
        case (next_state)
            IDLE: begin 
                sda_out <= 0; // SDA en alto
                sda_out_en <= 1; // SDA en modo salida
                scl <= 0;
            end
            START: begin
                sda_out <= 0; // SDA baja para iniciar la comunicación
                sda_out_en <= 1; // SDA en modo salida
                scl <= scl_reg;
                
            end
            SEND_ADDR_WRITE: begin
                
            end
        endcase
end
end






endmodule