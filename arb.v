module arb #(parameter num_arb=6)
(
input                clk,
input                rst,
input  	  [num_arb-1:0] req,
output reg [num_arb-1:0] grant
);

reg [3*num_arb-1:0] cur_pri;
reg [num_arb-1:0]   req_temp;
reg [num_arb-1:0]   grant_temp;

always@(posedge clk or negedge rst)
begin
	if(!rst)
	begin
		cur_pri<=18'b101_100_011_010_001_000;
	end
	else
	begin
	case(grant_temp) //????grant_temp???grant,grant??????????????????????
		6'b000001:cur_pri<={cur_pri[2:0],cur_pri[17:3]};
		6'b000010:cur_pri<={cur_pri[5:3],cur_pri[17:6],cur_pri[2:0]};
	    6'b000100:cur_pri<={cur_pri[8:6],cur_pri[17:9],cur_pri[5:0]};
		6'b001000:cur_pri<={cur_pri[11:9],cur_pri[17:12],cur_pri[8:0]};
		6'b010000:cur_pri<={cur_pri[14:12],cur_pri[17:15],cur_pri[11:0]};
		6'b100000:cur_pri<=cur_pri;
		default:cur_pri<=cur_pri;
		endcase
	end
end

always@(*)
begin
	case(cur_pri[2:0])
	3'b000:req_temp[0]=req[0];
    3'b001:req_temp[0]=req[1];
	3'b010:req_temp[0]=req[2];
	3'b011:req_temp[0]=req[3];
    3'b100:req_temp[0]=req[4];
    3'b101:req_temp[0]=req[5];
	default:req_temp[0]=0;
	endcase
end
always@(*)
begin
	case(cur_pri[5:3])
	3'b000:req_temp[1]=req[0];
    3'b001:req_temp[1]=req[1];
	3'b010:req_temp[1]=req[2];
	3'b011:req_temp[1]=req[3];
    3'b100:req_temp[1]=req[4];
    3'b101:req_temp[1]=req[5];
	default:req_temp[1]=0;
	endcase
end
always@(*)
begin
	case(cur_pri[8:6])
	3'b000:req_temp[2]=req[0];
    3'b001:req_temp[2]=req[1];
	3'b010:req_temp[2]=req[2];
	3'b011:req_temp[2]=req[3];
    3'b100:req_temp[2]=req[4];
    3'b101:req_temp[2]=req[5];
	default:req_temp[2]=0;
	endcase
end
always@(*)
begin
	case(cur_pri[11:9])
	3'b000:req_temp[3]=req[0];
    3'b001:req_temp[3]=req[1];
	3'b010:req_temp[3]=req[2];
	3'b011:req_temp[3]=req[3];
    3'b100:req_temp[3]=req[4];
    3'b101:req_temp[3]=req[5];
	default:req_temp[3]=0;
	endcase
end
always@(*)
begin
	case(cur_pri[14:12])
	3'b000:req_temp[4]=req[0];
    3'b001:req_temp[4]=req[1];
	3'b010:req_temp[4]=req[2];
	3'b011:req_temp[4]=req[3];
    3'b100:req_temp[4]=req[4];
    3'b101:req_temp[4]=req[5];
	default:req_temp[4]=0;
	endcase
end
always@(*)
begin
	case(cur_pri[17:15])
	3'b000:req_temp[5]=req[0];
    3'b001:req_temp[5]=req[1];
	3'b010:req_temp[5]=req[2];
	3'b011:req_temp[5]=req[3];
    3'b100:req_temp[5]=req[4];
    3'b101:req_temp[5]=req[5];
	default:req_temp[5]=0;
	endcase
end


always@(*)
begin
	if(req_temp[0])
	grant_temp=6'b000001;
	else if(req_temp[1])
	grant_temp=6'b000010;
	else if(req_temp[2])
	grant_temp=6'b000100;
	else if(req_temp[3])
	grant_temp=6'b001000;
	else if(req_temp[4])
	grant_temp=6'b010000;
	else if(req_temp[5])
	grant_temp=6'b100000;
    else
	grant_temp=6'b000000;
end


//grant = ?
always@(*)
begin
	case(grant_temp)
	6'b000001:case(cur_pri[2:0])
					3'b000:grant=6'b000001;
					3'b001:grant=6'b000010;
					3'b010:grant=6'b000100;
				    3'b011:grant=6'b001000;
					3'b100:grant=6'b010000;
			        3'b101:grant=6'b100000;
					default:grant=6'b000000;
					endcase
	6'b000010:case(cur_pri[5:3])
					3'b000:grant=6'b000001;
					3'b001:grant=6'b000010;
					3'b010:grant=6'b000100;
				    3'b011:grant=6'b001000;
					3'b100:grant=6'b010000;
			        3'b101:grant=6'b100000;
					default:grant=6'b000000;
					endcase
	6'b000100:case(cur_pri[8:6])
					3'b000:grant=6'b000001;
					3'b001:grant=6'b000010;
					3'b010:grant=6'b000100;
				    3'b011:grant=6'b001000;
					3'b100:grant=6'b010000;
			        3'b101:grant=6'b100000;
					default:grant=6'b000000;
					endcase
	6'b001000:case(cur_pri[11:9])
					3'b000:grant=6'b000001;
					3'b001:grant=6'b000010;
					3'b010:grant=6'b000100;
				    3'b011:grant=6'b001000;
					3'b100:grant=6'b010000;
			        3'b101:grant=6'b100000;
					default:grant=6'b000000;
					endcase
	6'b010000:case(cur_pri[14:12])
					3'b000:grant=6'b000001;
					3'b001:grant=6'b000010;
					3'b010:grant=6'b000100;
				    3'b011:grant=6'b001000;
					3'b100:grant=6'b010000;
			        3'b101:grant=6'b100000;
					default:grant=6'b000000;
					endcase
	6'b100000:case(cur_pri[17:15])
					3'b000:grant=6'b000001;
					3'b001:grant=6'b000010;
					3'b010:grant=6'b000100;
				    3'b011:grant=6'b001000;
					3'b100:grant=6'b010000;
			        3'b101:grant=6'b100000;
					default:grant=6'b000000;
					endcase
	default:grant=6'b0;
	endcase
end

endmodule
