module  FSM #(parameter INIT_PATRON = 2,
                        DATA_BITS = 4,
                        IN_BITS = 2,
                        TIME = 20,
                        TIME_IN = 50,
                        COUNT_MAX = 800000)(
    input clk,            
    input reset,
    input [IN_BITS:0] color,
    output reg [DATA_BITS-1:0] data,
    output reg [7:0] pun,
    output reg buzzer
);

// Definir los estados de la FSM
localparam IDLE = 2'b00;
localparam LOAD = 2'b01;
localparam START = 2'b10;
localparam DELAY = 2'b11;

reg [1:0] fsm_state;
reg [1:0] next_state;
reg clk_16ms;

// Mensajes de salida
localparam RED = 4'b000;
localparam GREEN = 4'b001;
localparam BLUE = 4'b010;
localparam YELLOW = 4'b011;
localparam NULL = 4'b100;

// Definir un contador para el divisor de frecuencia
reg [$clog2(COUNT_MAX)-1:0] clk_counter;
// Definir un contador para controlar el llenado del patron
reg [$clog2(INIT_PATRON):0] patron_counter;
// Definir un contador para controlar la comparacion
reg [$clog2(INIT_PATRON):0] patron_comp_counter;
// Definir un contador para controlar el tiempo
reg [$clog2(TIME)-1:0] tiempo;
// Definir un contador para controlar el tiempo de entrada
reg [$clog2(TIME_IN)-1:0] tiempo_in;

// Banco de registros
reg [IN_BITS-1:0] patron [0: INIT_PATRON-1];

//
reg [1:0] correcto;

reg [IN_BITS-1:0] temp;///////////////////////////// 

reg [7:0] punt;

initial begin
    fsm_state <= IDLE;
    patron_counter <= 'b0;
    patron_comp_counter <= 'b0;
    correcto <= 2'b10;
    clk_16ms <= 1'b0;
    clk_counter <= 'b0;
    tiempo <= 'b0;
    tiempo_in <= 'b0;
    buzzer = 'b0;
    temp <= 'b0;
    data <= NULL;
    pun <= 'b0;
    punt <= 'b0;
    $readmemh("/home/david/Simon-Dice/FSM/init.txt", patron);
    
end

always @(posedge clk) begin
    if (clk_counter == COUNT_MAX-1) begin
        clk_16ms <= ~clk_16ms;
        clk_counter <= 'b0;
    end else begin
        clk_counter <= clk_counter + 1;
    end
end


always @(posedge clk_16ms)begin
    if(reset == 0)begin
        fsm_state <= IDLE;
    end else begin
        fsm_state <= next_state;
    end
end

always @(*) begin
    case(fsm_state)
        IDLE: begin
            next_state <= LOAD;
        end
        LOAD: begin 
            next_state <= DELAY;
        end
        START:begin
			next_state <= IDLE;
        end
        DELAY: begin 
            next_state <= (tiempo_in == TIME_IN)? START : DELAY;
        end
        default: next_state = IDLE;
    endcase
end

always @(posedge clk_16ms) begin
    if (reset == 0) begin
        patron_counter <= 'b0;
        patron_comp_counter <= 'b0;
        correcto <= 2'b10; 
	    data <= 4'b1000;
        tiempo <= 'b0;
        tiempo_in <= 'b0;
        $readmemh("/home/david/Simon-Dice/FSM/init.txt", patron);
    end else begin
        case (next_state)
            IDLE: begin
                correcto <= 2'b10;
            end
            LOAD: begin 	
                correcto <= 2'b10;
                temp <= $urandom;  
                data <= temp;
                //patron [patron_counter] <= patron [patron_counter] [2:0]; 
            end
            START: begin
                tiempo <= 'b0;
                pun <= pun + 1;
                correcto <= (temp == color)? 2'b01 : 2'b00;
            end
            DELAY: begin
                tiempo <= tiempo + 1;
            end
        endcase
    end
end

assign enable = clk_16ms;

endmodule