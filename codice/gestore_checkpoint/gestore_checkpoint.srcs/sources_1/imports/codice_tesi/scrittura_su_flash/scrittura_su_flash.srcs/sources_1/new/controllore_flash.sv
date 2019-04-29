`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.04.2019 17:44:36
// Design Name: 
// Module Name: controllore_flash
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


module controllore_flash(
	input wire clk_i,
	input wire start,
	input wire reset,
	input wire [511:0] data,
	input wire [23:0] address,
	input wire [1:0]operation,
	output reg done,
	//input wire quad_spi_line_o,
	//output reg quad_spi_line_i,
	//output reg cs_n
	input wire quad_spi_line_o, //MOSI
    output reg quad_spi_line_i,
    output reg cs_n
    );
	reg [2:0] state;
	reg avvio;
	//reg reset;
	reg avvia_op;
	//reg done;
	reg [1:0] operation;
	reg rst;
	reg reset;
	reg start_op;
	reg i;
	//reg [511:0] data;
	//reg [23:0] address;
	reg [7:0] read_data;
	//reg started;
	/*ila_1 ila(
				.clk(clk_i),
				.probe0(state[0]),
				.probe1(state[1]),
				.probe2(start_op),
				.probe3(state),
				.probe4(done));*/
	//debouncer debounce1(.clk(clk),.PB(start),.PB_state(avvia_op));
	//debouncer debounce2(.clk(clk),.PB(rst),.PB_state(reset));
	//operazioni erase di un settore esadecimale 0, scrittura di 4kb esadecimale 1, lettura di una pagina esadecimale 2
	scrittura_su_flash driver(.clk_i(clk_i),.rst(rst),.start(start_op),.operation(operation),.data(data),
	.address(address),.quad_spi_line_o(quad_spi_line_o),.quad_spi_line_i(quad_spi_line_i),
	.read_data(read_data),.started(started),.done(done),.cs_n(cs_n));
	initial 
	begin
		state<=3'b000;
		 avvio<=0;
		 start_op<=0;
		 rst<=0;
		 //reset<=0;
	end
	always @(posedge clk_i)

				begin
				    if (reset)
				    begin
				      state<=3'b111;
				      avvio<=0;
				      start_op<=0;
				      rst<=1;

				    end
				    else if (start)
				    begin
				      state<=3'b000;
				      avvio<=1;
				      //data<=512'h8b000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000010;
				      //address<=32'h00000000;
				      rst<=0;
				      i<=0;
				      start_op<=1;
				      //operation<=2'h1;
				    end
				else if(avvio)
				    case (state)
				    	3'b000:
				    	begin
				    		
				    		//start<=1;
				    		if (started	)
				    		begin
				    			start_op<=0;
				    			state<=state+1;
				    		end
				    		
				    	end
				    	3'b001:
				    	begin
				    		if (done)
				    		begin
				    			state<=state+1;
				    			//start<=0;
				    			//start_op<=1;
				    			rst<=1;
				    		end
				    	end
				    	/*3'b001:
				    	begin
				    		rst<=0;
				    		//per avviare una operazione do lo start, asperto che started si alzi e metto start basso
				    		start_op<=1;
				    		if (started==1)
				    		begin
				    			start_op<=0;
				    			state<=state+1;
				    		operation<=2'h1;
				    		end
				    		//i<=1;
				    	end
				    	3'b010:
				    	begin
				    		
				    		//start<=1;
				    		i<=0;
				    		//start_op<=0;
				    		if (done==1)
				    		begin
				    			state<=state+1;
				    			//start<=0;
				    			//start_op<=1;
				    			rst<=1;
				    		end
				    	end
				    	3'b011:
				    	begin
				    		rst<=0;
				    		start_op<=1;
				    		if (started==1)
				    		begin
				    			//i<=1;
				    			start_op<=0;
				    			state<=state+1;
				    			operation<=2'h2;
				    		end
				    		//i<=1;
				    	end
				    	3'b100:
				    	begin
				    		
				    		//start<=1;
				    		i<=0;
				    		//start_op<=0;
				    		if (done==1)
				    		begin
				    			state<=state+1;
				    			//start<=0;
				    			//start_op<=1;

				    			//rst<=1; commentato per vedere se erase funziona
				    		end
				    	end*/
				    	
				    	default: 
				    	begin
				    		state<=3'b111;
				    		rst<=0;
				    	end
				    endcase // state
				end
				
endmodule
