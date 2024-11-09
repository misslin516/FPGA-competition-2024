module eth_adnet_pkt(
    input                 rst_n          ,   
   
    input                 data_clk       ,   
    input                 data_en        ,  
    input        [7:0]    data           ,  
    
    input                 transfer_flag  ,   
    
    input                 eth_tx_clk     , 
    input                 udp_tx_req     ,
    input                 udp_tx_done    /* synthesis PAP_MARK_DEBUG="1" */,                             
    output  reg           udp_tx_start_en,   //udp开始发送信号
    output       [7:0]    udp_tx_data    /* synthesis PAP_MARK_DEBUG="1" */,  
    output  wire  [15:0]   udp_tx_byte_num    //udp单包发送的有效字节数
    );    
 
/*********************************parameter*********************************/
parameter  udp_bytes = 16'd512;


/*********************************reg*********************************/
reg             wr_fifo_en;
reg  [7:0]      wr_fifo_data;
reg             tx_busy_flag;
/*********************************wire*********************************/
wire  [11:0]     fifo_rdusedw;
/*********************************assign*********************************/

assign  udp_tx_byte_num = udp_bytes;

/*********************************always*********************************/
always@(posedge data_clk or negedge rst_n)
begin
    if(~rst_n)begin
        wr_fifo_en <= 1'b0;
        wr_fifo_data <= 8'd0;
    end else if(data_en) begin
        wr_fifo_en <= 1'b1;
        wr_fifo_data <= data;     
    end else begin
        wr_fifo_en <= 1'b0;
        wr_fifo_data <= 8'd0;    
    end
end


always @(posedge eth_tx_clk or negedge rst_n) begin
    if(~rst_n) begin
        udp_tx_start_en <= 1'b0;
        tx_busy_flag <= 1'b0;
    end
    //上位机未发送"开始"命令时,以太网不发送数据
    else if(transfer_flag == 1'b0) begin
        udp_tx_start_en <= 1'b0;
        tx_busy_flag <= 1'b0;        
    end
    else begin
        udp_tx_start_en <= 1'b0;
        //当FIFO中的个数满足需要发送的字节数时
        if(tx_busy_flag == 1'b0 && fifo_rdusedw >= udp_tx_byte_num) begin
            udp_tx_start_en <= 1'b1;                     //开始控制发送一包数据
            tx_busy_flag <= 1'b1;
        end
        else if(udp_tx_done) 
            tx_busy_flag <= 1'b0;
        else;
    end
end

fifo_data_pkt the_instance_name (
  .wr_data(wr_fifo_data),                  // input [7:0]
  .wr_en(wr_fifo_en),                      // input
  .wr_clk(data_clk),                    // input
  .full(),                        // output
  .wr_rst((~transfer_flag) | (~rst_n)),                    // input
  .almost_full(),          // output
  .wr_water_level(),    // output [10:0]
  .rd_data(udp_tx_data),                  // output [7:0]
  .rd_en(udp_tx_req),                      // input
  .rd_clk(eth_tx_clk),                    // input
  .empty(),                      // output
  .rd_rst((~transfer_flag) | (~rst_n)),                    // input
  .almost_empty(),        // output
  .rd_water_level(fifo_rdusedw)     // output [10:0]
);

endmodule