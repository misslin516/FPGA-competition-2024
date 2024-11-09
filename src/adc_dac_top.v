//adc_dac function

`timescale 1ns/1ns
module adc_dac_top
(
   input  wire clk_50M  ,
   input  wire rst_n    ,
   output wire rst_n_out,  
   
   //adc_dac io
   output wire ad_clk /* synthesis PAP_MARK_DEBUG="true" */,
   input  wire [7:0]ad_data /* synthesis PAP_MARK_DEBUG="true" */,
   
   output reg  da_en       ,
   output reg [7:0]da_data /* synthesis PAP_MARK_DEBUG="true" */,
   output wire da_clk/* synthesis PAP_MARK_DEBUG="true" */
   
   

   );
/******************wire**********************/
wire    lock        ;
wire    clk_125M    ;
wire    clk_35M     ;
wire    clk_10M     ;


/******************reg**********************/
reg  [7:0]cnt ;

/******************assign**********************/
assign rst_n_out = (cnt == 'd255 && rst_n);
assign da_clk = clk_35M  ;
// assign da_data = ad_data  ;
assign ad_clk = clk_35M  ;


/******************always**********************/
always@(posedge clk_50M)
begin
    if(cnt == 'd255)begin
        cnt <= cnt;
    end else if(lock) begin
        cnt <= cnt + 1'b1;
    end else begin
        cnt <= 'd0;
    end
end

always@(posedge ad_clk or negedge rst_n_out)
begin
    if(~rst_n_out)begin
        da_en   <= 1'd0;
        da_data <= 8'd0;
    end else begin
        da_en   <= 1'b1;
        da_data <= cnt;
    end
end



/******************instance**********************/
ad_clock_125m u_pll (
  .clkin1(clk_50M),          // input
  .pll_lock(lock),          // output
  .clkout0(clk_125M) ,        // output
  .clkout1(clk_35M),      // output
  .clkout2(clk_10M)       // output       // output
);



endmodule