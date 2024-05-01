module cluster#(
parameter I_I = 5, //reg width for I
parameter I_J = 5, //reg width for J
parameter I_K = 5, //reg width for K
parameter I_T = 5, //reg width for T /Timestamp
parameter K_I = 5, //reg width of inputmap kernel I
parameter K_J = 5, //reg width of inputmap kernel J
parameter K_K = 5,
parameter MAX_KERNEL_NUM             = 16,
parameter BASE_ADDR_WIDTH = 32, //BASE ADDR REG Width
parameter DEPTH           = 16, //input fifo depth
parameter WIDTH           = 32,
parameter i_width         = 5,
parameter j_width         = 5,
parameter k_width         = 5,
parameter l_width         = 5,
parameter WEIGHT_WIDTH    = 16,
parameter POTENTIAL_WIDTH = 32,
parameter WEIGHT_DEPTH    = 32, 
parameter POTENTIAL_DEPTH = 729,
parameter NUM_ARB         = 6,
parameter PE_NUM          = 4,
parameter POST_WIDTH      = 32

)
(
input                                potential_read_en,
input                                potential_write_en,
input [$clog2(POTENTIAL_DEPTH)-1:0]  potential_raddr_cluster,
input [$clog2(POTENTIAL_DEPTH)-1:0]  potential_waddr_cluster,
input signed[POTENTIAL_WIDTH*MAX_KERNEL_NUM-1:0]      potential_wdata_cluster,
input clk,
input rst,
input [PE_NUM-1:0]start,
input signed[POTENTIAL_WIDTH-1:0] threhold,
input signed[POTENTIAL_WIDTH-1:0] rest_value,
input [2:0]working_mode,
input signed[31:0]w_data,
input signed[31:0]w_value,
input [PE_NUM-1:0] w_mem_wen,
input [WEIGHT_WIDTH*MAX_KERNEL_NUM-1:0]w_mem_wdata, 
input [$clog2(WEIGHT_DEPTH)-1:0]w_mem_waddr,
input [K_I-1:0] k_i,//size of kernel
input [K_J-1:0] k_j,
input [I_I-1:0] i_i,//size of input data
input [I_J-1:0] i_j,
input [BASE_ADDR_WIDTH-1:0] base_addr,
input post_grant,
input pre_grant,
input [POST_WIDTH-1:0] post_addr,
input [POTENTIAL_WIDTH-1:0] output_neuron_num,
input [I_T-1:0] timestamp,
input  start_sche,
output [POST_WIDTH-1:0] post_waddr,
output [POST_WIDTH-1:0] post_wdata,
output [PE_NUM-1:0]finish,
output post_req,
output [4*$clog2(POTENTIAL_DEPTH)-1:0]  Potential_raddr,
output [4*$clog2(POTENTIAL_DEPTH)-1:0]  Potential_waddr,
output [4*POTENTIAL_WIDTH*MAX_KERNEL_NUM-1:0]      Potential_wdata,
output [4*POTENTIAL_WIDTH*MAX_KERNEL_NUM-1:0]      Potential_rdata,
output [NUM_ARB-1:0]                  Read_req,
output [NUM_ARB-1:0]                  Write_req,
output [NUM_ARB-1:0]                  Read_grant,
output flagout,
output [$clog2(DEPTH)-1:0]          Read_Addr,
output [$clog2(DEPTH)-1:0]          Write_Addr,
output [3:0] PE_grant,
output [POTENTIAL_WIDTH*MAX_KERNEL_NUM-1:0]      Read_data,
output finish_sche,
output [POTENTIAL_WIDTH*MAX_KERNEL_NUM-1:0]potential_wdata1,
output [$clog2(POTENTIAL_DEPTH)-1:0]  potential_waddr1


);

reg [NUM_ARB-1:0] read_grant_reg;
reg [4:0] PE_finish_reg;
wire [$clog2(POTENTIAL_DEPTH)-1:0]  potential_raddr [PE_NUM-1:0];
wire [$clog2(POTENTIAL_DEPTH)-1:0]  potential_waddr [PE_NUM-1:0];
wire [POTENTIAL_WIDTH*MAX_KERNEL_NUM-1:0]      potential_wdata [PE_NUM-1:0];
wire [POTENTIAL_WIDTH*MAX_KERNEL_NUM-1:0]      potential_rdata [PE_NUM-1:0];
wire [POTENTIAL_WIDTH*MAX_KERNEL_NUM-1:0]      potential_wdata_sche;
wire [$clog2(POTENTIAL_DEPTH)-1:0]  potential_raddr_sche;
wire [$clog2(POTENTIAL_DEPTH)-1:0]  potential_waddr_sche;

wire [NUM_ARB-1:0]                  read_req;
wire [NUM_ARB-1:0]                  read_grant;
wire [NUM_ARB-1:0]                  write_req;
wire [NUM_ARB-1:0]                  write_grant;
wire                                read_req_pe     [PE_NUM-1:0];
wire                                write_req_pe    [PE_NUM-1:0];
wire                                read_req_sche;
wire                                write_req_sche;
wire                                flag_out;
wire [POTENTIAL_WIDTH*MAX_KERNEL_NUM-1:0]      read_data;
wire fifo_full[PE_NUM-1:0];
wire [PE_NUM-1:0] write_en_wire;
wire signed[31:0] input_data_wire;


//always@(posedge clk or negedge rst)    
//begin
//  if(!rst)
//  begin
//    PE_finish_reg <= 4'b0000;
//  end
//  else
//  begin
//    PE_finish_reg[0]=finish[0]|PE_finish_reg[0];
//    PE_finish_reg[1]=finish[1]|PE_finish_reg[1];
//    PE_finish_reg[2]=finish[2]|PE_finish_reg[2];
//    PE_finish_reg[3]=finish[3]|PE_finish_reg[3];
//  end

//  if(finish_sche) begin
//    PE_finish_reg<=0;
//  end
  
//end

//assign start_sche = (PE_finish_reg==4'b1111)?1'b1:1'b0;
assign potential_waddr1 = potential_waddr[0];
assign potential_wdata1 = potential_wdata1[0];
assign Potential_raddr = {potential_raddr[0],potential_raddr[1],potential_raddr[2],potential_raddr[3]};
assign Potential_waddr = {potential_waddr[0],potential_waddr[1],potential_waddr[2],potential_waddr[3]};
assign Read_req = read_req;
assign Write_req  = write_req;
assign Read_grant = read_grant_reg;
assign flagout = flag_out;
assign PE_grant = {read_grant[4],read_grant[3],read_grant[2],read_grant[1]};
assign Read_data = read_data;
genvar i;

always@(posedge clk or negedge rst)
begin
  if(!rst)
    read_grant_reg<='b0;
  else
    read_grant_reg<=read_grant;
end

generate//??4?PE
  for(i=0;i<PE_NUM;i=i+1)
  begin: pe_inst
    pe#(
    .I_I              (I_I            ), //data width of input data
    .I_J              (I_J            ),
    .I_K              (I_K            ),
    .I_T              (I_T            ),
    .K_I              (K_I            ), //data width of kernel
    .K_J              (K_J            ),
    .K_K              (K_K            ),
    .MAX_KERNEL_NUM   (MAX_KERNEL_NUM ),
    .BASE_ADDR_WIDTH  (BASE_ADDR_WIDTH),
    .DEPTH            (DEPTH          ),
    .WIDTH            (WIDTH          ),
    .i_width          (i_width        ),
    .j_width          (j_width        ),
    .k_width          (k_width        ),
    .l_width          (l_width        ),
    .WEIGHT_WIDTH     (WEIGHT_WIDTH   ), 
    .POTENTIAL_WIDTH  (POTENTIAL_WIDTH), 
    .WEIGHT_DEPTH     (WEIGHT_DEPTH   ), 
    .POTENTIAL_DEPTH  (POTENTIAL_DEPTH)

    )
    pe_inst
    (
    .clk               (clk),
    .rst               (rst),
    .start             (start[i]),
    .working_mode      (working_mode),
    .read_grant        (read_grant[i+1]&&flag_out), //read_grant[0] -> cluster
    .write_grant       (write_grant[i+1]),
    .write_en          (write_en_wire[i]),
    .w_data            (input_data_wire),
    .w_value           (w_value),
    .w_mem_wen         (w_mem_wen[i]),
    .w_mem_wdata       (w_mem_wdata),
    .w_mem_waddr       (w_mem_waddr),
    .k_i               (k_i),//size of kernel
    .k_j               (k_j),
    .i_i               (i_i),//size of input data
    .i_j               (i_j),
    .base_addr         (base_addr),
    .potential_rdata   (potential_rdata[i]),
    .potential_raddr   (potential_raddr[i]),
    .potential_waddr   (potential_waddr[i]), 
    .potential_wdata   (potential_wdata[i]),
    .read_req          (read_req_pe[i]),
    .write_req         (write_req_pe[i]),
    .finish            (finish[i]),
    .Fifo_full         (fifo_full[i]),
    .output_neuron_num (output_neuron_num)
    );
  end
endgenerate

assign potential_rdata[0]=read_grant_reg[1]?read_data:'b0;
assign potential_rdata[1]=read_grant_reg[2]?read_data:'b0;
assign potential_rdata[2]=read_grant_reg[3]?read_data:'b0;
assign potential_rdata[3]=read_grant_reg[4]?read_data:'b0;


potential_wrapper#(
.WIDTH (POTENTIAL_WIDTH*MAX_KERNEL_NUM),
.DEPTH (POTENTIAL_DEPTH),
.NUM_ARB(NUM_ARB)
)potential_inst
(
.clk              (clk),
.rst              (rst),
.read_grant       (read_grant),
.write_grant      (write_grant),
.read_addr0       (potential_raddr_cluster),
.read_addr1       (potential_raddr[0]),
.read_addr2       (potential_raddr[1]),
.read_addr3       (potential_raddr[2]),
.read_addr4       (potential_raddr[3]),
.read_addr5       (potential_raddr_sche),

.write_addr0      (potential_waddr_cluster),
.write_addr1      (potential_waddr[0]),
.write_addr2      (potential_waddr[1]),
.write_addr3      (potential_waddr[2]),
.write_addr4      (potential_waddr[3]),
.write_addr5      (potential_waddr_sche),

.write_data0      (potential_wdata_cluster),
.write_data1      (potential_wdata[0]),
.write_data2      (potential_wdata[1]),
.write_data3      (potential_wdata[2]),
.write_data4      (potential_wdata[3]),
.write_data5      (potential_wdata_sche),

.read_data        (read_data),
.flag_out         (flag_out),
.Write_Addr       (Write_Addr),
.Read_Addr        (Read_Addr)
);

assign read_req={read_req_sche,read_req_pe[3],read_req_pe[2],read_req_pe[1],read_req_pe[0],potential_read_en};
assign write_req={write_req_sche,write_req_pe[3],write_req_pe[2],write_req_pe[1],write_req_pe[0],potential_write_en};


arb #(.num_arb (NUM_ARB))
arb_inst_read
(
 .clk     (clk),
 .rst     (rst),
 .req     (read_req),
 .grant   (read_grant)
);

arb #(.num_arb (NUM_ARB))
arb_inst_write
(
 .clk     (clk),
 .rst     (rst),
 .req     (write_req),
 .grant   (write_grant)
);

scheduler #(
.POTENTIAL_WIDTH   (POTENTIAL_WIDTH),//4*12
.POTENTIAL_DEPTH   (POTENTIAL_DEPTH),
.PE_NUM            (PE_NUM),
.I_I               (I_I), //data width of input data
.I_J               (I_J),
.I_T               (I_T),
.K_I               (K_I), //data width of kernel
.K_J               (K_J),
.K_K               (K_K),
.MAX_KERNEL_NUM    (MAX_KERNEL_NUM),//width of kernel num(max=12)
.POST_WIDTH        (POST_WIDTH) 
)
scheduler_inst(
.clk                  (clk),
.rst                  (rst),
.start_sche           (start_sche),
.threhold             (threhold),
.rest_value           (rest_value),
.k_i                  (k_i),//size of kernel
.k_j                  (k_j),
.i_i                  (i_i),//size of input data
.i_j                  (i_j),
.read_grant           (read_grant[5]),
.write_grant          (write_grant[5]),
.post_grant           (post_grant),
.post_addr            (post_addr),
.potential_rdata      (read_data),
.potential_raddr      (potential_raddr_sche),
.potential_wdata      (potential_wdata_sche),
.potential_waddr      (potential_waddr_sche),
.read_req             (read_req_sche),   
.write_req            (write_req_sche),  
.post_waddr           (post_waddr),    
.post_wdata           (post_wdata),
.post_req             (post_req),
.finish_sche          (finish_sche),
.working_mode         (working_mode),
.output_neuron_num    (output_neuron_num),
.timestamp            (timestamp)
);


Workload_manager # (
    .I_I(I_I),
    .I_J(I_J),
    .I_K(I_K),
    .I_T(I_T),
    .PE_NUM(PE_NUM)
  )
  Workload_manager_inst (
    .clk(clk),
    .rst(rst),
    .working_mode(working_mode),
    .r_data(w_data),
    .req(pre_grant),
    .fifo_full_0(fifo_full[0]),
    .fifo_full_1(fifo_full[1]),
    .fifo_full_2(fifo_full[2]),
    .fifo_full_3(fifo_full[3]),

    
    .write_en(write_en_wire),
    .w_data(input_data_wire)
  );



endmodule
