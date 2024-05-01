`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/17/2024 04:04:19 PM
// Design Name: 
// Module Name: workload_manager
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Workload_manager#(
parameter I_I = 5, //reg width for I
parameter I_J = 5, //reg width for J
parameter I_K = 5, //reg width for K
parameter I_T = 5, //reg width for T
parameter PE_NUM = 4
)
(
    input clk,
    input rst,
    input [2:0] working_mode,
    input [31:0] r_data,
    input req,
    input  fifo_full_0,
    input  fifo_full_1,
    input  fifo_full_2,
    input  fifo_full_3,
    
    output reg [PE_NUM-1:0] write_en,
    output [31:0] w_data
    );
    
    localparam IDLE = 2'b00;
    localparam READ = 2'b01;
    localparam WAIT = 2'b10;
    localparam WRITE = 2'b11;
    
reg [1:0] cs;
reg [1:0] ns;
reg [PE_NUM-1:0] sel_PE;
reg [3:0] fifo_req;
wire [3:0] fifo_grant;
wire [3:0] fifo_wrapper;

assign w_data = (working_mode[2:1]==2'b00)?r_data:(r_data/PE_NUM);
assign fifo_wrapper = {!fifo_full_0,!fifo_full_1,!fifo_full_2,!fifo_full_3};
always@(posedge clk or negedge rst)
begin
  if(!rst)
  begin
    cs<=IDLE;
  end
  else
  begin
    cs<=ns;
  end
end

always@(*)
begin
    case(cs)
        IDLE:ns<=READ;
               
        READ:begin
            case(working_mode[2:1])
                 2'b00:ns<=req?WAIT:READ;
                 default:begin
                    if(req)begin
                        case(r_data%PE_NUM)
                            0:ns<=fifo_full_0?READ:WAIT;
                            1:ns<=fifo_full_1?READ:WAIT;
                            2:ns<=fifo_full_2?READ:WAIT;                          
                            3:ns<=fifo_full_3?READ:WAIT;     
                            default:ns<=READ;
                        endcase
                    end
                    else begin
                        ns<=READ;
                    end
                 end
            endcase
        end
        
        WAIT:ns<=WRITE;
        
        WRITE:ns<=READ;

    endcase
end

always@(posedge clk or negedge rst)begin
    if(!rst)begin
        fifo_req <= 0;
        sel_PE <= 0;
    end
    else begin
        case(cs)
            READ:begin
                case(working_mode[2:1])
                    2'b00:begin
                        fifo_req<=req?fifo_wrapper:4'b0000;                        
                    end                       
                    default:begin
                        sel_PE <= 0;                        
                    end                    
                endcase
            end
            
            WAIT:begin
                 case(working_mode[2:1])
                    2'b00:begin
                        fifo_req<=0;
                    end                    
                    default:begin
                        case(r_data%PE_NUM)
                            0:sel_PE <= 4'b0001;
                            1:sel_PE <= 4'b0010;
                            2:sel_PE <= 4'b0100;
                            3:sel_PE <= 4'b1000;
                            default:sel_PE <= 4'b0000;
                        endcase
                    end  
                   
                endcase
            end
            
            WRITE:begin
                 case(working_mode[2:1])
                    2'b00:begin
                        fifo_req<=0;
                    end                   
                    default:begin
                        sel_PE<=0;
                    end                  
                endcase           
            end
        endcase          
    end
end

always@(*)begin
    if(!rst)begin
        write_en = 0;
    end
    else begin
        if(working_mode[2:1]==2'b00)begin
            write_en = fifo_grant;
        end
        else begin
            write_en = sel_PE;
        end
    end
end

rr_arbiter  rr_arb_inst (
    .clk(clk),
    .rst(rst),
    .req(fifo_req),
    .grant(fifo_grant)
  );
  
endmodule
