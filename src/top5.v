//created by:*****
//created date:10/6
//version：V5.2
//revised date:2024/10/25
//details: 
//1 - add UART signal collection
//2 - add IO constranints
//3 - Anaylsis the time violation
`timescale 1ns/1ns

//multi-path Collection 
module top5
#(
  parameter VIDEO_LENGTH         = 1920                                                              ,
  parameter VIDEO_HIGTH          = 1080                                                              ,
  parameter ZOOM_VIDEO_LENGTH    = 960                                                               ,
  parameter ZOOM_VIDEO_HIGTH     = 540                                                               ,
  parameter PIXEL_WIDTH          = 32                                                                ,     
  parameter DQ_WIDTH             = 32                                                                ,     
  parameter MEM_ROW_ADDR_WIDTH   = 15                                                                ,
  parameter MEM_COL_ADDR_WIDTH   = 10                                                                ,
  parameter MEM_BADDR_WIDTH      = 3                                                                 ,
  parameter MEM_DQ_WIDTH         = 32                                                                ,
  parameter MEM_DM_WIDTH         = MEM_DQ_WIDTH/8                                                    ,
  parameter MEM_DQS_WIDTH        = MEM_DQ_WIDTH/8                                                    ,
  parameter M_AXI_BRUST_LEN      = 8                                                                 ,
  parameter RW_ADDR_MIN          = 20'b0                                                             ,
  parameter RW_ADDR_MAX          = ZOOM_VIDEO_LENGTH*ZOOM_VIDEO_HIGTH*PIXEL_WIDTH/MEM_DQ_WIDTH       ,//@540p  518400个地址   
  parameter CTRL_ADDR_WIDTH      = MEM_ROW_ADDR_WIDTH + MEM_BADDR_WIDTH + MEM_COL_ADDR_WIDTH
)
(
//sys
    input           sys_clk                                 ,
    input           sys_rst_n                               ,
//Key control                                             
    input           key11                                   ,
    input           key22                                   ,
    input           key33                                   ,
    input           key44                                   ,
    input           key55                                   ,
    input           key66                                   ,
    input           key77                                   ,
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
    output        [3:0]  eth_rgmii_txd_1                    ,
//uart
    input                uart_rx                            ,       
    
//led instruction
    output               frame00                            ,
    output               frame11                            ,
    output               frame22                            ,
    output               frame33                            ,
    output               uart_led                           ,

//DDR
    output                                 mem_rst_n        ,                       
    output                                 mem_ck           ,
    output                                 mem_ck_n         ,
    output                                 mem_cke          ,
    output                                 mem_cs_n         ,
    output                                 mem_ras_n        ,
    output                                 mem_cas_n        ,
    output                                 mem_we_n         ,  
    output                                 mem_odt          ,
    output     [MEM_ROW_ADDR_WIDTH-1:0]    mem_a            ,   
    output     [MEM_BADDR_WIDTH-1:0]       mem_ba           ,   
    inout      [MEM_DQS_WIDTH-1:0]         mem_dqs          ,
    inout      [MEM_DQS_WIDTH-1:0]         mem_dqs_n        ,
    inout      [MEM_DQ_WIDTH-1:0]          mem_dq           ,
    output     [MEM_DM_WIDTH-1:0]          mem_dm           ,
    output                                 ddr_pll_lock     ,           
    output                                 ddr_init_done       
  
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

//Key count
parameter     Key_filter_CNT = 20'd999_999                  ;

//FSM --if you wanna use Low-Power-Consumption design,there can be one-hot code or gray code(i>>1) ^ i
parameter     s0 = 4'd0,s1 = 4'd1,s2 = 4'd2,s3 = 4'd3,s4 = 4'd4,s5 = 4'd5,s6 = 4'd6,s7 = 4'd7,s8 = 4'd8,s9 = 4'd9,s10 = 4'd10;
parameter     state_x0 = 4'b0000 ,state_x1 = 4'b0001,state_x2 = 4'b0010,state_x3 = 4'b0100,state_x4 = 4'b1000;
parameter     u0 = 4'd0,u1 = 4'd1,u2 = 4'd2,u3 = 4'd3,u4 = 4'd4,u5 = 4'd5,u6 = 4'd6,u7 = 4'd7;

//BLUE RGB color
parameter     BLUE = 24'h0000FF;





/****************************************wire****************************************/
//adda
wire          rst_n_addac_out                               ;
wire          da_en                                         ;

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
wire   [6:0]  key1                                          ;
wire   [6:0]  key_flag1                                     ;
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

//DDR HDMI AXI-Arbitration
wire         ddr_ip_rst_n                                   ;
wire         ddr_ip_clk                                     ;  
    
wire         vs_out_sync                                    ;    
wire         hs_out_sync                                    ;    
wire         de_out_sync                                    ;    
                                                            
wire [11:0]  x_act_sync                                     ;
wire [11:0]  y_act_sync                                     ;

wire                    zoom_de_out                         ;
wire [PIXEL_WIDTH-1:0]  zoom_data_out                       ;


wire [31:0]   video0_data_out                               ;                                                          
wire [31:0]   video1_data_out                               ;                                                          
wire [31:0]   video2_data_out                               ;                                                         
wire [31:0]   video3_data_out                               ;       
                                                            
wire          fram0_done                                    ; 
wire          fram1_done                                    ; 
wire          fram2_done                                    ; 
wire          fram3_done                                    ; 

wire [3 : 0]                           M_AXI_AWID     /* synthesis PAP_MARK_DEBUG="1" */;
wire [CTRL_ADDR_WIDTH-1 : 0]           M_AXI_AWADDR   /* synthesis PAP_MARK_DEBUG="1" */;
wire                                   M_AXI_AWUSER   /* synthesis PAP_MARK_DEBUG="1" */;
wire                                   M_AXI_AWVALID   /* synthesis PAP_MARK_DEBUG="1" */;
wire                                   M_AXI_AWREADY   /* synthesis PAP_MARK_DEBUG="1" */;
                                               
wire [DQ_WIDTH*8-1 : 0]                M_AXI_WDATA    /* synthesis PAP_MARK_DEBUG="1" */;
wire [DQ_WIDTH-1 : 0]                  M_AXI_WSTRB    /* synthesis PAP_MARK_DEBUG="1" */;
wire                                   M_AXI_WLAST    /* synthesis PAP_MARK_DEBUG="1" */;
wire [3 : 0]                           M_AXI_WUSER    /* synthesis PAP_MARK_DEBUG="1" */;
wire                                   M_AXI_WREADY   /* synthesis PAP_MARK_DEBUG="1" */;                                                
                                               
wire [3 : 0]                           M_AXI_ARID     /* synthesis PAP_MARK_DEBUG="1" */;
wire                                   M_AXI_ARUSER   /* synthesis PAP_MARK_DEBUG="1" */;
wire [CTRL_ADDR_WIDTH-1 : 0]           M_AXI_ARADDR   /* synthesis PAP_MARK_DEBUG="1" */;

wire                                   M_AXI_ARVALID   /* synthesis PAP_MARK_DEBUG="1" */;
wire                                   M_AXI_ARREADY   /* synthesis PAP_MARK_DEBUG="1" */;
                                              
wire  [3 : 0]                          M_AXI_RID      /* synthesis PAP_MARK_DEBUG="1" */;
wire  [DQ_WIDTH*8-1 : 0]               M_AXI_RDATA    /* synthesis PAP_MARK_DEBUG="1" */;
wire                                   M_AXI_RLAST    /* synthesis PAP_MARK_DEBUG="1" */;
wire                                   M_AXI_RVALID   /* synthesis PAP_MARK_DEBUG="1" */;

 reg [15:0]  rstn_1ms                                       ;
 wire        pix_clk                                        ;
 wire        cfg_clk                                        ;
 wire        locked                                         ;
 wire        init_over                                      ;

//four type of video algorithm value setting
wire  [8:0]      bright_value           = 'd0               ;
wire  [8:0]      contrast_value         = 'd0               ;
wire  [8:0]      saturation_value       = 'd0               ;
wire  [7:0]      relief_value           = 'd0               ;

wire  [8:0]      B_value                                    ;
wire  [8:0]      C_value                                    ;
wire  [8:0]      S_value                                    ;
wire  [7:0]      R_value                                    ;

wire    [7:0]    rx_data                                    ;
wire             rx_en                                      ;
reg  [8:0]      bright_value_offset                         ;
reg  [8:0]      contrast_value_offset                       ;
reg  [8:0]      saturation_value_offset                     ;
reg  [7:0]      relief_value_offset                         ;

/**********NOTE: muti-path collection through the way of define signal*************/
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
reg [6:0]     cnt_keyen1                                    ;
//related to Bonus point 2
reg           mode_flag_0                                   ;  
reg           mode_flag_1                                   ;  
reg [3:0]     state_video_disp                              ;
reg           r_vs_out                                      ;
reg           r_vs_out_d0                                   ;
reg           r_hs_out                                      ;
reg           r_de_out                                      ;
reg           r_de_out_d0                                   ;
reg [7:0]     r_r_out                                       ;
reg [7:0]     r_g_out                                       ;
reg [7:0]     r_b_out                                       ;
reg           video0_rd_en                                  ;
reg           video1_rd_en                                  ;
reg           video2_rd_en                                  ;
reg           video3_rd_en                                  ;
reg [11:0]    r_x_act_d0                                    ;
reg [11:0]    r_x_act                                       ;
                                    
reg           vs_out_d0                                     ;
reg           vs_out_d1                                     ;
                            
reg           video_pre_rd_flag                             ;

reg       mode_hdmi_effect_flag_0                           ;
reg       mode_hdmi_effect_flag_1                           ;
reg [3:0] mode_hdmi_effect_state                            ;

reg   [8:0]      uart_cache [0:3]                           ;
reg   [9:0]      uart_sum                                   ;
reg              uart_finish                                ;
reg              uart_error                                 ;
reg              uart_cnt                                   ;
reg  [3:0]       state_uart                                 ;      
/****************************************asisgn****************************************/
//rgb565----> RGB888 {rgb[31:27],rgb[21:16],rgb[11:7]}
assign rgb_in[31:24] = r_in         ;
assign rgb_in[23:22] = 2'd0         ;
assign rgb_in[21:14] = g_in         ;
assign rgb_in[13:12] = 2'd0         ;
assign rgb_in[11: 4] = b_in         ;
assign rgb_in[3 : 2] = 2'd0         ;
assign rgb_in[1 : 0] = 2'd0         ;


assign key1 = {key77,key66,key55,key44,key33,key22,key11};

       
assign adnet_data_clk        = cnt_keyen1[1] ? da_clk : cnt_keyen1[2] ? rgmii_clk_0 :cnt_keyen1[4] ? da_clk_1: 1'b0;
assign adnet_data_en         = cnt_keyen1[1] ? da_en  : cnt_keyen1[2] ? udp1_en     :cnt_keyen1[4] ? da_en_1: 1'b0;
assign adnet_data            = cnt_keyen1[1] ? da_data: cnt_keyen1[2] ? udp1_data   :cnt_keyen1[4] ? da_data_1: 8'b0;


assign pixclk_out            = cnt_keyen1[3] ? pixclk_out_image :  pix_clk            ;
assign vs_out                = cnt_keyen1[3] ? r_vs_out         :  vs_out_adc         ;
assign hs_out                = cnt_keyen1[3] ? r_hs_out         :  hs_out_adc         ;
assign de_out                = cnt_keyen1[3] ? r_de_out         :  de_out_adc         ;
assign r_out                 = cnt_keyen1[3] ? r_r_out          :  r_out_adc          ;
assign g_out                 = cnt_keyen1[3] ? r_g_out          :  g_out_adc          ;
assign b_out                 = cnt_keyen1[3] ? r_b_out          :  b_out_adc          ;
assign led_int               = init_over                                              ;
                                             
                                             
assign da_clk_fft            = cnt_keyen1[4] ? da_clk_1 :da_clk                       ;
assign da_en_fft             = cnt_keyen1[4] ? da_en_1  :da_en                        ;
assign da_data_fft           = cnt_keyen1[4] ? da_data_1:da_data                      ;
    
    
assign  B_value = (bright_value     + bright_value_offset)     >= 256   ?  (bright_value     + bright_value_offset)    -256:(bright_value     + bright_value_offset)     ;
assign  C_value = (contrast_value   + contrast_value_offset)   >= 256   ?  (contrast_value   + contrast_value_offset)  -256:(contrast_value   + contrast_value_offset)   ;
assign  S_value = (saturation_value + saturation_value_offset) >= 256   ?  (saturation_value + saturation_value_offset)-256:(saturation_value + saturation_value_offset) ;
assign  R_value = (relief_value     + relief_value_offset)     >= 128   ?  (relief_value     + relief_value_offset)    -128:(relief_value     + relief_value_offset)     ;

assign rstn_out             = (rstn_1ms == 16'h2710)                                 ;
assign frame00              =   fram0_done_1                                         ;
assign frame11              =   fram1_done_1                                         ;
assign frame22              =   fram2_done_1                                         ;
assign frame33              =   fram3_done_1                                         ;
assign uart_led             =   uart_finish                                          ;


/****************************************always****************************************/
genvar i;
generate 
    for(i=0;i<7;i=i+1) begin:key_inst
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

reg        ddr_ip_rst_n_0 = 'd0     ;
reg        ddr_ip_rst_n_1 = 'd0     ;
reg        ddr_init_done_0  = 'd0   ;
reg        ddr_init_done_1  = 'd0   ;
reg        fram0_done_0  ='d0       ;
reg        fram0_done_1  ='d0       ;
reg        fram1_done_0  ='d0       ;
reg        fram1_done_1  ='d0       ;
reg        fram2_done_0  ='d0       ;
reg        fram2_done_1  ='d0       ;
reg        fram3_done_0  ='d0       ;
reg        fram3_done_1  ='d0       ;
//two level synchronization
always@(posedge pixclk_out_image)
begin
    ddr_ip_rst_n_0 <= ddr_ip_rst_n;
    ddr_ip_rst_n_1 <= ddr_ip_rst_n_0; 
    ddr_init_done_0 <= ddr_init_done;
    ddr_init_done_1 <= ddr_init_done_0;
    fram0_done_0 <= fram0_done;
    fram0_done_1 <= fram0_done_0;
    fram1_done_0 <= fram1_done;
    fram1_done_1 <= fram1_done_0;
    fram2_done_0 <= fram2_done;
    fram2_done_1 <= fram2_done_0;
    fram3_done_0 <= fram3_done;
    fram3_done_1 <= fram3_done_0;
end


always@(posedge pixclk_out_image)
begin
    if(~ddr_ip_rst_n_1)begin
        mode_flag_0 <= 'd0;
        mode_flag_1 <= 'd0;
    end else begin
        mode_flag_0 <= key_flag1[5];
        mode_flag_1 <= mode_flag_0;
    end
end

always@(posedge pixclk_out_image)
begin
    if(~ddr_ip_rst_n_1)begin
        state_video_disp <= s0;
    end else begin
        case(state_video_disp)
            s0:
                if(mode_flag_1)begin
                    state_video_disp <= s1;
                end else begin
                    state_video_disp <= s0;
                end
            s1:
                if(mode_flag_1)begin
                    state_video_disp <= s2;
                end else begin
                    state_video_disp <= s1;
                end
            s2:
                if(mode_flag_1)begin
                    state_video_disp <= s3;
                end else begin
                    state_video_disp <= s2;
                end
            s3:
                if(mode_flag_1)begin
                    state_video_disp <= s4;
                end else begin
                    state_video_disp <= s3;
                end
            s4:
                if(mode_flag_1)begin
                    state_video_disp <= s5;
                end else begin
                    state_video_disp <= s4;
                end
            s5:
                if(mode_flag_1)begin
                    state_video_disp <= s6;
                end else begin
                    state_video_disp <= s5;
                end
            s6:
                if(mode_flag_1)begin
                    state_video_disp <= s7;
                end else begin
                    state_video_disp <= s6;
                end
            s7:
                if(mode_flag_1)begin
                    state_video_disp <= s8;
                end else begin
                    state_video_disp <= s7;
                end
            s8:
                if(mode_flag_1)begin
                    state_video_disp <= s9;
                end else begin
                    state_video_disp <= s8;
                end
            s9:
                if(mode_flag_1)begin
                    state_video_disp <= s10;
                end else begin
                    state_video_disp <= s9;
                end
            s10:
                if(mode_flag_1)begin
                    state_video_disp <= s0;
                end else begin
                    state_video_disp <= s10;
                end
            default:state_video_disp <= s0;
         endcase
    end
end



always@(posedge pixclk_out_image)
begin
    if(~ddr_ip_rst_n_1)begin
        vs_out_d0 <= 1'b0;
        vs_out_d1 <= 1'b0;
    end else begin
        vs_out_d0 <= vs_out_sync;
        vs_out_d1 <= vs_out_d0  ;        
    end
end




//procedure: mode_cnt
    //------0->3 : sigle  video
    //-------  4 : four   video
    //---------5 : two videos -->> A and B
    //---------6 : two videos -->> A and C
    //---------7 : two videos -->> A and D
    //---------8 : two videos -->> B and C
    //---------9 : two videos -->> B and D
    //--------10 : two videos -->> C and D

always@(posedge pixclk_out_image)
begin
    if(~ddr_ip_rst_n_1)begin
        r_vs_out     <= 'd0;
        r_hs_out     <= 'd0;
        r_de_out     <= 'd0;
        r_r_out      <= 'd0;
        r_g_out      <= 'd0;
        r_b_out      <= 'd0;
        video0_rd_en <= 'd0;
        video1_rd_en <= 'd0;
        video2_rd_en <= 'd0;
        video3_rd_en <= 'd0;
    end else if(ddr_init_done_1) begin
        case(state_video_disp)
            s0:begin
               r_vs_out     <=  vs_out_image   ;
               r_hs_out     <=  hs_out_image   ;
               r_de_out     <=  de_out_image   ;
               r_r_out      <=  r_out_image    ;
               r_g_out      <=  g_out_image    ;
               r_b_out      <=  b_out_image    ;
               video0_rd_en <=  1'b0           ;
               video1_rd_en <=  1'b0           ;
               video2_rd_en <=  1'b0           ;
               video3_rd_en <=  1'b0           ;
            end
            s1:begin
               r_vs_out     <=  vs_out_image   ;
               r_hs_out     <=  hs_out_image   ;
               r_de_out     <=  de_out_image   ;
               r_r_out      <=  r_out_image    ;
               r_g_out      <=  g_out_image    ;
               r_b_out      <=  b_out_image    ;
               video0_rd_en <=  1'b0           ;
               video1_rd_en <=  1'b0           ;
               video2_rd_en <=  1'b0           ;
               video3_rd_en <=  1'b0           ; 
            end
            s2:begin
               r_vs_out     <=  vs_out_image   ;
               r_hs_out     <=  hs_out_image   ;
               r_de_out     <=  de_out_image   ;
               r_r_out      <=  r_out_image    ;
               r_g_out      <=  g_out_image    ;
               r_b_out      <=  b_out_image    ;
               video0_rd_en <=  1'b0           ;
               video1_rd_en <=  1'b0           ;
               video2_rd_en <=  1'b0           ;
               video3_rd_en <=  1'b0           ;
            end
            s3:begin
               r_vs_out     <=  vs_out_image   ;
               r_hs_out     <=  hs_out_image   ;
               r_de_out     <=  de_out_image   ;
               r_r_out      <=  r_out_image    ;
               r_g_out      <=  g_out_image    ;
               r_b_out      <=  b_out_image    ;
               video0_rd_en <=  1'b0           ;
               video1_rd_en <=  1'b0           ;
               video2_rd_en <=  1'b0           ;
               video3_rd_en <=  1'b0           ; 
            end
            s4:begin
                r_vs_out_d0 <= vs_out_sync     ;
                r_vs_out    <= r_vs_out_d0     ;
                r_hs_out    <= hs_out_sync     ;
                r_de_out_d0 <= de_out_sync     ;
                r_de_out    <= r_de_out_d0     ;
                r_x_act_d0  <= x_act_sync      ;
                r_x_act     <= r_x_act_d0      ;
                if(vs_out_d0 && !vs_out_d1) begin
                    video_pre_rd_flag <= 'd0;
                end else if(!vs_out_d0 && vs_out_d1 && !video_pre_rd_flag && (fram0_done_1 || fram1_done_1 || fram2_done_1 || fram3_done_1)) begin
                    video0_rd_en      <= 'd1;
                    video1_rd_en      <= 'd1;
                    video2_rd_en      <= 'd1;
                    video3_rd_en      <= 'd1;
                    video_pre_rd_flag <= 'd1;
                end else begin
                    if( fram0_done_1 && (r_x_act >= 0) && (r_x_act < ZOOM_VIDEO_LENGTH - 1) && (y_act_sync < ZOOM_VIDEO_HIGTH ) && (y_act_sync >= 0)) begin
                        r_r_out  <=  video0_data_out[31:24];
                        r_g_out  <=  video0_data_out[21:14];
                        r_b_out  <=  video0_data_out[11: 4];  
                        video0_rd_en <= de_out_sync; //pre-read
                        video1_rd_en <= 'd0; 
                        video2_rd_en <= 'd0; 
                        video3_rd_en <= 'd0; 
                        if(r_x_act == ZOOM_VIDEO_LENGTH - 2) begin
                            video1_rd_en <= de_out_sync;
                            video0_rd_en <= 'd0;
                        end
                    end
                    if(fram1_done_1 &&(r_x_act >= ZOOM_VIDEO_LENGTH - 1) && (r_x_act < VIDEO_LENGTH - 1) && (y_act_sync < ZOOM_VIDEO_HIGTH )&& (y_act_sync >= 0)) begin
                        r_r_out  <= video1_data_out[31:24];
                        r_g_out  <= video1_data_out[21:14];
                        r_b_out  <= video1_data_out[11: 4];
                        video0_rd_en <= 'd0; 
                        video1_rd_en <= de_out_sync; 
                        video2_rd_en <= 'd0; 
                        video3_rd_en <= 'd0; 
                    end  
                    if( fram2_done_1 &&(r_x_act >= 0) && (r_x_act < ZOOM_VIDEO_LENGTH - 1) && (y_act_sync < VIDEO_HIGTH )&& (y_act_sync >= ZOOM_VIDEO_HIGTH)) begin
                        r_r_out  <= video2_data_out[31:24] ;
                        r_g_out  <= video2_data_out[21:14] ;
                        r_b_out  <= video2_data_out[11: 4] ;  
                        video0_rd_en <= 'd0; 
                        video1_rd_en <= 'd0; 
                        video2_rd_en <= de_out_sync; 
                        video3_rd_en <= 'd0; 
                        if(r_x_act == ZOOM_VIDEO_LENGTH - 2) begin
                            video3_rd_en <= de_out_sync;
                            video2_rd_en <= 'd0;
                        end
                    end    
                    if(fram3_done_1 &&(r_x_act >= ZOOM_VIDEO_LENGTH - 1) && (r_x_act < VIDEO_LENGTH - 1) && (y_act_sync < VIDEO_HIGTH )&& (y_act_sync >= ZOOM_VIDEO_HIGTH)) begin//实际上是r_x_act 0~63
                        r_r_out  <= video3_data_out[31:24];
                        r_g_out  <= video3_data_out[21:14];
                        r_b_out  <= video3_data_out[11: 4];     
                        video0_rd_en <= 'd0; 
                        video1_rd_en <= 'd0; 
                        video2_rd_en <= 'd0; 
                        video3_rd_en <= de_out_sync; 
                    end 
                end 
            end
            s5:begin
                r_vs_out_d0 <= vs_out_sync     ;
                r_vs_out    <= r_vs_out_d0     ;
                r_hs_out    <= hs_out_sync     ;
                r_de_out_d0 <= de_out_sync     ;
                r_de_out    <= r_de_out_d0     ;
                r_x_act_d0  <= x_act_sync      ;
                r_x_act     <= r_x_act_d0      ;
                if(vs_out_d0 && !vs_out_d1) begin
                    video_pre_rd_flag <= 'd0;
                end else if(!vs_out_d0 && vs_out_d1 && !video_pre_rd_flag && (fram0_done_1 || fram1_done_1 || fram2_done_1 || fram3_done_1)) begin
                    video0_rd_en      <= 'd1;
                    video1_rd_en      <= 'd1;
                    video2_rd_en      <= 'd1;
                    video3_rd_en      <= 'd1;
                    video_pre_rd_flag <= 'd1;
                end else begin
                    if( fram0_done_1 && (r_x_act >= 0) && (r_x_act < ZOOM_VIDEO_LENGTH - 1) && (y_act_sync < ZOOM_VIDEO_HIGTH ) && (y_act_sync >= 0)) begin
                        r_r_out  <=  video0_data_out[31:24];
                        r_g_out  <=  video0_data_out[21:14];
                        r_b_out  <=  video0_data_out[11: 4];  
                        video0_rd_en <= de_out_sync; //pre-read
                        video1_rd_en <= 'd0; 
                        video2_rd_en <= 'd0; 
                        video3_rd_en <= 'd0; 
                        if(r_x_act == ZOOM_VIDEO_LENGTH - 2) begin
                            video1_rd_en <= de_out_sync;
                            video0_rd_en <= 'd0;
                        end
                    end
                    if(fram1_done_1 &&(r_x_act >= ZOOM_VIDEO_LENGTH - 1) && (r_x_act < VIDEO_LENGTH - 1) && (y_act_sync < ZOOM_VIDEO_HIGTH )&& (y_act_sync >= 0)) begin
                        r_r_out  <= video1_data_out[31:24];
                        r_g_out  <= video1_data_out[21:14];
                        r_b_out  <= video1_data_out[11: 4];
                        video0_rd_en <= 'd0; 
                        video1_rd_en <= de_out_sync; 
                        video2_rd_en <= 'd0; 
                        video3_rd_en <= 'd0; 
                    end  
                    if( fram2_done_1 &&(r_x_act >= 0) && (r_x_act < ZOOM_VIDEO_LENGTH - 1) && (y_act_sync < VIDEO_HIGTH )&& (y_act_sync >= ZOOM_VIDEO_HIGTH)) begin
                        r_r_out  <= BLUE[23:16] ;
                        r_g_out  <= BLUE[15:8]  ;
                        r_b_out  <= BLUE[7: 0]  ;  
                        video0_rd_en <= 'd0; 
                        video1_rd_en <= 'd0; 
                        video2_rd_en <= 'd0; 
                        video3_rd_en <= 'd0; 
                        if(r_x_act == ZOOM_VIDEO_LENGTH - 2) begin
                            video3_rd_en <= 'd0;
                            video2_rd_en <= 'd0;
                        end
                    end    
                    if(fram3_done_1 &&(r_x_act >= ZOOM_VIDEO_LENGTH - 1) && (r_x_act < VIDEO_LENGTH - 1) && (y_act_sync < VIDEO_HIGTH )&& (y_act_sync >= ZOOM_VIDEO_HIGTH)) begin//实际上是r_x_act 0~63
                        r_r_out  <= BLUE[23:16];
                        r_g_out  <= BLUE[15:8] ;
                        r_b_out  <= BLUE[7: 0] ;     
                        video0_rd_en <= 'd0; 
                        video1_rd_en <= 'd0; 
                        video2_rd_en <= 'd0; 
                        video3_rd_en <= 'd0; 
                    end 
                end 
            end
            
            s6:begin
                r_vs_out_d0 <= vs_out_sync     ;
                r_vs_out    <= r_vs_out_d0     ;
                r_hs_out    <= hs_out_sync     ;
                r_de_out_d0 <= de_out_sync     ;
                r_de_out    <= r_de_out_d0     ;
                r_x_act_d0  <= x_act_sync      ;
                r_x_act     <= r_x_act_d0      ;
                if(vs_out_d0 && !vs_out_d1) begin
                    video_pre_rd_flag <= 'd0;
                end else if(!vs_out_d0 && vs_out_d1 && !video_pre_rd_flag && (fram0_done_1 || fram1_done_1 || fram2_done_1 || fram3_done_1)) begin
                    video0_rd_en      <= 'd1;
                    video1_rd_en      <= 'd1;
                    video2_rd_en      <= 'd1;
                    video3_rd_en      <= 'd1;
                    video_pre_rd_flag <= 'd1;
                end else begin
                    if( fram0_done_1 && (r_x_act >= 0) && (r_x_act < ZOOM_VIDEO_LENGTH - 1) && (y_act_sync < ZOOM_VIDEO_HIGTH ) && (y_act_sync >= 0)) begin
                        r_r_out  <=  video0_data_out[31:24];
                        r_g_out  <=  video0_data_out[21:14];
                        r_b_out  <=  video0_data_out[11: 4];  
                        video0_rd_en <= de_out_sync; //pre-read
                        video1_rd_en <= 'd0; 
                        video2_rd_en <= 'd0; 
                        video3_rd_en <= 'd0; 
                        if(r_x_act == ZOOM_VIDEO_LENGTH - 2) begin
                            video2_rd_en <= de_out_sync;
                            video0_rd_en <= 'd0;
                        end
                    end
                    if(fram2_done_1 &&(r_x_act >= ZOOM_VIDEO_LENGTH - 1) && (r_x_act < VIDEO_LENGTH - 1) && (y_act_sync < ZOOM_VIDEO_HIGTH )&& (y_act_sync >= 0)) begin
                        r_r_out  <=  video2_data_out[31:24] ;
                        r_g_out  <=  video2_data_out[21:14] ;
                        r_b_out  <=  video2_data_out[11: 4] ;
                        video0_rd_en <= 'd0; 
                        video1_rd_en <= 'd0; 
                        video2_rd_en <= de_out_sync; 
                        video3_rd_en <= 'd0; 
                    end  
                    if( fram1_done_1 &&(r_x_act >= 0) && (r_x_act < ZOOM_VIDEO_LENGTH - 1) && (y_act_sync < VIDEO_HIGTH )&& (y_act_sync >= ZOOM_VIDEO_HIGTH)) begin
                        r_r_out  <= BLUE[23:16];
                        r_g_out  <= BLUE[15:8] ;
                        r_b_out  <= BLUE[7: 0] ;  
                        video0_rd_en <= 'd0; 
                        video1_rd_en <= 'd0; 
                        video2_rd_en <= 'd0; 
                        video3_rd_en <= 'd0; 
                        if(r_x_act == ZOOM_VIDEO_LENGTH - 2) begin
                            video3_rd_en <= 'd0;
                            video2_rd_en <= 'd0;
                        end
                    end    
                    if(fram3_done_1 &&(r_x_act >= ZOOM_VIDEO_LENGTH - 1) && (r_x_act < VIDEO_LENGTH - 1) && (y_act_sync < VIDEO_HIGTH )&& (y_act_sync >= ZOOM_VIDEO_HIGTH)) begin//实际上是r_x_act 0~63
                        r_r_out  <=  BLUE[23:16];
                        r_g_out  <=  BLUE[15:8] ;
                        r_b_out  <=  BLUE[7: 0] ;     
                        video0_rd_en <= 'd0; 
                        video1_rd_en <= 'd0; 
                        video2_rd_en <= 'd0; 
                        video3_rd_en <= 'd0; 
                    end 
                end 
            end
            
            s7:begin
                r_vs_out_d0 <= vs_out_sync     ;
                r_vs_out    <= r_vs_out_d0     ;
                r_hs_out    <= hs_out_sync     ;
                r_de_out_d0 <= de_out_sync     ;
                r_de_out    <= r_de_out_d0     ;
                r_x_act_d0  <= x_act_sync      ;
                r_x_act     <= r_x_act_d0      ;
                if(vs_out_d0 && !vs_out_d1) begin
                    video_pre_rd_flag <= 'd0;
                end else if(!vs_out_d0 && vs_out_d1 && !video_pre_rd_flag && (fram0_done_1 || fram1_done_1 || fram2_done_1 || fram3_done_1)) begin
                    video0_rd_en      <= 'd1;
                    video1_rd_en      <= 'd1;
                    video2_rd_en      <= 'd1;
                    video3_rd_en      <= 'd1;
                    video_pre_rd_flag <= 'd1;
                end else begin
                    if( fram0_done_1 && (r_x_act >= 0) && (r_x_act < ZOOM_VIDEO_LENGTH - 1) && (y_act_sync < ZOOM_VIDEO_HIGTH ) && (y_act_sync >= 0)) begin
                        r_r_out  <=  video0_data_out[31:24];
                        r_g_out  <=  video0_data_out[21:14];
                        r_b_out  <=  video0_data_out[11: 4];  
                        video0_rd_en <= de_out_sync; //pre-read
                        video1_rd_en <= 'd0; 
                        video2_rd_en <= 'd0; 
                        video3_rd_en <= 'd0; 
                        if(r_x_act == ZOOM_VIDEO_LENGTH - 2) begin
                            video3_rd_en <= de_out_sync;
                            video0_rd_en <= 'd0;
                        end
                    end
                    if(fram3_done_1 &&(r_x_act >= ZOOM_VIDEO_LENGTH - 1) && (r_x_act < VIDEO_LENGTH - 1) && (y_act_sync < ZOOM_VIDEO_HIGTH )&& (y_act_sync >= 0)) begin
                        r_r_out  <=  video3_data_out[31:24] ;
                        r_g_out  <=  video3_data_out[21:14] ;
                        r_b_out  <=  video3_data_out[11: 4] ;
                        video0_rd_en <= 'd0; 
                        video1_rd_en <= 'd0; 
                        video2_rd_en <= 'd0; 
                        video3_rd_en <= de_out_sync; 
                    end  
                    if( fram2_done_1 &&(r_x_act >= 0) && (r_x_act < ZOOM_VIDEO_LENGTH - 1) && (y_act_sync < VIDEO_HIGTH )&& (y_act_sync >= ZOOM_VIDEO_HIGTH)) begin
                        r_r_out  <= BLUE[23:16];
                        r_g_out  <= BLUE[15:8] ;
                        r_b_out  <= BLUE[7: 0] ;  
                        video0_rd_en <= 'd0; 
                        video1_rd_en <= 'd0; 
                        video2_rd_en <= 'd0; 
                        video3_rd_en <= 'd0; 
                        if(r_x_act == ZOOM_VIDEO_LENGTH - 2) begin
                            video3_rd_en <= 'd0;
                            video2_rd_en <= 'd0;
                        end
                    end    
                    if(fram1_done_1 &&(r_x_act >= ZOOM_VIDEO_LENGTH - 1) && (r_x_act < VIDEO_LENGTH - 1) && (y_act_sync < VIDEO_HIGTH )&& (y_act_sync >= ZOOM_VIDEO_HIGTH)) begin//实际上是r_x_act 0~63
                        r_r_out  <=  BLUE[23:16];
                        r_g_out  <=  BLUE[15:8] ;
                        r_b_out  <=  BLUE[7: 0] ;     
                        video0_rd_en <= 'd0; 
                        video1_rd_en <= 'd0; 
                        video2_rd_en <= 'd0; 
                        video3_rd_en <= 'd0; 
                    end 
                end 
            end
            s8:begin
                r_vs_out_d0 <= vs_out_sync     ;
                r_vs_out    <= r_vs_out_d0     ;
                r_hs_out    <= hs_out_sync     ;
                r_de_out_d0 <= de_out_sync     ;
                r_de_out    <= r_de_out_d0     ;
                r_x_act_d0  <= x_act_sync      ;
                r_x_act     <= r_x_act_d0      ;
                if(vs_out_d0 && !vs_out_d1) begin
                    video_pre_rd_flag <= 'd0;
                end else if(!vs_out_d0 && vs_out_d1 && !video_pre_rd_flag && (fram0_done_1 || fram1_done_1 || fram2_done_1 || fram3_done_1)) begin
                    video0_rd_en      <= 'd1;
                    video1_rd_en      <= 'd1;
                    video2_rd_en      <= 'd1;
                    video3_rd_en      <= 'd1;
                    video_pre_rd_flag <= 'd1;
                end else begin
                    if( fram1_done_1 && (r_x_act >= 0) && (r_x_act < ZOOM_VIDEO_LENGTH - 1) && (y_act_sync < ZOOM_VIDEO_HIGTH ) && (y_act_sync >= 0)) begin
                        r_r_out  <=  video1_data_out[31:24];
                        r_g_out  <=  video1_data_out[21:14];
                        r_b_out  <=  video1_data_out[11: 4];  
                        video0_rd_en <= 'd0; //pre-read
                        video1_rd_en <= de_out_sync; 
                        video2_rd_en <= 'd0; 
                        video3_rd_en <= 'd0; 
                        if(r_x_act == ZOOM_VIDEO_LENGTH - 2) begin
                            video2_rd_en <= de_out_sync;
                            video0_rd_en <= 'd0;
                        end
                    end
                    if(fram2_done_1 &&(r_x_act >= ZOOM_VIDEO_LENGTH - 1) && (r_x_act < VIDEO_LENGTH - 1) && (y_act_sync < ZOOM_VIDEO_HIGTH )&& (y_act_sync >= 0)) begin
                        r_r_out  <=  video2_data_out[31:24] ;
                        r_g_out  <=  video2_data_out[21:14] ;
                        r_b_out  <=  video2_data_out[11: 4] ;
                        video0_rd_en <= 'd0; 
                        video1_rd_en <= 'd0; 
                        video2_rd_en <= de_out; 
                        video3_rd_en <= 'd0; 
                    end  
                    if( fram0_done_1 &&(r_x_act >= 0) && (r_x_act < ZOOM_VIDEO_LENGTH - 1) && (y_act_sync < VIDEO_HIGTH )&& (y_act_sync >= ZOOM_VIDEO_HIGTH)) begin
                        r_r_out  <= BLUE[23:16];
                        r_g_out  <= BLUE[15:8] ;
                        r_b_out  <= BLUE[7: 0] ;  
                        video0_rd_en <= 'd0; 
                        video1_rd_en <= 'd0; 
                        video2_rd_en <= 'd0; 
                        video3_rd_en <= 'd0; 
                        if(r_x_act == ZOOM_VIDEO_LENGTH - 2) begin
                            video3_rd_en <= 'd0;
                            video2_rd_en <= 'd0;
                        end
                    end    
                    if(fram3_done_1 &&(r_x_act >= ZOOM_VIDEO_LENGTH - 1) && (r_x_act < VIDEO_LENGTH - 1) && (y_act_sync < VIDEO_HIGTH )&& (y_act_sync >= ZOOM_VIDEO_HIGTH)) begin//实际上是r_x_act 0~63
                        r_r_out  <=  BLUE[23:16];
                        r_g_out  <=  BLUE[15:8] ;
                        r_b_out  <=  BLUE[7: 0] ;     
                        video0_rd_en <= 'd0; 
                        video1_rd_en <= 'd0; 
                        video2_rd_en <= 'd0; 
                        video3_rd_en <= 'd0; 
                    end 
                end 
            end
            
            s9:begin
                r_vs_out_d0 <= vs_out_sync     ;
                r_vs_out    <= r_vs_out_d0     ;
                r_hs_out    <= hs_out_sync     ;
                r_de_out_d0 <= de_out_sync     ;
                r_de_out    <= r_de_out_d0     ;
                r_x_act_d0  <= x_act_sync      ;
                r_x_act     <= r_x_act_d0      ;
                if(vs_out_d0 && !vs_out_d1) begin
                    video_pre_rd_flag <= 'd0;
                end else if(!vs_out_d0 && vs_out_d1 && !video_pre_rd_flag && (fram0_done_1 || fram1_done_1 || fram2_done_1 || fram3_done_1)) begin
                    video0_rd_en      <= 'd1;
                    video1_rd_en      <= 'd1;
                    video2_rd_en      <= 'd1;
                    video3_rd_en      <= 'd1;
                    video_pre_rd_flag <= 'd1;
                end else begin
                    if( fram1_done_1 && (r_x_act >= 0) && (r_x_act < ZOOM_VIDEO_LENGTH - 1) && (y_act_sync < ZOOM_VIDEO_HIGTH ) && (y_act_sync >= 0)) begin
                        r_r_out  <=  video1_data_out[31:24];
                        r_g_out  <=  video1_data_out[21:14];
                        r_b_out  <=  video1_data_out[11: 4];  
                        video0_rd_en <= 'd0; //pre-read
                        video1_rd_en <= de_out_sync; 
                        video2_rd_en <= 'd0; 
                        video3_rd_en <= 'd0; 
                        if(r_x_act == ZOOM_VIDEO_LENGTH - 2) begin
                            video3_rd_en <= de_out_sync;
                            video0_rd_en <= 'd0;
                        end
                    end
                    if(fram3_done_1 &&(r_x_act >= ZOOM_VIDEO_LENGTH - 1) && (r_x_act < VIDEO_LENGTH - 1) && (y_act_sync < ZOOM_VIDEO_HIGTH )&& (y_act_sync >= 0)) begin
                        r_r_out  <=  video3_data_out[31:24] ;
                        r_g_out  <=  video3_data_out[21:14] ;
                        r_b_out  <=  video3_data_out[11: 4] ;
                        video0_rd_en <= 'd0; 
                        video1_rd_en <= 'd0; 
                        video2_rd_en <= 'd0; 
                        video3_rd_en <= de_out_sync; 
                    end  
                    if( fram0_done_1 &&(r_x_act >= 0) && (r_x_act < ZOOM_VIDEO_LENGTH - 1) && (y_act_sync < VIDEO_HIGTH )&& (y_act_sync >= ZOOM_VIDEO_HIGTH)) begin
                        r_r_out  <= BLUE[23:16];
                        r_g_out  <= BLUE[15:8] ;
                        r_b_out  <= BLUE[7: 0] ;  
                        video0_rd_en <= 'd0; 
                        video1_rd_en <= 'd0; 
                        video2_rd_en <= 'd0; 
                        video3_rd_en <= 'd0; 
                        if(r_x_act == ZOOM_VIDEO_LENGTH - 2) begin
                            video3_rd_en <= 'd0;
                            video2_rd_en <= 'd0;
                        end
                    end    
                    if(fram2_done_1 &&(r_x_act >= ZOOM_VIDEO_LENGTH - 1) && (r_x_act < VIDEO_LENGTH - 1) && (y_act_sync < VIDEO_HIGTH )&& (y_act_sync >= ZOOM_VIDEO_HIGTH)) begin//实际上是r_x_act 0~63
                        r_r_out  <=  BLUE[23:16];
                        r_g_out  <=  BLUE[15:8] ;
                        r_b_out  <=  BLUE[7: 0] ;     
                        video0_rd_en <= 'd0; 
                        video1_rd_en <= 'd0; 
                        video2_rd_en <= 'd0; 
                        video3_rd_en <= 'd0; 
                    end 
                end 
            end
            
            s10:begin
                r_vs_out_d0 <= vs_out_sync     ;
                r_vs_out    <= r_vs_out_d0     ;
                r_hs_out    <= hs_out_sync     ;
                r_de_out_d0 <= de_out_sync     ;
                r_de_out    <= r_de_out_d0     ;
                r_x_act_d0  <= x_act_sync      ;
                r_x_act     <= r_x_act_d0      ;
                if(vs_out_d0 && !vs_out_d1) begin
                    video_pre_rd_flag <= 'd0;
                end else if(!vs_out_d0 && vs_out_d1 && !video_pre_rd_flag && (fram0_done_1 || fram1_done_1 || fram2_done_1 || fram3_done_1)) begin
                    video0_rd_en      <= 'd1;
                    video1_rd_en      <= 'd1;
                    video2_rd_en      <= 'd1;
                    video3_rd_en      <= 'd1;
                    video_pre_rd_flag <= 'd1;
                end else begin
                    if( fram2_done_1 && (r_x_act >= 0) && (r_x_act < ZOOM_VIDEO_LENGTH - 1) && (y_act_sync < ZOOM_VIDEO_HIGTH ) && (y_act_sync >= 0)) begin
                        r_r_out  <=  video2_data_out[31:24];
                        r_g_out  <=  video2_data_out[21:14];
                        r_b_out  <=  video2_data_out[11: 4];  
                        video0_rd_en <= 'd0; //pre-read
                        video1_rd_en <= 'd0; 
                        video2_rd_en <= de_out_sync; 
                        video3_rd_en <= 'd0; 
                        if(r_x_act == ZOOM_VIDEO_LENGTH - 2) begin
                            video3_rd_en <= de_out_sync;
                            video0_rd_en <= 'd0;
                        end
                    end
                    if(fram3_done_1 &&(r_x_act >= ZOOM_VIDEO_LENGTH - 1) && (r_x_act < VIDEO_LENGTH - 1) && (y_act_sync < ZOOM_VIDEO_HIGTH )&& (y_act_sync >= 0)) begin
                        r_r_out  <=  video3_data_out[31:24] ;
                        r_g_out  <=  video3_data_out[21:14] ;
                        r_b_out  <=  video3_data_out[11: 4] ;
                        video0_rd_en <= 'd0; 
                        video1_rd_en <= 'd0; 
                        video2_rd_en <= 'd0; 
                        video3_rd_en <= de_out_sync; 
                    end  
                    if( fram0_done_1 &&(r_x_act >= 0) && (r_x_act < ZOOM_VIDEO_LENGTH - 1) && (y_act_sync < VIDEO_HIGTH )&& (y_act_sync >= ZOOM_VIDEO_HIGTH)) begin
                        r_r_out  <= BLUE[23:16];
                        r_g_out  <= BLUE[15:8] ;
                        r_b_out  <= BLUE[7: 0] ;  
                        video0_rd_en <= 'd0; 
                        video1_rd_en <= 'd0; 
                        video2_rd_en <= 'd0; 
                        video3_rd_en <= 'd0; 
                        if(r_x_act == ZOOM_VIDEO_LENGTH - 2) begin
                            video3_rd_en <= 'd0;
                            video2_rd_en <= 'd0;
                        end
                    end    
                    if(fram1_done_1 &&(r_x_act >= ZOOM_VIDEO_LENGTH - 1) && (r_x_act < VIDEO_LENGTH - 1) && (y_act_sync < VIDEO_HIGTH )&& (y_act_sync >= ZOOM_VIDEO_HIGTH)) begin//实际上是r_x_act 0~63
                        r_r_out  <=  BLUE[23:16];
                        r_g_out  <=  BLUE[15:8] ;
                        r_b_out  <=  BLUE[7: 0] ;     
                        video0_rd_en <= 'd0; 
                        video1_rd_en <= 'd0; 
                        video2_rd_en <= 'd0; 
                        video3_rd_en <= 'd0; 
                    end 
                end 
            end
            
            default:begin 
               r_vs_out     <=  vs_out_image   ;
               r_hs_out     <=  hs_out_image   ;
               r_de_out     <=  de_out_image   ;
               r_r_out      <=  r_out_image    ;
               r_g_out      <=  g_out_image    ;
               r_b_out      <=  b_out_image    ;
               video0_rd_en <=  1'b0           ;
               video1_rd_en <=  1'b0           ;
               video2_rd_en <=  1'b0           ;
               video3_rd_en <=  1'b0           ; 
            end
         endcase
   end    
end




always@(posedge pixclk_out_image)
begin
    if(~ddr_ip_rst_n_1)begin
        mode_hdmi_effect_flag_0 <= 'd0;
        mode_hdmi_effect_flag_1 <= 'd0;
    end else begin
        mode_hdmi_effect_flag_0 <= key_flag1[6];
        mode_hdmi_effect_flag_1 <= mode_hdmi_effect_flag_0;
    end
end


always@(posedge pixclk_out_image)
begin
    if(~ddr_ip_rst_n_1)begin
        mode_hdmi_effect_state <= state_x0;
    end else begin
        case(mode_hdmi_effect_state)
            state_x0:
                    if(mode_hdmi_effect_flag_1)begin
                        mode_hdmi_effect_state <= state_x1;
                    end else begin
                        mode_hdmi_effect_state <= state_x0;
                    end
            state_x1:
                    if(mode_hdmi_effect_flag_1)begin
                        mode_hdmi_effect_state <= state_x2;
                    end else begin
                        mode_hdmi_effect_state <= state_x1;
                    end
            state_x2:
                    if(mode_hdmi_effect_flag_1)begin
                        mode_hdmi_effect_state <= state_x3;
                    end else begin
                        mode_hdmi_effect_state <= state_x2;
                    end
            state_x3:
                    if(mode_hdmi_effect_flag_1)begin
                        mode_hdmi_effect_state <= state_x4;
                    end else begin
                        mode_hdmi_effect_state <= state_x3;
                    end
            state_x4:
                    if(mode_hdmi_effect_flag_1)begin
                        mode_hdmi_effect_state <= state_x0;
                    end else begin
                        mode_hdmi_effect_state <= state_x4;
                    end
           default:mode_hdmi_effect_state <= state_x0;
        endcase
    end
end
//---------------------------------------------------------------------------------------------------------------------------//
//The construction of uart frame:|  start  |  data type | data1 | data2  |         data_sum_check[7:0]            |    end  |//
//-------------------------------|  'h0a   |  (1,2,3,4) | 8B    |   8B   |  'h05 + (1,2,3,4) + data1 + data2      |   'hfa  |//
//---------------------------------------------------------------------------------------------------------------------------//
integer  ii;
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(!sys_rst_n)begin
        state_uart <= u0;
        uart_sum <= 'd0;
        uart_finish <= 'd0;
        uart_cnt <= 'd0;
        uart_error <= 'd0;
        for(ii = 0;ii < 4;ii = ii + 1)begin
            uart_cache[ii] <= 'd0;
        end
    end else begin
       case(state_uart) 
           u0:
                if(rx_en)begin
                     uart_finish <= 1'b0;
                     uart_error <= 1'b0 ;
                    if(rx_data == 8'h0a)begin
                        state_uart <= u1;
                        uart_sum <=  rx_data;
                     end else begin
                        state_uart <= u0;
                        uart_sum <=  'd0;
                     end
                end
           u1:
                if(rx_en)begin
                    if(rx_data == 8'h1)begin
                         state_uart <= u2;
                         uart_sum <= uart_sum + rx_data;
                    end else if(rx_data == 8'h2)begin
                         state_uart <= u3;
                         uart_sum <= uart_sum + rx_data;
                    end else if(rx_data == 8'h3)begin
                         state_uart <= u4;
                         uart_sum <= uart_sum + rx_data;
                    end else if(rx_data == 8'h4)begin
                         state_uart <= u5;
                         uart_sum <= uart_sum + rx_data;
                    end else begin
                         state_uart <= u0;
                         uart_sum <= 'd0;
                    end
                end
           u2:begin
                if(rx_en && uart_cnt == 'd0)begin
                    uart_cache[0] <= rx_data;
                    uart_cnt <= uart_cnt + 1'b1;
                    uart_sum <= uart_sum + rx_data;
                end else if(rx_en && uart_cnt == 'd1) begin
                    state_uart <= u6;
                    uart_cache[0] <= uart_cache[0] + rx_data;
                    uart_cnt <= 'd0;
                    uart_sum <= uart_sum + rx_data;
                end
              end
           u3:begin
                if(rx_en && uart_cnt == 'd0)begin
                    uart_cache[1] <= rx_data;
                    uart_cnt <= uart_cnt + 1'b1;
                    uart_sum <= uart_sum + rx_data;
                end else if(rx_en && uart_cnt == 'd1) begin
                    state_uart <= u6;
                    uart_cache[1] <= uart_cache[1] + rx_data;
                    uart_cnt <= 'd0;
                    uart_sum <= uart_sum + rx_data;
                end
              end
           u4:begin
                if(rx_en && uart_cnt == 'd0)begin
                    uart_cache[2] <= rx_data;
                    uart_cnt <= uart_cnt + 1'b1;
                    uart_sum <= uart_sum + rx_data;
                end else if(rx_en && uart_cnt == 'd1) begin
                    state_uart <= u6;
                    uart_cache[2] <= uart_cache[2] + rx_data;
                    uart_cnt <= 'd0;
                    uart_sum <= uart_sum + rx_data;
                end
              end
           u5:begin
                if(rx_en && uart_cnt == 'd0)begin
                    uart_cache[3] <= rx_data;
                    uart_cnt <= uart_cnt + 1'b1;
                    uart_sum <= uart_sum + rx_data;
                end else if(rx_en && uart_cnt == 'd1) begin
                    state_uart <= u6;
                    uart_cache[3] <= uart_cache[3] + rx_data;
                    uart_cnt <= 'd0;
                    uart_sum <= uart_sum + rx_data;
                end
              end
           u6:
                if(rx_en)begin
                    if(uart_sum[7:0] == rx_data)begin
                        state_uart <= u7;
                    end else begin
                        state_uart <= u0;
                        uart_error <= 1'b1;
                    end
                end
           u7:
                if(rx_en)begin
                    if(rx_data == 8'hfa)begin
                         state_uart <= u0;
                         uart_finish <= 1'b1;
                    end else begin
                         uart_error <= 1'b1;
                         state_uart <= u0;
                    end
                end
           default:state_uart <= u0;
        endcase 
    end
end


always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(!sys_rst_n)begin
        bright_value_offset      <= 'd0;
        contrast_value_offset    <= 'd0;
        saturation_value_offset  <= 'd0;
        relief_value_offset      <= 'd0;
    end else if(uart_finish) begin
        bright_value_offset      <= uart_cache[0]      ;
        contrast_value_offset    <= uart_cache[1]      ;
        saturation_value_offset  <= uart_cache[2]      ;
        relief_value_offset      <= uart_cache[3][7:0] ;
    end else begin
        bright_value_offset      <= bright_value_offset     ;    
        contrast_value_offset    <= contrast_value_offset   ;
        saturation_value_offset  <= saturation_value_offset ;
        relief_value_offset      <= relief_value_offset     ;
    end
end



always @(posedge cfg_clk)
begin
    if(!locked)
        rstn_1ms <= 16'd0;
    else
    begin
        if(rstn_1ms == 16'h2710)
            rstn_1ms <= rstn_1ms;
        else
            rstn_1ms <= rstn_1ms + 1'b1;
    end
end


/****************************************INST****************************************/

    PLL u_pll (
      .clkin1       (sys_clk   ),   // input//50MHz
      .pll_lock     (locked    ),   // output
      .clkout0      (cfg_clk   ),    // output//10MHz
      .clkout1      (pix_clk   )    //output//25MHz
    );

    ms72xx_ctl ms72xx_ctl(
        .clk         (  cfg_clk    ), //input       clk,
        .rst_n       (  rstn_out   ), //input       rstn,
                                
        .init_over   (  init_over  ), //output      init_over,
        .iic_tx_scl  (  iic_tx_scl ), //output      iic_scl,
        .iic_tx_sda  (  iic_tx_sda ), //inout       iic_sda
        .iic_scl     (  iic_scl    ), //output      iic_scl,
        .iic_sda     (  iic_sda    )  //inout       iic_sda
    );

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
hdmi_loop_revised
#(
     .x0                   ( state_x0  ),
     .x1                   ( state_x1  ),
     .x2                   ( state_x2  ),
     .x3                   ( state_x3  ),
     .x4                   ( state_x4  )
)
hdmi_loop_inst
(
   .sys_clk     (sys_clk         )  ,     // input system clock 50MHz
   .init_over   (init_over       )  ,
 
   .pixclk_in   (pixclk_in       )  ,                            
   .vs_in       (vs_in           )  , 
   .hs_in       (hs_in           )  , 
   .de_in       (de_in           )  ,
   .r_in        (r_in            )  , 
   .g_in        (g_in            )  , 
   .b_in        (b_in            )  ,  
   .bright_adjust_val    ( B_value     )  ,
   .contrast_adjust_val  ( C_value     )  ,
   .saturation_adjust_val( S_value     )  ,
   .TH                   ( R_value     )  ,
   
   .state_current(mode_hdmi_effect_state)  ,
   
   .pixclk_out  (pixclk_out_image)  ,                            
   .vs_out      (vs_out_image    )  , 
   .hs_out      (hs_out_image    )  , 
   .de_out      (de_out_image    )  ,
   .r_out       (r_out_image     )  , 
   .g_out       (g_out_image     )  , 
   .b_out       (b_out_image     )  
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
    .rst_n       ( rst_n_addac_out  )  ,
    .rstn_out    ( rstn_out         )  ,
   
    .fft_data    (data_modulus      )  , 
    .fft_sop     (data_sop          )  , 
    .fft_eop     (data_eop          )  , 
    .fft_valid   (data_valid        )  , 
    
    .audio_data  ({8'b0,da_data}    )  ,
    .audio_en    (  da_en           )  ,
    .audio_clk   (da_clk            )  ,
    
    .pix_clk     ( pix_clk          )  ,

    .vs_out      (vs_out_adc        )  , 
    .hs_out      (hs_out_adc        )  , 
    .de_out      (de_out_adc        )  ,
    .r_out       (r_out_adc         )  , 
    .g_out       (g_out_adc         )  , 
    .b_out       (b_out_adc         )  
);


//multi-paths HDMI
ipsxb_rst_sync_v1_1 u_core_clk_rst_sync(
    .clk                        (sys_clk         ),
    .rst_n                      (sys_rst_n       ),
    .sig_async                  (1'b1            ),
    .sig_synced                 (ddr_ip_rst_n    )
);


sync_generator user_sync_gen
(
    .clk       (pixclk_out_image             ),
    .rstn      (ddr_ip_rst_n_1 && ddr_init_done_1),
    .vs_out    (vs_out_sync                  ),
    .hs_out    (hs_out_sync                  ),
    .de_out    (de_out_sync                  ),
    .de_re     (                             ),
    .x_act     (x_act_sync                   ),
    .y_act     (y_act_sync                   )
);




video_zoom hdmi_video_zoom
(
    .clk                (pixclk_in                    ),
    .rstn               (ddr_ip_rst_n_1 && ddr_init_done_1),
    .vs_in              (vs_in                        ) ,
    .hs_in              (hs_in                        ) ,
    .de_in              (de_in                        ) ,
    .video_data_in      (rgb_in                       ),
    .de_out             (zoom_de_out                  ),
    .video_data_out     (zoom_data_out                )
   );


axi_m_arbitration 
#(
    .VIDEO_LENGTH     (VIDEO_LENGTH     ) ,
    .VIDEO_HIGTH      (VIDEO_HIGTH      ) ,
    .ZOOM_VIDEO_LENGTH(ZOOM_VIDEO_LENGTH) ,
    .ZOOM_VIDEO_HIGTH (ZOOM_VIDEO_HIGTH ) ,
    .PIXEL_WIDTH      (PIXEL_WIDTH      ) ,
	.CTRL_ADDR_WIDTH  (CTRL_ADDR_WIDTH  ) ,
	.DQ_WIDTH	      (DQ_WIDTH         ) ,
    .M_AXI_BRUST_LEN  (M_AXI_BRUST_LEN  )
)
user_axi_m_arbitration (
	.DDR_INIT_DONE           (ddr_init_done),
	.M_AXI_ACLK              (ddr_ip_clk   ),
	.M_AXI_ARESETN           (ddr_ip_rst_n  && ddr_init_done),
    .pix_clk_out             (pixclk_out_image),//1080p 148.5m
      
                                                             
	.M_AXI_AWID              (M_AXI_AWID   ),
	.M_AXI_AWADDR            (M_AXI_AWADDR ),

	.M_AXI_AWUSER            (M_AXI_AWUSER ),
	.M_AXI_AWVALID           (M_AXI_AWVALID),
	.M_AXI_AWREADY           (M_AXI_AWREADY),
                                                             
	.M_AXI_WDATA             (M_AXI_WDATA  ),
	.M_AXI_WSTRB             (M_AXI_WSTRB  ),
	.M_AXI_WLAST             (M_AXI_WLAST  ),
	.M_AXI_WUSER             (M_AXI_WUSER  ),
	.M_AXI_WREADY            (M_AXI_WREADY ),
                                                             
	.M_AXI_ARID              (M_AXI_ARID   ),
    .M_AXI_ARUSER            (M_AXI_ARUSER ),
	.M_AXI_ARADDR            (M_AXI_ARADDR ),

	.M_AXI_ARVALID           (M_AXI_ARVALID),
	.M_AXI_ARREADY           (M_AXI_ARREADY),
	                                                       
	.M_AXI_RID               (M_AXI_RID    ),
	.M_AXI_RDATA             (M_AXI_RDATA  ),
	.M_AXI_RLAST             (M_AXI_RLAST  ),
	.M_AXI_RVALID            (M_AXI_RVALID ),

    .vs_in                   (vs_in        ),
    .vs_out                  (vs_out_sync  ),
       
    .video0_clk_in           (pixclk_in    ),                                                                                                                  
    .video0_de_in            (zoom_de_out  ),
    .video0_data_in          (zoom_data_out  ),
    .video0_rd_en            (video0_rd_en   ),
    .video0_data_out         (video0_data_out),
    .fram0_done              (fram0_done     ),
    .video0_vs_in            (vs_in ),

    .video1_clk_in           (pixclk_in),                                                               
    .video1_de_in            (zoom_de_out    ),
    .video1_data_in          (zoom_data_out  ),
    .video1_rd_en            (video1_rd_en   ),
    .video1_data_out         (video1_data_out),
    .fram1_done              (fram1_done     ),
    .video1_vs_in            (vs_in ),
                               
    .video2_clk_in           (pixclk_in),                       
    .video2_de_in            (zoom_de_out ),
    .video2_data_in          (zoom_data_out),
    .video2_rd_en            (video2_rd_en   ),
    .video2_data_out         (video2_data_out),
    .fram2_done              (fram2_done     ),
    .video2_vs_in            (vs_in),
                                       
    .video3_clk_in           (pixclk_in),                       
    .video3_de_in            (zoom_de_out    ),
    .video3_data_in          (zoom_data_out),
    .video3_rd_en            (video3_rd_en   ),
    .video3_data_out         (video3_data_out),
    .fram3_done              (fram3_done     ),
    .video3_vs_in            (vs_in ),

    .wr_addr_min             (RW_ADDR_MIN),
    .wr_addr_max             (RW_ADDR_MAX), 
    .y_act                   (y_act_sync)        , 
    .x_act                   (x_act_sync)  

);


ddr_test  #
  (
   //***************************************************************************
   // The following parameters are Memory Feature
   //***************************************************************************
   .MEM_ROW_WIDTH          (MEM_ROW_ADDR_WIDTH),     
   .MEM_COLUMN_WIDTH       (MEM_COL_ADDR_WIDTH),     
   .MEM_BANK_WIDTH         (MEM_BADDR_WIDTH   ),     
   .MEM_DQ_WIDTH           (MEM_DQ_WIDTH      ),    
   .MEM_DM_WIDTH           (MEM_DM_WIDTH      ),     
   .MEM_DQS_WIDTH          (MEM_DQS_WIDTH     ),     
   .CTRL_ADDR_WIDTH        (CTRL_ADDR_WIDTH   )    
  )
  I_ipsxb_ddr_top(
   .ref_clk                (sys_clk                ),
   .resetn                 (ddr_ip_rst_n           ),
   .ddr_init_done          (ddr_init_done          ),
   .ddrphy_clkin           (ddr_ip_clk             ),
   .pll_lock               (ddr_pll_lock           ), 

   .axi_awaddr             (M_AXI_AWADDR           ),
   .axi_awuser_ap          (M_AXI_AWUSER           ),
   .axi_awuser_id          (M_AXI_AWID             ),
   .axi_awlen              (M_AXI_BRUST_LEN        ),
   .axi_awready            (M_AXI_AWREADY          ),
   .axi_awvalid            (M_AXI_AWVALID          ),
   
   .axi_wdata              (M_AXI_WDATA            ),
   .axi_wstrb              (M_AXI_WSTRB            ),
   .axi_wready             (M_AXI_WREADY           ),
   .axi_wusero_id          (M_AXI_WUSER            ),
   .axi_wusero_last        (M_AXI_WLAST            ),
            
   .axi_araddr             (M_AXI_ARADDR           ),
   .axi_aruser_ap          (M_AXI_ARUSER           ),
   .axi_aruser_id          (M_AXI_ARID             ),
   .axi_arlen              (M_AXI_BRUST_LEN        ),
   .axi_arready            (M_AXI_ARREADY          ),
   .axi_arvalid            (M_AXI_ARVALID          ),
    
   .axi_rdata              (M_AXI_RDATA             ),
   .axi_rid                (M_AXI_RID               ),
   .axi_rlast              (M_AXI_RLAST            ),
   .axi_rvalid             (M_AXI_RVALID           ),

   .apb_clk                (1'b0                   ),
   .apb_rst_n              (1'b1                   ),
   .apb_sel                (1'b0                   ),
   .apb_enable             (1'b0                   ),
   .apb_addr               (8'b0                   ),
   .apb_write              (1'b0                   ),
   .apb_ready              (                       ),
   .apb_wdata              (16'b0                  ),
   .apb_rdata              (                       ),
   .apb_int                (                       ),
   .debug_data             (                       ),
   .debug_slice_state      (                       ),
   .debug_calib_ctrl       (                       ),
   .ck_dly_set_bin         (                       ),
   .force_ck_dly_en        (1'b0                   ),
   .force_ck_dly_set_bin   (8'h05                  ),
   .dll_step               (                       ),
   .dll_lock               (                       ),
   .init_read_clk_ctrl     (2'b0                   ),                                                       
   .init_slip_step         (4'b0                   ), 
   .force_read_clk_ctrl    (1'b0                   ),  
   .ddrphy_gate_update_en  (1'b0                   ),
   .update_com_val_err_flag(                       ),
   .rd_fake_stop           (1'b0                   ),
   
   .mem_rst_n              (mem_rst_n              ),
   .mem_ck                 (mem_ck                 ),
   .mem_ck_n               (mem_ck_n               ),
   .mem_cke                (mem_cke                ),
   .mem_cs_n               (mem_cs_n               ),
   .mem_ras_n              (mem_ras_n              ),
   .mem_cas_n              (mem_cas_n              ),
   .mem_we_n               (mem_we_n               ),
   .mem_odt                (mem_odt                ),
   .mem_a                  (mem_a                  ),
   .mem_ba                 (mem_ba                 ),
   .mem_dqs                (mem_dqs                ),
   .mem_dqs_n              (mem_dqs_n              ),
   .mem_dq                 (mem_dq                 ),
   .mem_dm                 (mem_dm                 )
  );



//UART signal collection
uart_rx 
#(
   .BPS_NUM(16'd434) //115200
)
uart_rx1
(
     .clk            (sys_clk)  ,
     .uart_rx        (uart_rx)  ,
                   
     .rx_data        (rx_data)  ,
     .rx_en          (rx_en  )  ,
     .rx_finish      ()
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
    .cam_pclk           (pixclk_in       ), //input  图像时钟             
    .img_vsync          (vs_in          ), //input  帧同步               
    .img_data_en        (zoom_de_out          ), //input  de               
    .img_data           ({zoom_data_out[31:27],zoom_data_out[21:16],zoom_data_out[11:7]}), //input  [15:0]
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






