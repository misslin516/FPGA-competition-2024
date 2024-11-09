`timescale 1ns / 1ps
//created by:****
//created date:2024/10/7
//Principle :Neighboring pixels are subtracted plus a constant threshold(TH)
module image_relief_effect(
   input wire clk,
   input wire reset,
   
   input wire valid_i,
   input wire [23:0] img_data_i,
   
   input wire vs_in, 
   input wire hs_in,
   
   input wire [7:0] TH, //阈值
   
   output wire vs_out,
   output wire hs_out,
   output reg valid_o,
   output reg [23:0] img_data_o
    );
 
    //常量声明
    wire rgb2gray_valid;
    wire [7:0] rgb2gray_data;
    
    reg rgb2gray_valid_d1;
    reg [7:0] rgb2gray_data_d1;

    wire [9:0] new_pix_val;
    wire [7:0] new_pix;
    
    wire     rgb2gray_vs_out;
    wire     rgb2gray_hs_out;

image_rgb2gray image_rgb2gray_inst
(
   .clk        (clk        ),
   .reset      (reset      ),

   .vs_in      (vs_in      ),
   .hs_in      (hs_in      ),

   .valid_i    (valid_i    ),
   .img_data_i (img_data_i ),
  
   .vs_out     (rgb2gray_vs_out     ),
   .hs_out     (rgb2gray_hs_out     ),
   .valid_o    (rgb2gray_valid    ),
   .img_data_o (rgb2gray_data )
);

    //打一拍
    always@(posedge clk) begin
        if(reset) begin
            rgb2gray_valid_d1 <= 'b0;
            rgb2gray_data_d1 <= 'b0;
        end else begin
            rgb2gray_valid_d1 <= rgb2gray_valid;
            rgb2gray_data_d1 <= rgb2gray_data;
        end
    end

    //浮雕效果
    assign new_pix_val = rgb2gray_data_d1 - rgb2gray_data + TH;
    assign new_pix = new_pix_val[9] ? 0 : new_pix_val[8] ? 255 : new_pix_val[7:0];
    always@(posedge clk) begin
        if(reset) begin
            valid_o <= 'b0;
            img_data_o <= 'b0;
        end else begin
            valid_o <= rgb2gray_valid_d1;
            img_data_o <= {3{new_pix}};
        end
    end  

    reg [1:0] rgb2gray_vs_out_0;
    reg [1:0] rgb2gray_hs_out_0;

    always@(posedge clk)begin
        if(reset)begin
            rgb2gray_vs_out_0 <= 'd0;
            rgb2gray_hs_out_0 <= 'd0;
        end else begin
            rgb2gray_vs_out_0 <= {rgb2gray_vs_out_0[0],rgb2gray_vs_out};
            rgb2gray_hs_out_0 <= {rgb2gray_hs_out_0[0],rgb2gray_hs_out};
        end
    end
    
    assign vs_out = rgb2gray_vs_out_0[1];
    assign hs_out = rgb2gray_hs_out_0[1];
    
endmodule
