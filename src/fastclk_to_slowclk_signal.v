module fastclk_to_slowclk_signal
#(
    parameter delay = 'd5
)
(
    input   fast_clk    ,
    input   slow_clk    ,
    input   rst_n       ,
    input   data_in     ,
    
    output  data_out

);

reg data_reg_0;
reg [delay-1:0] data_reg_1;

always@(posedge fast_clk or negedge rst_n)
begin
    if(~rst_n)begin
        data_reg_0 <= 1'b0;
    end else if(data_in) begin
        data_reg_0 <= ~data_reg_0;
    end else begin
        data_reg_0 <= data_reg_0;
    end
end


always@(posedge slow_clk or negedge rst_n)
begin
    if(~rst_n)begin
        data_reg_1 <= 'd0;
    end else begin
        data_reg_1 <= {data_reg_1[delay-2:0],data_reg_0};
    end
end


assign data_out = data_reg_1[delay-1] ^ data_reg_1[delay-2];


endmodule