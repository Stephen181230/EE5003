module potential_mem#(      //fake dual port sdfa

parameter WIDTH = 32,
parameter DEPTH = 16)
(
    input clk,
    input rst,
	input read_en,
	input [$clog2(DEPTH)-1:0] read_addr,	
    input                     write_en,
	input [$clog2(DEPTH)-1:0] write_addr,
	input [WIDTH-1:0]         write_data,	
	output reg signed[WIDTH-1:0]    read_data
);
//*************code***********//
reg signed[WIDTH-1:0] ram [DEPTH-1:0];
integer i;

always@(posedge clk or negedge rst)
begin
	if(!rst)
	begin
		read_data<='b0;
	end
	else
	begin
		if(read_en)
		read_data<=ram[read_addr];
    else
    read_data<=read_data;
	end
end

always@(posedge clk or negedge rst)
begin
  if(!rst)
  begin
    for(i=0;i<DEPTH;i=i+1)
		begin
			ram[i]<='b0;
		end
  end
  else
  begin
	  if(write_en)
	  ram[write_addr]<=write_data;
	  else
    ram[write_addr]<=ram[write_addr];
  end
end

//*************code***********//
endmodule


