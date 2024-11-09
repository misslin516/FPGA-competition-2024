`timescale 1ns / 1ps
//created by:****
//created date:2024/10/7
//Principle:weighted mixture based on original image and grayscale image
module image_saturation_adjust(
   input wire clk,
   input wire reset,
   
   input wire [8:0] adjust_val,//-255~255 有符号数对应 -1 ~ 1
   
   input wire vs_in,
   input wire hs_in,
   
   input wire valid_i,
   input wire [23:0] img_data_i,
   
   
   output wire  vs_out,
   output wire  hs_out,
   output wire valid_o,
   output wire [23:0] img_data_o
    );

    //RGB颜色空间，饱和度调节
    //原图和灰度图进行加权组合即可改变图像的饱和度
    //Y = 0.2989*R + 0.5870*G + 0.1140*B;
    //R_new = -Y * value + R * (1+value);
    //G_new = -Y * value + G * (1+value);
    //B_new = -Y * value + B * (1+value);
    //value 范围 (-1~1)    

    //常量声明
    parameter C0 = 9'd306;//0.299*1024;
    parameter C1 = 10'd601;//0.587*1024;
    parameter C2 = 7'd117;//0.114*1024;

    //变量声明
    wire [7:0] R, G, B;
    reg valid_d1;
    reg [16:0] Y_R_m;
    reg [17:0] Y_G_m;
    reg [14:0] Y_B_m;
    reg [7:0] R_d1, G_d1, B_d1;
    reg [8:0] RGB_C;
    
    reg valid_d2;
    wire [17:0] Y_w;
    reg [7:0] Y;//最大值，当RGB都等于255时，(C0 + C1 + C2)*255 = 1024*255；不会出现负数
    reg [7:0] R_d2, G_d2, B_d2;
    reg Y_C_sign;
    reg [7:0] Y_C_abs;
    reg [8:0] RGB_C_d1;

    reg valid_d3;
    reg [16:0] Y_m;
    reg [16:0] R_m, G_m, B_m;
    
    reg valid_d4;
    wire [18:0] Y_m_s;
    wire [18:0] Y_R_m_s, Y_G_m_s, Y_B_m_s;
    reg [7:0] R_new, G_new, B_new;
    
    //Y=0.299*R十0.587*G+0.114*B
    assign {R, G, B} = img_data_i;
    always@(posedge clk or posedge reset) begin
        if(reset) begin
            valid_d1 <= 0;
            {Y_R_m, Y_G_m, Y_B_m} <= 0;
            {R_d1, G_d1, B_d1} <= 0;
            RGB_C <= 0;
        end else begin
            valid_d1 <= valid_i;
            Y_R_m <= R*C0;
            Y_G_m <= G*C1;
            Y_B_m <= B*C2;
            {R_d1, G_d1, B_d1} <= {R, G, B};
            RGB_C <= 255 + adjust_val;
        end
    end

    assign Y_w = Y_R_m + Y_G_m + Y_B_m;
    always@(posedge clk or posedge reset) begin
        if(reset) begin
            valid_d2 <= 0;
            Y <= 0;
            {R_d2, G_d2, B_d2} <= 0;
            {Y_C_sign, Y_C_abs} <= 0;
            RGB_C_d1 <= 0;
        end else begin
            valid_d2 <= valid_d1;
            Y <= Y_w[17:10];
            {R_d2, G_d2, B_d2} <= {R_d1, G_d1, B_d1};
            //求绝对值
            Y_C_sign <= adjust_val[8];
            Y_C_abs <= adjust_val[8] ? (~adjust_val[7:0] + 1) : adjust_val;
            RGB_C_d1 <= RGB_C;
        end
    end   

    always@(posedge clk or posedge reset) begin
        if(reset) begin
            valid_d3 <= 0;
            Y_m <= 0;
            {R_m, G_m, B_m} <= 0;
        end else begin
            valid_d3 <= valid_d2;
            Y_m <= Y*Y_C_abs;
            R_m <= R_d2*RGB_C_d1;
            G_m <= G_d2*RGB_C_d1;
            B_m <= B_d2*RGB_C_d1;
        end
    end
    
    assign Y_m_s = (~Y_C_sign) ? (~{2'b0, Y_m} + 1) : {2'b0, Y_m};

    assign Y_R_m_s = Y_m_s + R_m;
    assign Y_G_m_s = Y_m_s + G_m;
    assign Y_B_m_s = Y_m_s + B_m;

    always@(posedge clk or posedge reset) begin
        if(reset) begin
            valid_d4 <= 0;
            {R_new, G_new, B_new} <= 0;
        end else begin
            valid_d4 <= valid_d3;
            R_new <= Y_R_m_s[18] ? 0 : Y_R_m_s[17:16] > 0 ? 255 : Y_R_m_s[15:8];
            G_new <= Y_G_m_s[18] ? 0 : Y_G_m_s[17:16] > 0 ? 255 : Y_G_m_s[15:8];
            B_new <= Y_B_m_s[18] ? 0 : Y_B_m_s[17:16] > 0 ? 255 : Y_B_m_s[15:8];
        end
    end       
    
    reg [3:0] vs_in_delay;
    reg [3:0] hs_in_delay;
    always@(posedge clk or posedge reset)begin
        if(reset)begin
            vs_in_delay <= 'd0;
            hs_in_delay <= 'd0;
        end else begin
            vs_in_delay <= {vs_in_delay[2:0],vs_in};
            hs_in_delay <= {hs_in_delay[2:0],hs_in};
        end
    end
    
    
    assign valid_o = valid_d4;
    assign img_data_o = {R_new, G_new, B_new};
    assign vs_out = vs_in_delay[3];
    assign hs_out = hs_in_delay[3];
    
    
endmodule
