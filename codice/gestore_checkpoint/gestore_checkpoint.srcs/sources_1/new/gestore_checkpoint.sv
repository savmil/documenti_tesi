`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.04.2019 15:05:11
// Design Name: 
// Module Name: gestore_checkpoint
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


module gestore_checkpoint(
	input wire clk_i,
	input wire rst,
	input wire leggi_scrivi,//mi permette di scrivere un frame sul FPGA oppure di leggerlo e salvarlo su flash
	input wire reset_icap,
	input wire enable_counter,
	input wire enable_reg,
	input wire enable_clk,
	input wire avvia_ciclo,
	output reg icap_ready,
	input wire quad_spi_line_o, //MOSI
	output reg quad_spi_line_i,
	output reg cs_n,
	output reg ritorno,
	output reg [7:0] h_c
    );
	reg [2:0]state;
	reg avvia_icap;

	reg avvio;
	reg reset;
	reg start;
	reg[1:0] r_w;
	reg [31:0] out;
	reg [31:0] counter;
	reg [31:0] counter1;
	reg c;
	icap icap(.clk(clk_i),.rst_i(rst),.readstrobe_i(avvia_icap),.r_w(r_w),.ready_o(icap_ready),
		.quad_spi_line_o(quad_spi_line_o),.quad_spi_line_i(quad_spi_line_i),.cs_n(cs_n),.ritorno(ritorno));
	debouncer debounce1(.clk(clk_i),.PB(avvia_ciclo),.PB_state(start));
	debouncer debounce2(.clk(clk_i),.PB(rst),.PB_state(reset));
	counter_reg #(.prova(1)) c_r 
	(.out(counter),.enable(enable_counter),.clk(clk_i),.reset(reset));
	counter_reg #(.prova(2)) contatore
	(.out(counter1),.enable(enable_reg),.clk(clk_i),.reset(reset));
	//register  #(.prova("trovami" )) registro 
	//(.out(out),.in(counter),.clk(clk_i),.enable(enable_reg),.rst(rst));
	/*ila_1 ila(
		.clk(clk_i),
		.probe0(state[0]),
		.probe1(state[1]),
		.probe2(state[2]),
		.probe3(avvia_icap),
		.probe4(icap_ready));*/
	/*always_comb
	begin
		if (enable_clk)
		begin
			c<=clk_i;
		end
		else
		begin
			c<=0;
		end
	end*/
	initial begin
		avvia_icap<=0;
		//r_w<=0;
		
	end
	always @(posedge clk_i)
	begin
		h_c[6:0]<=counter[31:25];
		h_c[7]<=counter1[31];
		//appoggio<=out[23:0];
		if(!reset_icap && !leggi_scrivi)
		begin
			r_w<=0;

		end
		else if (!reset_icap && leggi_scrivi)
		begin
			r_w<=1;
		end
		else if(reset_icap)
		begin
			r_w<=2;
		end

		if (reset)
		begin
			state<=7;
			avvia_icap<=0;
			//r_w<=0;
		end
		else if (start)
		begin
			state<=0;
			avvio<=1;
			avvia_icap<=0;
		end
		else if (avvio)
		begin
			case (state)
				3'b000:
				begin
					//r_w<=1'b0;
					if (avvia_icap==0)
					begin
						avvia_icap<=1'b1;
					end
					
					else if ( avvia_icap)
					begin
						state<=state+1;
					end
				end
				3'b001:
				begin
					if (!icap_ready)
					begin
						avvia_icap<=0; 
						state<=state+1;
					end
				end
				3'b010:
				begin
					if (icap_ready)
					begin 
						state<=state+1;
					end
				end
				/*3'b011:
				begin
					r_w<=1'b1;
					if (avvia_icap==0)
					begin
						avvia_icap<=1'b1;
					end
					
					else if ( avvia_icap)
					begin
						avvia_icap<=0;
						state<=state+1;
					end
				end
				3'b100:
				begin
					if (!icap_ready)
					begin 
						state<=state+1;
					end
				end
				3'b101:
				begin
					if (icap_ready)
					begin 
						state<=state+1;
					end
				end*/
				default:
				begin
					avvio<=0;
					state<=7;
				end
			endcase
		end
	end 
	
endmodule
