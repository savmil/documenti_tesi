`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.03.2019 09:06:22
// Design Name: 
// Module Name: testbench_scrittura
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


module testbench_scrittura(
         
    );
    reg clk;
    reg rst;
    reg start;
    wire quad_spi_line_i;
     wire quad_spi_line_o;
    wire cs_n;

    controllore_flash flash(clk,start,quad_spi_line_o,quad_spi_line_i,cs_n) ;
    initial 
    begin
    rst<=0;
    start<=0;
    clk<=0;
    #10 rst<=1;
    #10 rst<=0; start<=1;
    #40 start<=0;
    end
    always
    begin
    #10 clk = ~clk;
    end

endmodule
