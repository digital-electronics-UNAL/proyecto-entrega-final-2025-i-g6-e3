module  RANG #(parameter MENS_BITS = 4,
                        PUN_BITS = 7)(          
    input [MENS_BITS-1:0] data,
    input [PUN_BITS-1:0] pun,
    output reg [PUN_BITS-1:0] mpun,
    output reg [PUN_BITS-1:0] apun
);

localparam PUN = 4'b1000;

reg [PUN_BITS-1:0] mej_pun;
reg [PUN_BITS-1:0] ant_pun;

initial begin
end

always @(*) begin
    if (data == PUN) begin
        if (pun < mej_pun) begin
            mej_pun <= pun;
            ant_pun <= pun;
        end else begin
            mej_pun <= mej_pun;
            ant_pun <= pun;
        end
    end 
end

endmodule
