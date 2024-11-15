//----------------------------------------------------------------------------------------
//**********************************
`timescale 1ns/1ns


module udp_tx_top
#(
    parameter     BOARD_MAC =     48'ha0_b1_c2_d3_e1_e1     ,     //开发板MAC地址
    parameter     BOARD_IP  = {8'd192,8'd168,8'd1,8'd11}    ,     //开发板IP地址
                                                                                
    parameter     DES_MAC   = 48'h84_A9_38_BF_C9_A0         ,     //PC   MAC地址
    parameter     DES_IP    = {8'd192,8'd168,8'd1,8'd102}          //目的 IP  地址
)
(
    //udp io                                                 
    output wire                          eth_rst_n_0            ,
    input  wire                          eth_rgmii_rxc_0        ,
    input  wire                          eth_rgmii_rx_ctl_0     ,
    input  wire [3:0]                    eth_rgmii_rxd_0        ,
                                                               
    output wire                          eth_rgmii_txc_0        ,
    output wire                          eth_rgmii_tx_ctl_0     ,
    output wire [3:0]                    eth_rgmii_txd_0        ,
    
    output   wire                        rgmii_clk_0            ,
    input   wire                         rst_n                  ,
    
    output                               rec_en                 ,
    output       [7:0]                   rec_data               , 
    
    input                                tx_start_en            ,
    input     [7:0]                      tx_data                ,   
    
    input     [15:0]                     tx_byte_num            ,
    
    
    output                               tx_req                 ,
    output                               udp_tx_done               
);

/******************************wire********************************************/  
//udp
wire mac_tx_data_valid_0;
wire [7:0] mac_tx_data_0;
wire mac_rx_error_0;
wire mac_rx_data_valid_0;
wire [7:0] mac_rx_data_0;
wire rec_pkt_done;

// wire tx_start_en;
// wire [7:0] tx_data;
// wire [15:0] tx_byte_num;
// wire udp_tx_done;
// wire tx_req;
wire  [15:0]      rec_byte_num  ;
/******************************reg********************************************/  


/******************************assign********************************************/  
assign eth_rst_n_0 = rst_n;
/******************************always********************************************/  



/******************************instance********************************************/  
//ETH0_GMII_RGMII
gmii_to_rgmii eth0_gmii_to_rgmii(
   .rgmii_clk             (rgmii_clk_0       ),    // output GMII时钟，供数据使用      
   .rst                   (rst_n             ),    // input        
    //mac输入的数据由gmii转化为rgmii，时钟为rgmii_clk
   .mac_tx_data_valid     (mac_tx_data_valid_0),    // input        
   .mac_tx_data           (mac_tx_data_0      ),    // input [7:0]  
    //eth输入的数据由rgmii转化为gmii，时钟为rgmii_clk
   .mac_rx_error          (mac_rx_error_0     ),    //output reg       
   .mac_rx_data_valid     (mac_rx_data_valid_0),    //output reg       
   .mac_rx_data           (mac_rx_data_0      ),    //output reg [7:0] 
   //eth接收                
   .rgmii_rxc             (eth_rgmii_rxc_0    ),    //input        
   .rgmii_rx_ctl          (eth_rgmii_rx_ctl_0 ),    //input        
   .rgmii_rxd             (eth_rgmii_rxd_0    ),    //input [3:0]  
   //eth发送                                    
   .rgmii_txc             (eth_rgmii_txc_0    ),    //output       
   .rgmii_tx_ctl          (eth_rgmii_tx_ctl_0 ),    //output       
   .rgmii_txd             (eth_rgmii_txd_0    )     //output [3:0] 
);

//UDP通信
udp                                             
   #(
    .BOARD_MAC     (BOARD_MAC),      //参数例化
    .BOARD_IP      (BOARD_IP ),
    .DES_MAC       (DES_MAC  ),
    .DES_IP        (DES_IP   )
    )
u_udp(
    .rst_n         (rst_n   ),  //input       复位信号，低电平有效            
    //GMII接口                                
    .gmii_rx_clk   (rgmii_clk_0         ),  //input       GMII接收数据时钟                    
    .gmii_rx_dv    (mac_rx_data_valid_0 ),  //input       GMII输入数据有效信号                
    .gmii_rxd      (mac_rx_data_0       ),  //input [7:0] GMII输入数据                              
    .gmii_tx_clk   (rgmii_clk_0         ),  //input       GMII发送数据时钟            
    .gmii_tx_en    (mac_tx_data_valid_0 ),  //output      GMII输出数据有效信号                  
    .gmii_txd      (mac_tx_data_0       ),  //output[7:0] GMII输出数据              
    //用户接口                                  
    .rec_pkt_done  (rec_pkt_done        ),  //output      以太网单包数据接收完成信号          
    .rec_en        (rec_en              ),  //output      以太网接收的数据使能信号            
    .rec_data      (rec_data            ),  //output[31:0]以太网接收的数据                    
    .rec_byte_num  (rec_byte_num        ),  //output[15:0]以太网接收的有效字节数 单位:byte  
    
    .tx_start_en   (tx_start_en         ),  //input       以太网开始发送信号                  
    .tx_data       (tx_data             ),  //input [7:0]以太网待发送数据                    
    .tx_byte_num   (tx_byte_num         ),  //input [15:0]以太网发送的有效字节数 单位:byte   
    .des_mac       (DES_MAC             ),  //input [47:0]发送的目标MAC地址            
    .des_ip        (DES_IP              ),  //input [31:0]发送的目标IP地址              
    .tx_done       (udp_tx_done         ),  //output      以太网发送完成信号                  
    .tx_req        (tx_req              )   //output      读数据请求信号                      
    ); 


endmodule




