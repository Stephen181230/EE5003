module gelu_4(
    input signed [31:0] x,
    output reg signed [31:0] y
);

localparam signed [31:0] COEF_A1 = 32'b0000000000000000_0000001011011110; // 0.0112 * 2^16
localparam signed [31:0] COEF_A2 = 32'b0000000000000001_0001100101011000; // 1.099 * 2^16
localparam signed [31:0] COEF_A3 = 32'b0000000000000000_0001010000001011; // 0.0783 * 2^16
localparam signed [31:0] COEF_B1 = 32'b0000000000000000_0000011111000001; // 0.0303 * 2^16
localparam signed [31:0] COEF_B2 = 32'b0000000000000000_0000000010111110; // 0.0029 * 2^16
localparam signed [31:0] COEF_B3 = 32'b0000000000000000_0101100001001011; // 0.3449 * 2^16
localparam signed [31:0] COEF_B4 = 32'b0000000000000000_1000001101011010; // 0.5131 * 2^16
localparam signed [31:0] COEF_B5 = 32'b0000000000000000_0100111100010100; // 0.3089 * 2^16
localparam signed [31:0] COEF_C1 = 32'b0000000000000000_0000001101001000; // 0.01282 * 2^16
localparam signed [31:0] COEF_C2 = 32'b0000000000000000_0001110100100001; // 0.1138 * 2^16
localparam signed [31:0] COEF_C3 = 32'b0000000000000000_0000101110001010; // 0.04508 * 2^16
localparam signed [31:0] OFFSET_03 = 32'd19660; // 0.3 * 2^16

wire signed [63:0] temp1;
wire signed [63:0] temp2;
wire signed [63:0] temp3;


assign temp1 = x * x >> 16; //square
assign temp2 = temp1 * x >>16; // cube
assign temp3 = temp2 * x >>16; // 4th

always @(x) begin
    if (x >= 131072 && x <= 327680) begin // 2 <= x <= 5
        y = (COEF_A2 * x >>16)-(COEF_A1 * temp1 >>16) + COEF_A3;
    end else if (x<=131072 && x>=-131072) begin // -2 <= x <= 2
        y =  COEF_B5 + (COEF_B4 * x >> 16) + (COEF_B3 * temp1 >> 16) - (COEF_B2 * temp2 >> 16) - (COEF_B1 * temp3 >> 16);
    end else if (x >= -327680 && x <= -131072) begin // -5 <= x <= -2
        y =  COEF_C3 - (COEF_C2 * x >> 16) - (COEF_C1 * temp1 >> 16);
    end else if (x > 327680) begin // x > 5
        y = x + OFFSET_03; 
    end else begin
        y = OFFSET_03; 
    end
end

endmodule
