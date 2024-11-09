//created by:*****
//created date:10/4
//version：V2.0
//details: - add two-path adc HDMI  display
`timescale 1ns/1ns

//multi-path Collection 
module top2
(
//sys
    input           sys_clk                                 ,
    input           sys_rst_n                               ,
//                                               
    input           key11                                   ,
    input           key22                                   ,
    input           key33                                   ,
    input           key44                                   ,
    input           key55                                   ,
//adc_dac io                                              
    input     [7:0] ad_data                                 ,
    output    [7:0] da_data                                 ,
    output          ad_clk                                  ,
    output          da_clk                                  ,
      
//HDMI io                                                 
    output            rstn_out                              ,
    output            iic_scl                               ,
    inout             iic_sda                               ,
    output            iic_tx_scl                            ,
    inout             iic_tx_sda                            ,
    input             pixclk_in                             ,
    input             vs_in                                 ,
    input             hs_in                                 ,
    input             de_in                                 ,
    input     [7:0]   r_in                                  ,
    input     [7:0]   g_in                                  ,
    input     [7:0]   b_in                                  ,
       
    output               pixclk_out                         ,  
    output               vs_out                             ,
    output               hs_out                             ,
    output               de_out                             ,
    output        [7:0]  r_out                              ,
    output        [7:0]  g_out                              ,
    output        [7:0]  b_out                              ,
    output               led_int                            ,
//udp0 in                 
    output               eth_rst_n_0                        ,
    input                eth_rgmii_rxc_0                    ,
    input                eth_rgmii_rx_ctl_0                 ,
    input         [3:0]  eth_rgmii_rxd_0                    ,
                
    output               eth_rgmii_txc_0                    ,
    output               eth_rgmii_tx_ctl_0                 ,
    output        [3:0]  eth_rgmii_txd_0                    ,
//udp1 out             
    output               eth_rst_n_1                        ,
    input                eth_rgmii_rxc_1                    ,
    input                eth_rgmii_rx_ctl_1                 ,
    input         [3:0]  eth_rgmii_rxd_1                    ,
                                                           
    output               eth_rgmii_txc_1                    ,
    output               eth_rgmii_tx_ctl_1                 ,
    output        [3:0]  eth_rgmii_txd_1     
  
);
/******************************************global para*************************************************/
//eth0
parameter     BOARD_MAC_UDP0 =     48'h00_11_22_33_44_55    ;    //MAC Address
parameter     BOARD_IP_UDP0  = {8'd192,8'd168,8'd1,8'd10}   ;    //IP  Address      
//PC or other FPGA                                           
parameter     DES_MAC_UDP0   = 48'h84_A9_38_BF_C9_A0        ;    //PC  MAC Address
parameter     DES_IP_UDP0    = {8'd192,8'd168,8'd1,8'd102}  ;    //PC  IP  Address

//eth1
parameter     BOARD_MAC_UDP1 =     48'ha0_b1_c2_d3_e1_e1    ;    //MAC Address
parameter     BOARD_IP_UDP1  = {8'd192,8'd168,8'd1,8'd11}   ;    //IP  Address   
//PC or other FPGA                                               
parameter     DES_MAC_UDP1   = 48'h84_A9_38_BF_C9_A0        ;    //PC  MAC Address
parameter     DES_IP_UDP1    = {8'd192,8'd168,8'd1,8'd102}  ;    //PC  IP  Address


parameter     Key_filter_CNT = 20'd999_999                  ;

/****************************************wire****************************************/
//adda
wire          rst_n_addac_out                               ;
wire          led_int_adc                                   ;
wire          da_en                                         ;
wire          rstn_out_adc                                  ;
wire          iic_tx_scl_adc                                ;
wire          iic_tx_sda_adc                                ;
wire          pixclk_out_adc                                ;
wire          vs_out_adc                                    ;
wire          hs_out_adc                                    ;
wire          de_out_adc                                    ;
wire [7:0]    r_out_adc                                     ;
wire [7:0]    g_out_adc                                     ;
wire [7:0]    b_out_adc                                     ;
wire          data_sop                                      ;       
wire          data_eop                                      ;       
wire          data_valid                                    ;
wire [31:0]   data_modulus                                  ;


//udp rev                   
wire          udp1_en                                       ;
wire  [7:0]   udp1_data                                     ;
wire          rgmii_clk_0                                   ;
                    
wire          adnet_data_clk                                ;  
wire          adnet_data_en                                 ;
wire [7:0]    adnet_data                                    ;                    
                    
//rgb888torgb565                    
wire  [31:0]  rgb_in                                        ;
               
                    
//key                   
wire   [4:0]  key1                                          ;
wire   [4:0]  key_flag1                                     ;
//adnet signal                                              
                                                            
wire          adnet_udp_tx_req                              ;
wire          adnet_udp_tx_done                             ;
wire          adnet_udp_tx_start_en                         ;
wire [7:0]    adnet_udp_tx_data                             ;
wire [15:0]   adnet_udp_tx_byte_num                         ;
wire          rgmii_clk_1_adnet                             ;
wire          rec_en_adnet                                  ;
wire [7:0]    rec_data_adnet                                ;
wire          da_clk_fft                                    ;
wire          da_en_fft                                     ;
wire [7:0]    da_data_fft                                   ;                    
                                    
//image signal                  
wire          rgmii_clk_1                                   ;
wire          rec_en_image                                  ;  
wire  [31:0]  rec_data_image                                ;  
                    
wire          tx_start_en_image                             ;
wire  [31:0]  tx_data_image                                 ;
                    
                    
wire          tx_req                                        ;   
wire          udp_tx_done                                   ;
wire  [15:0]  tx_byte_num                                   ;  

wire          pixclk_out_image                              ;
wire          vs_out_image                                  ;
wire          hs_out_image                                  ;
wire          de_out_image                                  ;
wire [7:0]    r_out_image                                   ;
wire [7:0]    g_out_image                                   ;
wire [7:0]    b_out_image                                   ;
wire          led_int_image                                 ;     
wire          iic_tx_scl_image                              ;
wire          iic_tx_sda_image                              ;
wire          iic_scl_image                                 ;
wire          iic_sda_image                                 ;
wire          rstn_out_image                                ;



/**********NOTE: muti-path collection throught the way of define signal*************/
//-----Interface of using SFP transmission from another FPGA development board---
//ADDA  
wire  [7:0]   ad_data_1                                     ;
wire  [7:0]   da_data_1                                     ;
wire          ad_clk_1                                      ;
wire          da_clk_1                                      ;
wire          da_en_1                                       ;



assign   ad_data_1   =  ad_data                             ;      
assign   da_data_1   =  da_data                             ; 
assign   da_en_1     =  da_en                               ;
assign   ad_clk_1    =  ad_clk                              ;
assign   da_clk_1    =  da_clk                              ;





/****************************************reg****************************************/
reg [4:0]     cnt_keyen1                                    ;

/****************************************asisgn****************************************/
//rgb565---->  {rgb[31:27],rgb[21:16],rgb[11:7]}
assign rgb_in[31:24] = r_out;
assign rgb_in[23:22] = 2'd0;
assign rgb_in[21:14] = g_out;
assign rgb_in[13:12] = 2'd0;
assign rgb_in[11: 4] = b_out;
assign rgb_in[3 : 2] = 2'd0;
assign rgb_in[1 : 0] = 2'd0;

assign key1 = {key11,key22,key33,key44,key55};
       
assign adnet_data_clk        = cnt_keyen1[1] ? da_clk : cnt_keyen1[2] ? rgmii_clk_0 :cnt_keyen1[4] ? da_clk_1: 1'b0;
assign adnet_data_en         = cnt_keyen1[1] ? da_en  : cnt_keyen1[2] ? udp1_en     :cnt_keyen1[4] ? da_en_1: 1'b0;
assign adnet_data            = cnt_keyen1[1] ? da_data: cnt_keyen1[2] ? udp1_data   :cnt_keyen1[4] ? da_data_1: 8'b0;

assign rstn_out              = cnt_keyen1[3] ? rstn_out_image   :  rstn_out_adc       ;
assign iic_scl               = cnt_keyen1[3] ? iic_scl_image    :  iic_scl            ;
assign iic_sda               = cnt_keyen1[3] ? iic_sda_image    :  iic_sda            ;
assign iic_tx_scl            = cnt_keyen1[3] ? iic_tx_scl_image :  iic_tx_scl_adc     ;
assign iic_tx_sda            = cnt_keyen1[3] ? iic_tx_sda_image :  iic_tx_sda_adc     ;
assign pixclk_out            = cnt_keyen1[3] ? pixclk_out_image :  pixclk_out_adc     ;
assign vs_out                = cnt_keyen1[3] ? vs_out_image     :  vs_out_adc         ;
assign hs_out                = cnt_keyen1[3] ? hs_out_image     :  hs_out_adc         ;
assign de_out                = cnt_keyen1[3] ? de_out_image     :  de_out_adc         ;
assign r_out                 = cnt_keyen1[3] ? r_out_image      :  r_out_adc          ;
assign g_out                 = cnt_keyen1[3] ? g_out_image      :  g_out_adc          ;
assign b_out                 = cnt_keyen1[3] ? b_out_image      :  b_out_adc          ;
assign led_int               = cnt_keyen1[3] ? led_int_image    :  led_int_adc        ;
                                             
                                             
assign da_clk_fft            = cnt_keyen1[4] ? da_clk_1 :da_clk                       ;
assign da_en_fft             = cnt_keyen1[4] ? da_en_1  :da_en                        ;
assign da_data_fft           = cnt_keyen1[4] ? da_data_1:da_data                      ;
    
/****************************************always****************************************/
genvar i;
generate 
    for(i=0;i<5;i=i+1) begin:key_inst
        key_filter
        #(
            .CNT_MAX    (Key_filter_CNT) 
        )
        key_filter_inst1
        (
            .sys_clk    (sys_clk    )  , 
            .sys_rst_n  (sys_rst_n  )  , 
            .key_in     (key1[i]    )  , 
           
            .key_flag   (key_flag1[i])     
        );
   
        always@(posedge sys_clk or negedge sys_rst_n)
        begin
            if(!sys_rst_n) begin
                cnt_keyen1[i] <= 1'b0;
            end else if(key_flag1[i]) begin
                cnt_keyen1[i] <= ~cnt_keyen1[i];
            end else begin
                cnt_keyen1[i] <= cnt_keyen1[i];
            end
        end 
  end
endgenerate 



/****************************************INST****************************************/
//adc_dac collection

adc_dac_top adc_dac_inst
(
    .clk_50M   (sys_clk         )  ,
    .rst_n     (sys_rst_n       )  ,
    .rst_n_out (rst_n_addac_out )  ,
    .ad_clk    (ad_clk          )  ,
    .ad_data   (ad_data         )  ,
    .da_en     (da_en           )  ,
    .da_data   (da_data         )  ,
    .da_clk    (da_clk          )
   );

// HMDI  collection
hdmi_loop hdmi_loop_inst
(
   .sys_clk      (sys_clk          )  ,
  
   .rstn_out     (rstn_out_image   )  ,
   .iic_scl      (iic_scl_image    )  ,
   .iic_sda      (iic_sda_image    )  , 
   .iic_tx_scl   (iic_tx_scl_image )  ,
   .iic_tx_sda   (iic_tx_sda_image )  , 
   .pixclk_in    (pixclk_in        )  ,                            
   .vs_in        (vs_in            )  , 
   .hs_in        (hs_in            )  , 
   .de_in        (de_in            )  ,
   .r_in         (r_in             )  , 
   .g_in         (g_in             )  , 
   .b_in         (b_in             )  ,  
    
   .pixclk_out   (pixclk_out_image )  ,                            
   .vs_out       (vs_out_image     )  , 
   .hs_out       (hs_out_image     )  , 
   .de_out       (de_out_image     )  ,
   .r_out        (r_out_image      )  , 
   .g_out        (g_out_image      )  , 
   .b_out        (b_out_image      )  ,
   .led_int      (led_int_image    )
);




//UDP collection
udp_rec_top
#(
   .BOARD_MAC (BOARD_MAC_UDP1),
   .BOARD_IP  (BOARD_IP_UDP1 ),//192.168.1.11
                                                 
   .DES_MAC   (DES_MAC_UDP1  ),
   .DES_IP    (DES_IP_UDP1   )//192.168.1.102
)
udp_rec_top_inst
(
  .eth_rst_n_0       (eth_rst_n_0       )   ,
  .eth_rgmii_rxc_0   (eth_rgmii_rxc_0   )   ,
  .eth_rgmii_rx_ctl_0(eth_rgmii_rx_ctl_0)   ,
  .eth_rgmii_rxd_0   (eth_rgmii_rxd_0   )   ,
  
  .eth_rgmii_txc_0   (eth_rgmii_txc_0   )   ,
  .eth_rgmii_tx_ctl_0(eth_rgmii_tx_ctl_0)   ,
  .eth_rgmii_txd_0   (eth_rgmii_txd_0   )   ,
  
  .rgmii_clk_0       (rgmii_clk_0       )   ,
  .rst_n             (sys_rst_n         )   ,
 
  .rec_en            (udp1_en           )   ,
  .rec_data          (udp1_data         )
   
);



//adda display of time and frequency domain 
fft_top fft_top_inst
(
   .clk_50m       (sys_clk             ) ,
   .rst_n         (rst_n_addac_out     ) ,
 
   .audio_clk     (da_clk_fft          ) ,
   .audio_valid   (da_en_fft           ) ,
   .audio_data    ({8'b0,da_data_fft}  ) ,
 
   .data_sop      (data_sop            ) ,
   .data_eop      (data_eop            ) ,
   .data_valid    (data_valid          ) ,
   .data_modulus  (data_modulus        ) ,
   .o_alm         (                    )     //led5,6,7
);



hdmi_test1 hdmi_test1_inst
(
    .sys_clk     (sys_clk           )  ,// input system clock 50MHz 
    .rst_n       (rst_n_addac_out   )  ,
    .rstn_out    (rstn_out_adc      )  ,
    .iic_tx_scl  (iic_tx_scl_adc    )  ,
    .iic_tx_sda  (iic_tx_sda_adc    )  ,
   
    .fft_data    (data_modulus      )  , 
    .fft_sop     (data_sop          )  , 
    .fft_eop     (data_eop          )  , 
    .fft_valid   (data_valid        )  , 
    
    .audio_data  ({8'b0,da_data}    )  ,
    .audio_en    (  da_en           )  ,
    .audio_clk   (da_clk            )  ,
    
    .pix_clk     (pixclk_out_adc    )  ,
    .led_int     (led_int_adc       )  ,

    .vs_out      (vs_out_adc        )  , 
    .hs_out      (hs_out_adc        )  , 
    .de_out      (de_out_adc        )  ,
    .r_out       (r_out_adc         )  , 
    .g_out       (g_out_adc         )  , 
    .b_out       (b_out_adc         )  
);


//UDP TO PC
/********************************AD/NettoUdp************************************/
eth_adnet_pkt eth_adnet_pkt_inst
(
    .rst_n          (sys_rst_n      ),   
    
    .data_clk       (adnet_data_clk ),   
    .data_en        (adnet_data_en  ),  
    .data           (adnet_data     ),  
   
    .transfer_flag  (1              ),   
    
    .eth_tx_clk     (rgmii_clk_1_adnet    ), 
    .udp_tx_req     (adnet_udp_tx_req     ),
    .udp_tx_done    (adnet_udp_tx_done    ),                             
    .udp_tx_start_en(adnet_udp_tx_start_en),  
    .udp_tx_data    (adnet_udp_tx_data    ),  
    .udp_tx_byte_num(adnet_udp_tx_byte_num)  
    );    

 

/********************************ImagetoUdp**************************************/
eth_img_pkt eth0_img_pkt(    
    .rst_n              (sys_rst_n        ), //input                    
    ////图像相关信号              
    .cam_pclk           (pixclk_out      ), //input  图像时钟             
    .img_vsync          (vs_out          ), //input  帧同步               
    .img_data_en        (de_out          ), //input  de               
    .img_data           ({rgb_in[31:27],rgb_in[21:16],rgb_in[11:7]}), //input  [15:0]
    .transfer_flag      (1               ), //input                                        
    ////以太网相关信号
    .eth_tx_clk         (rgmii_clk_1     ), //input                          
    .udp_tx_req         (tx_req          ), //input                
    .udp_tx_done        (udp_tx_done     ), //input                
    .udp_tx_start_en    (tx_start_en_image     ), //output  reg          
    .udp_tx_data        (tx_data_image         ), //output       [31:0]  
    .udp_tx_byte_num    (tx_byte_num     )  //output  reg  [15:0]  
    ); 
    
/********************************Udpout**************************************/
udp_tx_top_revised
#(
   .BOARD_MAC(BOARD_MAC_UDP0),     //开发板MAC地址
   .BOARD_IP (BOARD_IP_UDP0 ),     //开发板IP地址
                   
   .DES_MAC  (DES_MAC_UDP0  ),     //PC   MAC地址
   .DES_IP   (DES_IP_UDP0   )   //目的 IP  地址
)
udp_tx_top_revised_inst
(
                      
  .eth_rst_n_0           (eth_rst_n_1              )   ,
  .eth_rgmii_rxc_0       (eth_rgmii_rxc_1          )   ,
  .eth_rgmii_rx_ctl_0    (eth_rgmii_rx_ctl_1       )   ,
  .eth_rgmii_rxd_0       (eth_rgmii_rxd_1          )   ,
       
  .eth_rgmii_txc_0       (eth_rgmii_txc_1          )   ,
  .eth_rgmii_tx_ctl_0    (eth_rgmii_tx_ctl_1       )   ,
  .eth_rgmii_txd_0       (eth_rgmii_txd_1          )   ,
       
  .rgmii_clk_0           (rgmii_clk_1              )   ,
  .rst_n                 (sys_rst_n                )   ,
       
  .eth_ctrl              (cnt_keyen1[0]            )   ,
 
  .rec_en_0              (rec_en_adnet             )   ,
  .rec_data_0            (rec_data_adnet           )   , 
  .tx_start_en_0         (adnet_udp_tx_start_en    )   ,
  .tx_data_0             (adnet_udp_tx_data        )   ,   
  .tx_byte_num_0         (adnet_udp_tx_byte_num    )   ,
 
  .rec_en_1              (rec_en_image             )   ,
  .rec_data_1            (rec_data_image           )   , 
  .tx_start_en_1         (tx_start_en_image        )   ,
  .tx_data_1             (tx_data_image            )   ,   
  .tx_byte_num_1         (tx_byte_num              )   ,

  .tx_req_0              (adnet_udp_tx_req         )   ,
  .udp_tx_done_0         (adnet_udp_tx_done        )   ,
 
  .tx_req_1              (tx_req                   )   ,
  .udp_tx_done_1         (udp_tx_done              )
);




endmodule






