`timescale 1ns / 1ps

module rr_arbiter(
    input clk,
    input rst,
    input [3:0] req,
    output reg [3:0] grant
);

reg [1:0] priority; // Current priority

always @(posedge clk or negedge rst) begin
    if (!rst) begin
        grant <= 4'b0000;
        priority <= 2'b00;
    end else begin
        // Rotate the priority based on the last grant.
        if (grant[0]) priority <= 2'b01;
        else if (grant[1]) priority <= 2'b10;
        else if (grant[2]) priority <= 2'b11;
        else if (grant[3]) priority <= 2'b00;

        // Decide on the next grant based on the rotated priority.
        case (priority)
            2'b00: grant <= (req[0]) ? 4'b0001 :
                           (req[1]) ? 4'b0010 :
                           (req[2]) ? 4'b0100 :
                           (req[3]) ? 4'b1000 : 4'b0000;
            2'b01: grant <= (req[1]) ? 4'b0010 :
                           (req[2]) ? 4'b0100 :
                           (req[3]) ? 4'b1000 :
                           (req[0]) ? 4'b0001 : 4'b0000;
            2'b10: grant <= (req[2]) ? 4'b0100 :
                           (req[3]) ? 4'b1000 :
                           (req[0]) ? 4'b0001 :
                           (req[1]) ? 4'b0010 : 4'b0000;
            2'b11: grant <= (req[3]) ? 4'b1000 :
                           (req[0]) ? 4'b0001 :
                           (req[1]) ? 4'b0010 :
                           (req[2]) ? 4'b0100 : 4'b0000;
            default: grant <= 4'b0000; // Default case, should not be reached
        endcase
    end
end

endmodule
