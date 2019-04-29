`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.03.2019 16:27:30
// Design Name: 
// Module Name: Icap_read_sim
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Icap_read_sim(

    );
     logic clk_i=1'b1;
     logic rst_i=1'b1;
     logic readstrobe_i=1'b0;
     //wire [22:0] icap_addr_i;
     //reg [31:0] data_o;
     reg ready_o=1'b0;
     //reg data_valid_o;
    icap#()
    icap_uut(
       .clk_i(clk_i),
       .rst_i(rst_i),
       .readstrobe_i(readstrobe_i),
       //.icap_addr_i(icap_addr_i),
       //.data_o(data_o),
       .ready_o(ready_o)
       //.data_valid_o(data_valid_o)
    );
    always #10 clk_i = ~clk_i;
    /*always 
    begin
        #10 clk_i = ~clk_i;
        if (ready_o==readstrobe_i)
        begin
        readstrobe_i<=1;
        end
        else
        begin 
         readstrobe_i<=0;
        end
    end*/
    
    initial begin
            #50
            rst_i<=0;
            //readstrobe_i<=1;
            readstrobe_i<=1;
            #40
            readstrobe_i<=0;
    end 
endmodule

