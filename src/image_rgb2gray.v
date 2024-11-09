`timescale 1ns / 1ps
//created by:****
//created date:2024/10/7
module image_rgb2gray(
   input wire clk,
   input wire reset,
   
   input wire vs_in,
   input wire hs_in,
   
   input wire valid_i,
   input wire [23:0] img_data_i,
   
   
   output wire  vs_out,
   output wire  hs_out,
   output wire valid_o,
   output wire [23:0] img_data_o
    );

    //常量
    parameter MODE = 1;  //0表示加权平均法，1表示平均法 
    //Y=0.299*R十0.587*G+0.114*B
    parameter C0 = 9'd306;//0.299*1024;
    parameter C1 = 10'd601;//0.587*1024;
    parameter C2 = 7'd117;//0.114*1024;

    //参数声明
    wire [7:0] R, G, B;

    assign {R, G, B} = img_data_i;
 
    generate if (MODE) begin

    reg valid_d1;   
    reg [9:0] RGB_avr;
    
    reg valid_d2;   
    reg [16:0] RGB_avr_m;
    
    reg valid_d3;   
    reg [7:0] RGB_new;
    
    reg [2:0] vs_in_delay;
    reg [2:0] hs_in_delay;
    //平均法
    //1/3 * 512 = 171

    always@(posedge clk or posedge reset) begin
        if(reset) begin
            valid_d1 <= 'b0;
            RGB_avr <= 'b0;
        end else begin
            valid_d1 <= valid_i;
            RGB_avr <= R + G + B;
        end
    end

    //最大值不可能超过255*3*171 = 17'd130815
    always@(posedge clk) begin
        RGB_avr_m <= RGB_avr * 8'd171;
    end
    always@(posedge clk or posedge reset) begin
        if(reset) begin
            valid_d2 <= 'b0;
        end else begin
            valid_d2 <= valid_d1;
        end
    end

    //最大值不可能超过255
    always@(posedge clk or posedge reset) begin
        if(reset) begin
            valid_d3 <= 'b0;
            RGB_new <= 'b0;
        end else begin
            valid_d3 <= valid_d2;
            RGB_new <= RGB_avr_m[16:9];
        end
    end
    
    always@(posedge clk or posedge reset)begin
        if(reset)begin
            vs_in_delay <= 'd0;
            hs_in_delay <= 'd0;
        end else begin
            vs_in_delay <= {vs_in_delay[1:0],vs_in};
            hs_in_delay <= {hs_in_delay[1:0],hs_in};
        end
    end
    
    
    assign valid_o = valid_d3;
    assign img_data_o = {3{RGB_new}};
    assign vs_out = vs_in_delay[2];
    assign hs_out = hs_in_delay[2];
    end else begin

    //加权平均法
    reg valid_d1;
    reg [16:0] Y_R_m;
    reg [17:0] Y_G_m;
    reg [14:0] Y_B_m;
    
    reg valid_d2;
    reg [17:0] Y_s;//最大值，当RGB都等于255时，(C0 + C1 + C2)*255 = 1024*255；不会出现负数
    
    reg valid_d3;
    reg [7:0] Y;
    reg [2:0] vs_in_delay;
    reg [2:0] hs_in_delay;
    
    
    always@(posedge clk ) begin
        Y_R_m <= R*C0;
        Y_G_m <= G*C1;
        Y_B_m <= B*C2;
    end

    always@(posedge clk or posedge reset) begin
        if(reset) begin
            valid_d1 <= 0;
        end else begin
            valid_d1 <= valid_i;
        end
    end    

    always@(posedge clk or posedge reset) begin
        if(reset) begin
            Y_s <= 0;
            valid_d2 <= 0;
        end else begin
            if(valid_d1) begin
                Y_s <= Y_R_m + Y_G_m + Y_B_m;
            end
            valid_d2 <= valid_d1;
        end
    end

    always@(posedge clk or posedge reset) begin
        if(reset) begin
            Y <= 0;
            valid_d3 <= 0;
        end else begin
            if(valid_d2) begin
               Y <= Y_s[17:10];
            end
            valid_d3 <= valid_d2;
        end
    end  
    
   always@(posedge clk or posedge reset)begin
        if(reset)begin
            vs_in_delay <= 'd0;
            hs_in_delay <= 'd0;
        end else begin
            vs_in_delay <= {vs_in_delay[1:0],vs_in};
            hs_in_delay <= {hs_in_delay[1:0],hs_in};
        end
    end
    
    
    assign valid_o = valid_d3;
    assign img_data_o = {3{Y}};
    assign vs_out = vs_in_delay[2];
    assign hs_out = hs_in_delay[2];
    end        
    endgenerate

    
endmodule
