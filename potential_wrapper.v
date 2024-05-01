module potential_wrapper#(

parameter WIDTH = 32,
parameter DEPTH = 16,
parameter NUM_ARB=6
)
(
input                               clk,
input                               rst,
input [NUM_ARB-1:0]                 read_grant,
input [NUM_ARB-1:0]                 write_grant,
input [$clog2(DEPTH)-1:0]           read_addr0,
input [$clog2(DEPTH)-1:0]           read_addr1,
input [$clog2(DEPTH)-1:0]           read_addr2,
input [$clog2(DEPTH)-1:0]           read_addr3,
input [$clog2(DEPTH)-1:0]           read_addr4,
input [$clog2(DEPTH)-1:0]           read_addr5,

input [$clog2(DEPTH)-1:0]           write_addr0,
input [$clog2(DEPTH)-1:0]           write_addr1,
input [$clog2(DEPTH)-1:0]           write_addr2,
input [$clog2(DEPTH)-1:0]           write_addr3,
input [$clog2(DEPTH)-1:0]           write_addr4,
input [$clog2(DEPTH)-1:0]           write_addr5,

input signed[WIDTH-1:0]                   write_data0,
input signed[WIDTH-1:0]                   write_data1,
input signed[WIDTH-1:0]                   write_data2,
input signed[WIDTH-1:0]                   write_data3,
input signed[WIDTH-1:0]                   write_data4,
input signed[WIDTH-1:0]                   write_data5,

output signed[WIDTH-1:0]                   read_data,
output reg                          flag_out,
output [$clog2(DEPTH)-1:0]          Read_Addr,
output [$clog2(DEPTH)-1:0]          Write_Addr

);
reg signed[WIDTH-1:0]                     write_data;
reg [$clog2(DEPTH)-1:0]             write_addr;
reg [$clog2(DEPTH)-1:0]             read_addr;
reg [0:0] flag [DEPTH-1:0];

integer i;

always@(*)
begin
  case(read_grant)
   6'b000001:read_addr=read_addr0; 
   6'b000010:read_addr=read_addr1;
   6'b000100:read_addr=read_addr2;  
   6'b001000:read_addr=read_addr3;
   6'b010000:read_addr=read_addr4;
   6'b100000:read_addr=read_addr5;
   default:read_addr='b0;
 endcase
end

always@(*)
begin
  case(write_grant)
   6'b000001:write_addr=write_addr0; 
   6'b000010:write_addr=write_addr1;
   6'b000100:write_addr=write_addr2;  
   6'b001000:write_addr=write_addr3;
   6'b010000:write_addr=write_addr4;
   6'b100000:write_addr=write_addr5;
   default:write_addr='b0;
 endcase
end

always@(*)
begin
  case(write_grant)
   6'b000001:write_data=write_data0; 
   6'b000010:write_data=write_data1;
   6'b000100:write_data=write_data2;  
   6'b001000:write_data=write_data3;
   6'b010000:write_data=write_data4;
   6'b100000:write_data=write_data5;
   default:write_data='b0;
 endcase
end

potential_mem#(      //fake dual port
.WIDTH  (WIDTH),
.DEPTH  (DEPTH))
p_mem
(
.clk          (clk),
.rst          (rst),
.read_en      (|read_grant),
.read_addr    (read_addr), 	
.write_en     (|write_grant),
.write_addr   (write_addr),
.write_data   (write_data),	
.read_data    (read_data)
);

always@(posedge clk or negedge rst)
begin
  if(!rst)
  begin
    for(i=0;i<DEPTH;i=i+1)
      flag[i]<=1'b1;
  end
  else if((write_addr==read_addr)&&((|write_grant)&&(|read_grant)))
  begin
    flag[write_addr]<=1'b1;
  end
  else if((write_addr!=read_addr)&&((|write_grant)&&(|read_grant)))
  begin
    flag[write_addr]<=1'b1;
    flag[read_addr]<=1'b0;
  end
  else
  begin
    if(|write_grant)
      flag[write_addr]<=1'b1;
    else if(|read_grant)
      flag[read_addr]<=1'b0;
  end
end

always@(*)
begin
  if(|read_grant)
  begin
  flag_out=flag[read_addr];
  end
  else
  begin
  flag_out=1'b0;
  end
end

assign Read_Addr = read_addr;
assign Write_Addr = write_addr;

endmodule
