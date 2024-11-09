`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:Meyesemi 
// Engineer: Will
// 
// Create Date: 2023-01-29 20:31  
// Design Name:  
// Module Name: 
// Project Name: 
// Target Devices: Pango
// Tool Versions: 
// Description: 
//      
// Dependencies: 
// 
// Revision:V2.0
// Revision date:2024/10/07
// Revision 1.0 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`define UD #1
//Revised by:****
//Revised date:2024/10/8

module hdmi_loop_revised
#(
    parameter  x0 = 4'b0000                ,
    parameter  x1 = 4'b0001                ,
    parameter  x2 = 4'b0010                ,
    parameter  x3 = 4'b0100                ,
    parameter  x4 = 4'b1000                
)
(
    input wire        sys_clk,     // input system clock 50MHz
    input             init_over,
  
    input             pixclk_in,                            
    input             vs_in, 
    input             hs_in, 
    input             de_in,
    input     [7:0]   r_in, 
    input     [7:0]   g_in, 
    input     [7:0]   b_in,  
    
    input     [8:0] bright_adjust_val    ,
    input     [8:0] contrast_adjust_val  , 
    input     [8:0] saturation_adjust_val,
    input     [7:0] TH                   ,
    
    input     [3:0]   state_current,

    output               pixclk_out,                            
    output reg           vs_out, 
    output reg           hs_out, 
    output reg           de_out,
    output reg    [7:0]  r_out, 
    output reg    [7:0]  g_out, 
    output reg    [7:0]  b_out
);
/*****************************parameter*************************************/
    parameter   X_WIDTH = 4'd12;
    parameter   Y_WIDTH = 4'd12;    
//MODE_1080p
    parameter V_TOTAL = 12'd1125;
    parameter V_FP = 12'd4;
    parameter V_BP = 12'd36;
    parameter V_SYNC = 12'd5;
    parameter V_ACT = 12'd1080;
    parameter H_TOTAL = 12'd2200;
    parameter H_FP = 12'd88;
    parameter H_BP = 12'd148;
    parameter H_SYNC = 12'd44;
    parameter H_ACT = 12'd1920;
    parameter HV_OFFSET = 12'd0;
   
 /*****************************wire*************************************/   
    wire        pix_clk        ;
    wire        cfg_clk        ;
    wire        locked         ;
    wire        vs_out_0       ;    
    wire        hs_out_0       ;    
    wire        de_out_0       ;    
    wire[7:0]   r_out_0        ;
    wire[7:0]   g_out_0        ;
    wire[7:0]   b_out_0        ;
           
    wire        vs_out_1       ;    
    wire        hs_out_1       ;    
    wire        de_out_1       ;    
    wire[7:0]   r_out_1        ;
    wire[7:0]   g_out_1        ;
    wire[7:0]   b_out_1        ;   
       
    wire        vs_out_2       ;    
    wire        hs_out_2       ;    
    wire        de_out_2       ;    
    wire[7:0]   r_out_2        ;
    wire[7:0]   g_out_2        ;
    wire[7:0]   b_out_2        ; 
           
    wire        vs_out_3       ;    
    wire        hs_out_3       ;    
    wire        de_out_3       ;    
    wire[7:0]   r_out_3        ;
    wire[7:0]   g_out_3        ;
    wire[7:0]   b_out_3        ; 
 /*****************************reg*************************************/   
    // reg [15:0]  rstn_1ms       ; 
 /*****************************assign*************************************/   
    // assign    led_int  =  init_over; 
    // assign rstn_out = (rstn_1ms == 16'h2710);
    //HDMI_OUT  =  HDMI_IN 

    assign pixclk_out   =  pixclk_in    ;
    
 /*****************************always*************************************/   
  // always @(posedge cfg_clk)
    // begin
    	// if(!locked)
    	    // rstn_1ms <= 16'd0;
    	// else
    	// begin
    		// if(rstn_1ms == 16'h2710)
    		    // rstn_1ms <= rstn_1ms;
    		// else
    		    // rstn_1ms <= rstn_1ms + 1'b1;
    	// end
    // end
    
 
    always@(posedge pixclk_out)
    begin
        if(!init_over)begin
            vs_out       <=  1'b0        ;
            hs_out       <=  1'b0        ;
            de_out       <=  1'b0        ;
            r_out        <=  8'b0        ;
            g_out        <=  8'b0        ;
            b_out        <=  8'b0        ;
        end else begin
            case(state_current)
                x0:begin
                   vs_out       <=  vs_in           ;
                   hs_out       <=  hs_in           ;
                   de_out       <=  de_in           ;
                   r_out        <=  r_in            ;
                   g_out        <=  g_in            ;
                   b_out        <=  b_in            ; 
                end  
                x1:begin
                   vs_out       <=  vs_out_0        ;
                   hs_out       <=  hs_out_0        ;
                   de_out       <=  de_out_0        ;
                   r_out        <=  r_out_0         ;
                   g_out        <=  g_out_0         ;
                   b_out        <=  b_out_0         ;
                end
                x2:begin
                   vs_out       <=  vs_out_1        ;
                   hs_out       <=  hs_out_1        ;
                   de_out       <=  de_out_1        ;
                   r_out        <=  r_out_1         ;
                   g_out        <=  g_out_1         ;
                   b_out        <=  b_out_1         ;
                end
                x3:begin
                   vs_out       <=  vs_out_2        ;
                   hs_out       <=  hs_out_2        ;
                   de_out       <=  de_out_2        ;
                   r_out        <=  r_out_2         ;
                   g_out        <=  g_out_2         ;
                   b_out        <=  b_out_2         ;
                end
                x4:begin
                   vs_out       <=  vs_out_3        ;
                   hs_out       <=  hs_out_3        ;
                   de_out       <=  de_out_3        ;
                   r_out        <=  r_out_3         ;
                   g_out        <=  g_out_3         ;
                   b_out        <=  b_out_3         ;
                end
                default: begin
                   vs_out       <=  vs_in           ;
                   hs_out       <=  hs_in           ;
                   de_out       <=  de_in           ;
                   r_out        <=  r_in            ;
                   g_out        <=  g_in            ;
                   b_out        <=  b_in            ; 
                 end
             endcase
        end
    end
 /*****************************INST*************************************/   
 

    // PLL u_pll (
      // .clkin1       (sys_clk   ),   // input//50MHz
      // .pll_lock     (locked    ),   // output
      // .clkout0      (cfg_clk   )    // output//10MHz
    // );

    // ms72xx_ctl ms72xx_ctl(
        // .clk         (  cfg_clk    ), //input       clk,
        // .rst_n       (  rstn_out   ), //input       rstn,
                                
        // .init_over   (  init_over  ), //output      init_over,
        // .iic_tx_scl  (  iic_tx_scl ), //output      iic_scl,
        // .iic_tx_sda  (  iic_tx_sda ), //inout       iic_sda
        // .iic_scl     (  iic_scl    ), //output      iic_scl,
        // .iic_sda     (  iic_sda    )  //inout       iic_sda
    // );


image_bright_adjust image_bright_adjust_inst
(
   .clk        (pixclk_out               ) ,
   .reset      ((~init_over) & (~x1[0])) , //low power-consumption design
                                         
   .adjust_val (bright_adjust_val        ) ,//-255~255 signed
                                         
   .vs_in      (vs_in                    ) ,
   .hs_in      (hs_in                    ) ,   
                                         
   .valid_i    (de_in                    ) ,
   .img_data_i ({r_in,g_in,b_in}         ) ,
       
   .vs_out     (vs_out_0                 ) ,
   .hs_out     (hs_out_0                 ) ,
   .valid_o    (de_out_0                 ) ,
   .img_data_o ({r_out_0,g_out_0,b_out_0})
);



image_contrast_adjust image_contrast_adjust_inst
(
   .clk          (pixclk_out                          )  ,
   .reset        ((~init_over) & (~x2[1])       )  ,
 
   .adjust_val   (contrast_adjust_val                 )  ,//0~511 mapping to 0~2
       
   .vs_in        (vs_in                               )  ,
   .hs_in        (hs_in                               )  ,
    
   .valid_i      (de_in                               )  ,
   .img_data_i   ({r_in,g_in,b_in}                    )  ,
      
   .vs_out       (vs_out_1                            )  ,
   .hs_out       (hs_out_1                            )  ,
   .valid_o      (de_out_1                            )  ,
   .img_data_o   ({r_out_1,g_out_1,b_out_1}           )
    );

  

image_saturation_adjust image_saturation_adjust_inst
(
   .clk         (pixclk_out                   ),
   .reset       ((~init_over) & (~x3[2])),
   
   .adjust_val  (saturation_adjust_val        ),//-255~255 mapping to -1 ~ 1
   
   .vs_in       (vs_in                        ),
   .hs_in       (hs_in                        ),
  
   .valid_i     (de_in                        ),
   .img_data_i  ({r_in,g_in,b_in}             ),
  
   .vs_out      (vs_out_2                     ),
   .hs_out      (hs_out_2                     ),
   .valid_o     (de_out_2                     ),
   .img_data_o  ({r_out_2,g_out_2,b_out_2}    )
);




image_relief_effect image_relief_effect_inst
(
   .clk        (pixclk_out                        ),
   .reset      ((~init_over) & (~x4[3])     ),
  
   .valid_i    (de_in                             ),
   .img_data_i ({r_in,g_in,b_in}                  ),
 
   .vs_in      (vs_in                             ), 
   .hs_in      (hs_in                             ),
                           
   .TH         (TH                                ), //Threhold
   
   .vs_out     (vs_out_3                          ),
   .hs_out     (hs_out_3                          ),
   .valid_o    (de_out_3                          ),
   .img_data_o ({r_out_3,g_out_3,b_out_3}         )
    );


endmodule
