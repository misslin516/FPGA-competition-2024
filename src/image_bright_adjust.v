`timescale 1ns / 1ps
//created by:****
//created date:2024/10/7
//Principle : based on Linear adjustment ----> rgb_out = rgb_in * alpha + beta
//                                       ----> alpha can be used to control contrast,beta to control bright
module image_bright_adjust(
   input wire clk,
   input wire reset,
   
   input wire [8:0] adjust_val,//-255~255 signed
   
   input wire vs_in,
   input wire hs_in,
   
   
   input wire valid_i,
   input wire [23:0] img_data_i,
   
   
   output wire  vs_out,
   output wire  hs_out,
   output wire valid_o,
   output wire [23:0] img_data_o
    );

    wire [7:0] R, G, B;
    reg valid_d1;
    reg [9:0] R_add_a, G_add_a, B_add_a;
    
    reg valid_d2;
    reg [7:0] R_new, G_new, B_new;
    
    assign {R, G, B} = img_data_i;
    always@(posedge clk or posedge reset) begin
        if(reset) begin
            valid_d1 <= 0;
            {R_add_a, G_add_a, B_add_a} <= 0;
        end else begin
            valid_d1 <= valid_i;
            R_add_a <= R + {adjust_val[8], adjust_val};
            G_add_a <= G + {adjust_val[8], adjust_val};
            B_add_a <= B + {adjust_val[8], adjust_val};
        end
    end


    always@(posedge clk or posedge reset) begin
        if(reset) begin
            valid_d2 <= 0;
            {R_new, G_new, B_new} <= 0;
        end else begin
            valid_d2 <= valid_d1;
            R_new <= R_add_a[9] ? 0 : R_add_a[8] ? 255 : R_add_a[8:0];
            G_new <= G_add_a[9] ? 0 : G_add_a[8] ? 255 : G_add_a[8:0];
            B_new <= B_add_a[9] ? 0 : B_add_a[8] ? 255 : B_add_a[8:0];
        end
    end   

    reg [1:0]  vs_in_delay ;
    reg [1:0]  hs_in_delay ;
    //delay 2 clk
    always@(posedge clk or posedge reset)
    begin
        if(reset)begin
            vs_in_delay <= 'd0;
            hs_in_delay <= 'd0;
        end else begin
            vs_in_delay <= {vs_in_delay[0],vs_in};
            hs_in_delay <= {hs_in_delay[0],hs_in};
        end
    end
    
    
    
    assign valid_o = valid_d2;
    assign img_data_o = {R_new, G_new, B_new};
    assign vs_out = vs_in_delay[1];
    assign hs_out = hs_in_delay[1];
endmodule
