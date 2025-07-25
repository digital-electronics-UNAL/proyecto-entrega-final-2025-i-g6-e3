module LFSR (
    input wire clk,
    input wire rst,
    output reg [1:0] rnd
);

reg clk_16ms;

initial begin
    rnd <= 2'b01;  // semilla inicial distinta de 00
    clk_counter <= 'b0;
    clk_16ms <= 'b0;
end

reg [$clog2(500)-1:0] clk_counter;

always @(posedge clk) begin // Generación del reloj (divisor de frecuencia)
    if (clk_counter == 500) begin
        clk_16ms <= ~clk_16ms;
        clk_counter <= 'b0;
    end else begin
        clk_counter <= clk_counter + 1;
    end
end

always @(posedge clk or posedge rst) begin
    if (rst)
        rnd <= 2'b01;  // semilla inicial distinta de 00
    else begin
        // feedback: XOR de los dos bits
        // taps: [1] y [0]
        rnd <= {rnd[0], clk_16ms ^ rnd[1]};
    end
end

endmodule