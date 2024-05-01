module mem#(           //single port  
parameter WIDTH = 16,//width*max_kernel
parameter DEPTH = 25)//5*5inputmap
(
    input clk,
    input rst,
	  input write_en,
	  input [$clog2(DEPTH)-1:0]write_addr,
	  input [WIDTH-1:0]write_data,	
	  input read_en,
	  input [$clog2(DEPTH)-1:0]read_addr,
	  output reg [WIDTH-1:0]read_data
);
//*************code***********//
reg [WIDTH-1:0] ram [DEPTH-1:0];
integer i;

always@(posedge clk or negedge rst)
begin
	if(!rst)
	begin
		read_data<='b0;
		for(i=0;i<DEPTH;i=i+1)
		begin
			ram[i]<='b0;
		end
	end
	else
	begin
		if(write_en)
		ram[write_addr]<=write_data;
		else if(read_en)
		read_data<=ram[read_addr];
	end
end
//*************code***********//
endmodule


