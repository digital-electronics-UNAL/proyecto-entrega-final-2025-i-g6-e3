module LFSR (
    input wire clk,
    input wire rst,
    output reg [1:0] rnd
);

initial begin
    rnd <= 2'b01;  // semilla inicial distinta de 00
end

always @(posedge clk or posedge rst) begin
    if (rst)
        rnd <= 2'b01;  // semilla inicial distinta de 00
    else begin
        // feedback: XOR de los dos bits
        // taps: [1] y [0]
        rnd <= {rnd[0], rnd[1] ^ rnd[0]};
    end
end

endmodule