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
localparam IDLE = 3'b000;
localparam LOAD = 3'b001;
localparam START = 3'b010;
localparam CORRECT = 3'b011;
localparam WRONG = 3'b100;
localparam SUCCES = 3'b101;
localparam COLOR = 3'b110;

reg [2:0] fsm_state;
reg [2:0] next_state;
reg clk_16ms;

// Mensajes de salida
localparam RED = 4'b0000;
localparam GREEN = 4'b0001;
localparam BLUE = 4'b0010;
localparam YELLOW = 4'b0011;
localparam READY = 4'b0100;
localparam CORRECTO = 4'b0101;
localparam INCORRECTO = 4'b0110;
localparam COMPLETO = 4'b0111;
localparam PUN = 4'b1000;

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
    data <= PUN;
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
            next_state <= (patron_counter == (INIT_PATRON + 1))? START : COLOR;
        end
        START:begin
			next_state <= (correcto == 2'b10)? ((tiempo_in == TIME_IN)? WRONG : START) : ((correcto == 2'b00)? WRONG : ((patron_comp_counter == INIT_PATRON)? SUCCES : CORRECT));
        end
        CORRECT: begin 
            next_state <= (tiempo == TIME)? START : CORRECT;
        end
		WRONG: begin
			next_state <= (tiempo == TIME)? IDLE : WRONG;
		end
        SUCCES: begin 
            next_state <= (tiempo == TIME)? LOAD : SUCCES;
        end
        COLOR: begin 
            next_state <= (tiempo == TIME)? LOAD : COLOR;
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
                patron_counter <= 'b0;
                patron_comp_counter <= 'b0;
                correcto <= 2'b10;
                tiempo <= 'b0;
                tiempo_in <= 'b0;
                data <= PUN;
                buzzer = 'b0;
                punt <= 'b0;
            end
            LOAD: begin 	
                patron_counter <= patron_counter + 1;
                patron_comp_counter <= 'b0;
                tiempo <= 'b0;
                tiempo_in <= 'b0;
                correcto <= 2'b10;
                temp <= $urandom;  
                patron [patron_counter] <= temp;
                //patron [patron_counter] <= patron [patron_counter] [2:0]; 
            end
            START: begin
                tiempo_in <= tiempo_in + 1;
                patron_comp_counter <= patron_comp_counter + 1;
                tiempo <= 'b0;
                correcto <= ({1'b0,patron [patron_comp_counter]} == color)? 2'b01 : 2'b00;
				data <= READY;
            end
            CORRECT: begin
                tiempo <= tiempo + 1;
                tiempo_in <= 'b0; 
                correcto <= 2'b10;
				data <= CORRECTO;
                punt <= punt + 1;
            end
			WRONG: begin
                buzzer = 'b1;
                tiempo <= tiempo + 1;
				data <= INCORRECTO;
                pun <= punt;
            end

            SUCCES: begin
                tiempo <= tiempo + 1;
                patron_counter <= 'b0;
				data <= COMPLETO;
            end

            COLOR: begin
                tiempo <= tiempo + 1;
                case(temp)
                    2'b00: data <= RED;
                    2'b01: data <= GREEN;
                    2'b10: data <= BLUE;
                    2'b11: data <= YELLOW;
                endcase
            end
        endcase
    end
end

assign enable = clk_16ms;

endmodule
