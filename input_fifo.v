module input_fifo#(
parameter DEPTH = 16,
parameter WIDTH = 32)
(
input                  clk,
input                  rst,
input                  write_en,
input                  read_en,
input      [WIDTH-1:0] w_data,
output reg signed [WIDTH-1:0] r_data,
output                 full,
output                 empty
);

reg signed[WIDTH-1:0] mem [DEPTH-1:0];
reg [$clog2(DEPTH):0] w_pointer;
reg [$clog2(DEPTH):0] r_pointer;

integer i;

always@(posedge clk or negedge rst)
begin
  if(!rst)
  begin
    w_pointer<='b0;
  end
  else if(write_en&&!full)
  begin
    w_pointer<=w_pointer+1'b1;
  end
  else
  begin
    w_pointer<=w_pointer;
  end
end

always@(posedge clk or negedge rst)
begin
  if(!rst)
  begin
    r_pointer<='b0;
  end
  else if(read_en&&!empty)
  begin
    r_pointer<=r_pointer+1'b1;
  end
  else
  begin
    r_pointer<=r_pointer;
  end
end

always@(posedge clk or negedge rst)
begin 
  if(!rst)
  begin
    for(i=0;i<DEPTH;i=i+1)
		begin
			mem[i]<='b0;
		end
  end
  else
  begin
    if(write_en&&!full)
    begin
      mem[w_pointer]<=w_data;
    end
  end
end

always@(*)
begin
  if(read_en&&!empty)
  begin
    r_data=mem[r_pointer[$clog2(DEPTH)-1:0]];
  end
  else
  begin
    r_data=r_data;
  end
end

assign full=((w_pointer[$clog2(DEPTH)]!=r_pointer[$clog2(DEPTH)])&&(w_pointer[$clog2(DEPTH)-1:0]==r_pointer[$clog2(DEPTH)-1:0]));//??????&&??????
assign empty=(w_pointer==r_pointer);

endmodule
