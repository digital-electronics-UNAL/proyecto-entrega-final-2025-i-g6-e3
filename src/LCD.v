module LCD1604_controller #(parameter NUM_COMMANDS = 4,   // 4 comandos basicos del funcionamiento de la LCD
                                      NUM_DATA_ALL = 32,  
                                      NUM_DATA_PERLINE = 20,
                                      DATA_BITS = 8,
                                      MAX_COUNT = 8,
                                      COUNT_MAX = 800000)(
    input clk,            // Reloj
    input reset,          // Inicio estados 
    input ready_i,       
    input [2:0] mensaje,
    output reg rs,        // Tipo de registro rs=0 "Comando configuracion", rs=1 "Datos"
    output reg rw,        // Accion rw=0 "Escritura", rw=1 "Lectura"
    output enable,    
    output reg [DATA_BITS-1:0] data
);

// Definir los estados de la FSM
localparam IDLE = 4'b0000;
localparam CONFIG_CMD1 = 4'b0001;
localparam WR_STATIC_TEXT_1L = 4'b0010;
localparam WR_DINAMIC_TEXT = 4'b0011;


integer i; 
reg [2:0] fsm_state;
reg [2:0] next_state;
reg [3:0] fsm_sub_state;
reg [3:0] next_sub_state;

reg clk_16ms;

// Comandos de configuración
localparam CLEAR_DISPLAY = 8'h01;
localparam SHIFT_CURSOR_RIGHT = 8'h06;
localparam DISPON_CURSOROFF = 8'h0C;
localparam DISPON_CURSORBLINK = 8'h0E;
localparam LINES2_MATRIX5x8_MODE8bit = 8'h38;
localparam START_2LINE = 8'hC0;

// Definir un contador para el divisor de frecuencia
reg [$clog2(COUNT_MAX)-1:0] clk_counter;
// Definir un contador para controlar el envío de comandos
reg [$clog2(NUM_COMMANDS):0] command_counter;
// Definir un contador para controlar el envío de datos
reg [$clog2(NUM_DATA_PERLINE):0] data_counter;
//definir contador para controlar el envio de datos dinámicos
reg [$clog2(NUM_DATA_PERLINE-1):0] dynamic_data_counter;

reg [5:0] offset;

// Banco de registros
reg [DATA_BITS-1:0] static_data_mem [0: NUM_DATA_PERLINE-1]; // Memoria para los datos estáticos (tamaño)

reg [DATA_BITS-1:0] config_mem [0:NUM_COMMANDS-1]; // Memoria para los comandos de configuración (Cantidad de filas)

reg [DATA_BITS-1:0] pointer_mem [0:NUM_DATA_ALL]; // Memoria para los punteros de datos dinámicos

reg [DATA_BITS-1:0] color_mem [0:40-1]; // Memoria para los datos dinámicos (tamaño)



always @(posedge clk) begin
        pointer_mem[0] <= 8'hC0;
        pointer_mem[1] <= 8'h14; 
        pointer_mem[2] <= 8'h54;
end

initial begin
    fsm_state <= IDLE;
    fsm_sub_state <= 2'b00;
    command_counter <= 'b0;
    data_counter <= 'b0;
    rs <= 1'b0;
    rw <= 1'b0;
    data <= 8'b0;
	 offset <= 'b0;
	 dynamic_data_counter <= 'b0;
    clk_16ms <= 1'b0;
    clk_counter <= 'b0;
    $readmemh("/home/cristhianhendes/Simon dice/Simon-Dice/src/Texto_estatico.txt",static_data_mem);    
    $readmemh("/home/cristhianhendes/Simon dice/Simon-Dice/src/color.txt",color_mem);    
	config_mem[0] <= LINES2_MATRIX5x8_MODE8bit;
	config_mem[1] <= SHIFT_CURSOR_RIGHT;
	config_mem[2] <= DISPON_CURSOROFF;
	config_mem[3] <= CLEAR_DISPLAY;

end





always @(posedge clk) begin // Generación del reloj (divisor de frecuencia)
    if (clk_counter == COUNT_MAX-1) begin
        clk_16ms <= ~clk_16ms;
        clk_counter <= 'b0;
    end else begin
        clk_counter <= clk_counter + 1;
    end
end


always @(posedge clk_16ms)begin //Condición inicial maquina de estados (Transición de estado)
    if(reset == 0)begin
        fsm_state <= IDLE;
    end else begin
        fsm_state <= next_state;
    end
end

always @(*) begin // Lógica combinacional para la transición de estados
    case(fsm_state)
        IDLE: begin
            next_state <= (ready_i)? CONFIG_CMD1 : IDLE;
        end
        CONFIG_CMD1: begin 
            next_state <= (command_counter == NUM_COMMANDS)? WR_STATIC_TEXT_1L : CONFIG_CMD1;
        end
        WR_STATIC_TEXT_1L:begin
			next_state <= (data_counter == NUM_DATA_PERLINE)? WR_DINAMIC_TEXT: WR_STATIC_TEXT_1L;
        end
        default: next_state = WR_DINAMIC_TEXT;
    endcase
end

always @(posedge clk_16ms) begin //
    if (reset == 0) begin
        command_counter <= 'b0;
        data_counter <= 'b0;
		  data <= 'b0;
		  offset <= 0;
        dynamic_data_counter <= 'b0;
		  fsm_sub_state <= 2'b00;
        $readmemh("/home/cristhianhendes/Simon dice/Simon-Dice/src/Texto_estatico.txt", static_data_mem);
        $readmemh("/home/cristhianhendes/Simon dice/Simon-Dice/src/color.txt",color_mem);  
    end else begin
        case (next_state)
            IDLE: begin
                command_counter <= 'b0;
                data_counter <= 'b0;
                rs <= 1'b0;
                data  <= 'b0;
            end
            CONFIG_CMD1: begin
			    rs <= 1'b0; 	
                command_counter <= command_counter + 1;
				data <= config_mem[command_counter];
            end
            WR_STATIC_TEXT_1L: begin
                data_counter <= data_counter + 1;
                rs <= 1'b1; 
				data <= static_data_mem[data_counter];
            end
            WR_DINAMIC_TEXT: begin
                case (next_sub_state)
                    2'b00: begin
                        rs <= 1'b0; 	 
                        data <= 8'hC0;
                        dynamic_data_counter <= 'b0;
                        if (mensaje == 3'b000) begin
                            offset <= 8;
									 next_sub_state <= 2'b01;
                        end else if (mensaje == 3'b001) begin
                            offset <= 16;
									 next_sub_state <= 2'b01;
                        end else if (mensaje == 3'b010) begin
                            offset <= 24;
									 next_sub_state <= 2'b01;
                        end else if (mensaje == 3'b011) begin
                            offset <= 32;
									 next_sub_state <= 2'b01;
                        end else begin
									offset <= 0;
									next_sub_state <= 2'b01;
							end
                    end
                    2'b01:begin
                        rs <= 1'b1; 
                        data <= color_mem[offset + dynamic_data_counter];
                        if (dynamic_data_counter == MAX_COUNT-1) begin
                            next_sub_state <= 2'b00;
									 dynamic_data_counter <= 'b0;
                        end else begin
                            dynamic_data_counter <= dynamic_data_counter + 1;
                        end
                    end
                endcase    
            end
        endcase
    end
end

assign enable = clk_16ms;

endmodule