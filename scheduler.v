module scheduler#(
parameter POTENTIAL_WIDTH   = 32,
parameter POTENTIAL_DEPTH   = 64,
parameter PE_NUM = 4,
parameter I_I = 5, //data width of input data
parameter I_J = 5,
parameter I_T = 5,
parameter K_I = 5, //data width of kernel
parameter K_J = 5,
parameter K_K = 1,
parameter MAX_KERNEL_NUM = 16,
parameter POST_WIDTH        = 32
)
(
input                                 clk,
input                                 rst,
input                                 start_sche,
input   [POTENTIAL_WIDTH-1:0]         threhold,
input   [POTENTIAL_WIDTH-1:0]         rest_value,
input   [K_I-1:0]                     k_i,//size of kernel
input   [K_J-1:0]                     k_j,
input   [I_I-1:0]                     i_i,//size of input data
input   [I_J-1:0]                     i_j,
input                                 read_grant,
input                                 write_grant,
input                                 post_grant,
input   [POST_WIDTH-1:0]              post_addr,
input   [POTENTIAL_WIDTH*MAX_KERNEL_NUM-1:0]     potential_rdata,
// for FC
input   [2:0]                         working_mode,
input   [15:0]                        output_neuron_num,
input   [I_T-1:0]                     timestamp,

output reg [$clog2(POTENTIAL_DEPTH)-1:0] potential_raddr,
output reg [POTENTIAL_WIDTH*MAX_KERNEL_NUM-1:0]     potential_wdata,
output reg [$clog2(POTENTIAL_DEPTH)-1:0] potential_waddr,
output reg                               read_req,   
output reg                               write_req,  
output reg [POST_WIDTH-1:0]              post_waddr,  
output reg [POST_WIDTH-1:0]              post_wdata, 
output reg                               post_req,
output reg                               finish_sche



);

localparam IDLE = 3'b000;
localparam  READ_SPIKE=3'b001;
localparam  WAIT=3'b010;
localparam  CHECK_SPIKE=3'b011;
localparam  WRITE_POTENTIAL=3'b100;
localparam  WRITE_SPIKE=3'b101;
genvar num;

reg [2:0] cs;
reg [2:0] ns;
reg [I_T-1:0] count_kernel;
reg [$clog2(POTENTIAL_DEPTH)-1:0] count_depth;
reg read_grant_reg;
reg [0:0] post_spike_temp [MAX_KERNEL_NUM-1:0];
reg spike_empty;
reg [POTENTIAL_WIDTH-1:0]potential_data;
wire [$clog2(POTENTIAL_DEPTH-1)-1:0] neuron_num;//neuron number per output channel
wire [I_I-1:0] i;
wire [I_J-1:0] j;
wire [POTENTIAL_WIDTH-1:0] gelu_out [MAX_KERNEL_NUM-1:0];
wire [POTENTIAL_WIDTH-1:0] gelu_in [MAX_KERNEL_NUM-1:0];
wire [POTENTIAL_WIDTH*MAX_KERNEL_NUM-1:0] gelu_out_wrapper;
integer c0;
integer c1;

genvar c2;
generate
    for(c2=0;c2<PE_NUM;c2=c2+1)
      begin: gen_gelu gelu_4

        gelu_inst(
        .x               (gelu_in[c2]),
        .y               (gelu_out[c2])
       
        );
     end
endgenerate
assign neuron_num = (working_mode[2:1]==2'b00)?(i_i-k_i+1)*(i_j-k_j+1):(output_neuron_num-1)/MAX_KERNEL_NUM+1;//FC->o_i*o_j 
assign i=(potential_raddr-1)%(i_i-k_i+1'b1);
assign j=(potential_raddr-1)/(i_j-k_j+1'b1);
assign gelu_in[0] = potential_rdata[31:0];
assign gelu_in[1] = potential_rdata[63:32];
assign gelu_in[3] = potential_rdata[95:64];
assign gelu_in[4] = potential_rdata[127:96];
assign gelu_out_wrapper = {gelu_out[0],gelu_out[1],gelu_out[2],gelu_out[3]};

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
    IDLE:ns=start_sche?READ_SPIKE:IDLE;
    READ_SPIKE:ns=read_grant?WAIT:READ_SPIKE;
    WAIT:ns=CHECK_SPIKE;
    //CHECK_SPIKE:ns=(count_kernel==KERNEL_NUM)?IDLE:((potnetial_rdata_reg[(count_kernel+1)*POTENTIAL_WIDTH-1:count_kernel*POTENTIAL_WIDTH]>=threhold))?WRITE_SPIKE:CHECK_SPIKE);
    CHECK_SPIKE:begin
          if(!spike_empty )begin
            if((count_depth==neuron_num)&&(post_grant)&&(working_mode==3'b000))begin
                ns=IDLE;
                finish_sche=1;
            end
            else
                ns=READ_SPIKE;
          end
          else
            ns=WRITE_POTENTIAL;
    end
    WRITE_POTENTIAL:begin
          if(write_grant)
          begin
            ns=WRITE_SPIKE;
          end
          else
          begin
            ns=WRITE_POTENTIAL;
          end
    end
    WRITE_SPIKE:begin
          if((count_kernel==MAX_KERNEL_NUM)&&(count_depth==neuron_num)&&(post_grant))
          begin
            ns=IDLE;
            finish_sche=1;
          end
          else if((count_kernel==MAX_KERNEL_NUM)&&(count_depth<neuron_num)&&(post_grant))
          begin
            ns=READ_SPIKE;
          end
          else
          begin
            ns=WRITE_SPIKE;
          end
    end
    default:ns=IDLE;
  endcase
end

always@(posedge clk or negedge rst)
begin
  if(!rst)
  begin
    potential_raddr<='b0;
    potential_wdata<='b0;
    potential_waddr<='b0;
    read_req       <='b0;
    write_req      <='b0;
    post_waddr     <='b0;
    post_wdata     <='b0;
    count_kernel   <='b0;
    count_depth    <='b0;
    post_req       <='b0;
    finish_sche    <='b0;
  end
  else
  begin
    case(ns)
      IDLE:begin
          potential_raddr<='b0;
          potential_wdata<='b0;
          potential_waddr<='b0;
          read_req       <='b0;
          write_req      <='b0;
          post_waddr     <='b0;
          post_wdata     <='b0;
          count_kernel   <='b0;
          count_depth    <='b0;
          post_req       <='b0;
      end
      READ_SPIKE:begin
          read_req<=1'b1;
          write_req<='b0;
          post_req<=1'b0;
      end
      WAIT:begin
          read_req<=1'b0;
          potential_raddr<=potential_raddr+1'b1;
          count_depth<=count_depth+1'b1;
          count_kernel<='b0;
      end
      CHECK_SPIKE:begin
             case(working_mode[2])
                1'b0:begin
                    for(c0=0;c0<MAX_KERNEL_NUM;c0=c0+1)begin
                      if(potential_rdata[((c0+1)*POTENTIAL_WIDTH-1)-:POTENTIAL_WIDTH]>=threhold)begin
                        potential_wdata[((c0+1)*POTENTIAL_WIDTH-1)-:POTENTIAL_WIDTH]<=rest_value;
                        post_spike_temp[MAX_KERNEL_NUM-c0-1]<=1'b1;
                      end
                      else begin
                        potential_wdata[((c0+1)*POTENTIAL_WIDTH-1)-:POTENTIAL_WIDTH]<=potential_rdata[((c0+1)*POTENTIAL_WIDTH-1)-:POTENTIAL_WIDTH];
                        post_spike_temp[MAX_KERNEL_NUM-c0-1]<=1'b0;
                      end  
                    end
                end
                
                1'b1:begin
                    if(!working_mode[1])begin
                        for(c0=0;c0<MAX_KERNEL_NUM;c0=c0+1)begin
                          if(potential_rdata[((c0+1)*POTENTIAL_WIDTH-1)-:POTENTIAL_WIDTH]<0)begin
                            potential_wdata[((c0+1)*POTENTIAL_WIDTH-1)-:POTENTIAL_WIDTH]<=0;
                            post_spike_temp[MAX_KERNEL_NUM-c0-1]<=1'b1;
                          end
                          else begin
                            potential_wdata[((c0+1)*POTENTIAL_WIDTH-1)-:POTENTIAL_WIDTH]<=potential_rdata[((c0+1)*POTENTIAL_WIDTH-1)-:POTENTIAL_WIDTH];
                            post_spike_temp[MAX_KERNEL_NUM-c0-1]<=1'b1;
                          end  
                        end
                    end
                    else begin
                        potential_wdata <= gelu_out_wrapper;
                        for(c0=0;c0<MAX_KERNEL_NUM;c0=c0+1)begin
                            post_spike_temp[MAX_KERNEL_NUM-c0-1]<=1'b1;
                        end                          
                    end    
                end
             endcase
      end
      WRITE_POTENTIAL:begin
        case(working_mode[2])
                1'b0:begin
                     write_req<=1'b1;
                     potential_waddr<=potential_raddr-1'b1;
                     potential_wdata<=potential_wdata;
                     count_kernel<='b0;
                end
                
                1'b1:begin
                     write_req<=1'b1;
                     potential_waddr<=potential_raddr-1'b1;
                     potential_wdata<=potential_rdata;
                     count_kernel<='b0;  
                end
             endcase
        end
      WRITE_SPIKE:begin
          write_req<=1'b0;
          case(working_mode[2:1])
          2'b00:begin
            if(count_kernel==0)
              begin
                if(post_spike_temp[count_kernel])
                begin  
                  post_req<=1'b1;
                  post_waddr<=post_addr;
                  post_wdata<={12'b0,i,j,count_kernel,timestamp};
                  count_kernel<=count_kernel+1'b1;
                end
                else
                begin
                  post_req<=1'b0;
                  count_kernel<=count_kernel+1'b1;
                end
              end
              else if(post_grant)
              begin
                if(post_spike_temp[count_kernel])
                begin  
                  post_req<=1'b1;
                  post_waddr<=post_addr;
                  post_wdata<={12'b0,i,j,count_kernel,timestamp};
                  count_kernel<=count_kernel+1'b1;
                end
                else
                begin
                  post_req<=1'b0;
                  count_kernel<=count_kernel+1'b1;
                end
              end
          end
          
          2'b01: begin
            if(count_kernel==0)
              begin
                if(post_spike_temp[count_kernel])
                begin  
                  post_req<=1'b1;
                  post_waddr<=post_addr;    
                  post_wdata<={count_kernel + (count_depth-1)*MAX_KERNEL_NUM,timestamp};       
                  count_kernel<=count_kernel+1'b1;            
                end
                else
                begin
                  post_req<=1'b0;
                  count_kernel<=count_kernel+1'b1;
                  post_wdata<=0;
                end
              end
            else if(post_grant)
              begin
                if(post_spike_temp[count_kernel])
                begin  
                  post_req<=1'b1;
                  post_waddr<=post_addr;
                  post_wdata<={count_kernel + (count_depth-1)*MAX_KERNEL_NUM,timestamp};
                  count_kernel<=count_kernel+1'b1;                 
                end
                else
                begin
                  post_req<=1'b0;
                  count_kernel<=count_kernel+1'b1;
                  post_wdata<=0;
                end
              end
          end
          
          default: begin
            if(count_kernel==0)
              begin
                if(post_spike_temp[count_kernel])
                begin  
                  post_req<=1'b1;
                  post_waddr<=post_addr;    
                  post_wdata<=potential_wdata[(POTENTIAL_WIDTH-1)-:POTENTIAL_WIDTH];       
                  count_kernel<=count_kernel+1'b1;            
                end
                else
                begin
                  post_req<=1'b0;
                  count_kernel<=count_kernel+1'b1;
                  post_wdata<=0;
                end
              end
            else if(post_grant)
              begin
                if(post_spike_temp[count_kernel])
                begin  
                  post_req<=1'b1;
                  post_waddr<=post_addr;
                  post_wdata<=potential_wdata[((count_kernel+1)*POTENTIAL_WIDTH-1)-:POTENTIAL_WIDTH];
                  count_kernel<=count_kernel+1'b1;                 
                end
                else
                begin
                  post_req<=1'b0;
                  count_kernel<=count_kernel+1'b1;
                  post_wdata<=0;
                end
              end            
          end
          
          endcase
        end
      endcase
  end
end

always@(*)
begin
  if(cs==CHECK_SPIKE)
  begin
  for(c1=0;c1<MAX_KERNEL_NUM;c1=c1+1)
    spike_empty=spike_empty|post_spike_temp[c1];   
  end
  else if(cs==READ_SPIKE)
  begin
    spike_empty=1'b0;
  end
  else
  begin
    spike_empty=spike_empty;
  end

end

always@(posedge clk or negedge rst)
begin
  if(!rst)
    read_grant_reg<='b0;
  else
    read_grant_reg<=read_grant;
end

endmodule
