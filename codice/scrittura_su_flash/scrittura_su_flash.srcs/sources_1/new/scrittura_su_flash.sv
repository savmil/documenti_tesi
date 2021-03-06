					`timescale 1ns / 1ps
					`default_nettype wire
					//////////////////////////////////////////////////////////////////////////////////
					// Company                                          :
					// Engineer                                         :
					//
					// Create Date                                      : 24.03.2019 07:44:37
					// Design Name                                      :
					// Module Name                                      : scrittura_su_flash
					// Project Name                                     :
					// Target Devices                                   :
					// Tool Versions                                    :
					// Description                                      :
					//
					// Dependencies                                     :
					//
					// Revision                                         :
					// Revision 0.01 - File Created
					// Additional Comments                              :
					//
					//////////////////////////////////////////////////////////////////////////////////

					//inserire cloacking wizard per avere clock a 50 MHZ da inserire in startupe, dopodichè leggere blog per capire come ha fatto
					// prima di dare un comando bisogna far si che venga catturato il chip select basso al falling edge del clock, invece i dati vengono catturati al rising
					`define ERASE 2'h0  
					`define WRITE 2'h1
					`define READ  2'h2
					module scrittura_su_flash(
					  input wire clk,
					  input wire rst,
					  input wire start,
					  input wire [1:0]operation, //operation
					  input reg [511:0] data,
					  input reg [23:0] address,// address of operation
					  input wire quad_spi_line_o, //MOSI
					  output reg quad_spi_line_i, //MISO
					  output reg [7:0] read_data, //data readed by register or page,
					  output reg started,
					  output reg done, //go to 1 one operation is done
					  output reg cs_n
					  );
					  reg avvio;
					  reg [3:0] state;
					  reg [7                                          :0] command;
					  reg [12                                         :0] i;					  
					  wire clk_50_MHZ; //bus maximum velocity for all operation
					  reg activate_clk; //permits clock signal to pilot sck of flash low activated
					  clk_wiz_0 clk_gen(.clk_in1(clk),.clk_out1(clk_50_MHZ));
					  STARTUPE2
					  #(
					  	.PROG_USR("FALSE"),
					  	.SIM_CCLK_FREQ(0.0)
					  	)
					  STARTUPE2_inst
					  (
					  	.CFGCLK (),
					  	.CFGMCLK (),
					  	.EOS (),
					  	.PREQ (),
					  	.CLK (1'b0),
					  	.GSR (1'b0),
					  	.GTS (1'b0),
					  	.KEYCLEARB (1'b0),
					  	.PACK (1'b0),
					  .USRCCLKO (~clk_50_MHZ), // First three cycles after config ignored, see AR# 52626
					  .USRCCLKTS (activate_clk), // 0 to enable CCLK output
					  .USRDONEO (1'b1), // Shouldn't matter if tristate is high, but generates a warning if tied low.
					  .USRDONETS (1'b1) // 1 to tristate DONE output
					  );
					  initial
					  begin
					  	avvio<=0;
					  	state<=7;
					  	cs_n<=1;
					  	i<=0;
					  	started<=0;
					  	quad_spi_line_i<=1'b1;
					  	//address<=32'h00000000;
					  	activate_clk<=1'b0;
					    //wp<=1'b1;
					end

					always @(posedge clk_50_MHZ)

					begin
						if (rst)
						begin
							state<=4'b1111;
							avvio<=0;
							i<=0;
							activate_clk<=1'b0;
							cs_n<=1;
							done<=0;
							started<=0;
						end
						else if (start)
						begin
							state<=4'b0000;
							avvio<=1;
							
					      //cs_n<=0;
					      i<=1;
					      activate_clk<=1'b0;

					      started<=1;
					      //wp<=1'b1;
					      //bus_clk<=clk;
					      //data_valid_o<=0;
					  end
					  else if(avvio)
					  	case (operation)
					  		`ERASE:
					  		begin 
					  			case(state)
					        4'b0000           : //abilito la scrittura asserendo WREN
					        begin
					        	i<=1;
					        	started<=0;
					        	state<=state+1;
					          command<=8'h06; //'h06
					      end
					        4'b0001           : //attivo il chip select
					        begin
					        	cs_n<=0;
					        	
					        	state<=state+1;
				
					          quad_spi_line_i<=command[7];
					      end
					      4'b0010           ://invio il comando, attivo chip select
					      begin

					      	if (i<=7)
					      	begin
					      		quad_spi_line_i<=command[7-i];
					      		i<=i+1;
					      	end

					      	else if (i>=8)
					      	begin
					      		i<=1;
					      		state<=state+1;
					
					            cs_n<=1;
					            //i<=i+1;
					        end
					    end
					        4'b0011           : //lettura stato RSR1 lo faccio per capire se la scrittura è andata a buon fine
					        begin

					        	state<=state+1;
					        	command<=8'h05;
					        end
					        4'b0100           ://asserisco il chip select
					        begin
					        	cs_n<=0;
					        	state<=state+1;
					          //cs_n<=0;
					          quad_spi_line_i<=command[7];
					      end
					      4'b0101           ://invio il comando
					      begin

					      	if (i<=7)
					      	begin
					      		quad_spi_line_i<=command[7-i];
					      		i<=i+1;
					      	end

					      	else if (i>=8)
					      	begin
					      		i<=0;
					      		state<=state+1;
					      		read_data[i]<=quad_spi_line_o;
					            //i<=i+1;
					        end
					    end
					    4'b0110           ://leggo il valore del registro
					    begin
					    	if (i<=7)
					    	begin
					    		read_data[i]<=quad_spi_line_o;
					    		i<=i+1;
					    	end
					    	else if (i>=8)
					    	begin
					    		i<=1;
					    		cs_n<=1;

					            
					            state<=state+1;
					        end
					    end
					        4'b0111           : //cancello la pagina (vengono messi tutti i bit a 1 di una pagina di 4KB)
					        begin
					        	state<=state+1;
					          command<=8'h20; //page erase
					          //address<=32'h00000000;
					        end//fine lettura funzionante
					        4'b1000           : //attivo il chip select
					        begin
					        	cs_n<=0;
					        	state<=state+1;
					        	quad_spi_line_i<=command[7];
					        end
					        4'b1001           ://invio il comando
					        begin
					        	if (i<=7)
					        	begin
					        		quad_spi_line_i<=command[7-i];
					        		i<=i+1;
					        	end
					        	else if (i>=8)
					        	begin
					        		i<=1;
					        		state<=state+1;
					        		quad_spi_line_i<=address[23];
					            //i<=i+1;
					        end
					    end
					    4'b1010           ://invio indirizzo della pagina
					    begin
					    	if (i<=23)
					    	begin
					    		quad_spi_line_i<=address[23-i];
					    		i<=i+1;
					    	end
					    	else if (i>=24)
					    	begin
					    		i<=1;
					    		state<=state+1;
					    		cs_n<=1;
					            //i<=i+1;
					        end
					    end
					        4'b1011: //lettura stato RSR1 funzionante per attendere che la cancellazione avvenga
					        begin

					        	state<=state+1;
					        	command<=8'h05;
					        end
					        4'b1100://asserisco il chip select
					        begin
					        	cs_n<=0;
					        	state<=state+1;
					          //cs_n<=0;
					          quad_spi_line_i<=command[7];
					      end
					      4'b1101 ://invio il comando
					      begin
					      	if (i<=7)
					      	begin
					      		quad_spi_line_i<=command[7-i];
					      		i<=i+1;
					      	end
					      	else if (i>=8)
					      	begin
					      		i<=0;
					      		state<=state+1;
					      		read_data[i]<=quad_spi_line_o;
					            //i<=i+1;
					        end
					    end
					    4'b1110                       ://leggo il valore del registro per vedere se il bit 1 (partendo da sinistra si abbassi)
					    begin
					    	if (i<=7)
					    	begin
					    		read_data[i]<=quad_spi_line_o;
					    		i<=i+1;
					    	end
					    	else if (i==8)
					    	begin
					    		i<=i+1;
					    		cs_n<=1;
					    	end
					    	else if (i>=9)
					    	begin
					    		i<=1;
					    		if (read_data[7]==1'b1)
					    		begin
					    			state<=4'b1011;

					    		end
					    		else
					    		begin

					    			state<=state+1;
					    			done<=1;
					    			avvio<=0;
					    		end
					           

					        end
					    end
					endcase
				end 














				`WRITE:
				begin
					case(state)
						        4'b0000                 : //abilito la scrittura perchè ogni volta che scrivo e leggo si azzera WLEN(che mi permette di effettuare,
						        // una operazione sulla board
						        begin
						        	i<=1;
						        	started<=0;
						        	state<=state+1;
						          command<=8'h06; //'h06
						      end
						        4'b0001            : //attivo il chip select
						        begin
						        	cs_n<=0;
						        	
						        	state<=state+1;
						          
						          quad_spi_line_i<=command[7];
						      end
						        4'b0010            : //invio il comando, attivo chip select
						        begin

						        	if (i<=7)
						        	begin
						        		quad_spi_line_i<=command[7-i];
						        		i<=i+1;
						        	end

						        	else if (i>=8)
						        	begin
						        		i<=1;
						        		state<=state+1;
						           
						            cs_n<=1;
						            //i<=i+1;
						        end
						    end





						        4'b0011            : //scrivo nella pagina 512 bit
						        begin
						        	state<=state+1;
						          command<=8'h02; //page program
						          //address<=32'h00000000;
						          //dati<=512'h8b000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000010;
						      end
						        4'b0100            : //attivo il chip select
						        begin
						        	cs_n<=0;
						        	state<=state+1;
						        	quad_spi_line_i<=command[7];
						        end
						        4'b0101            : //scrivo il comando
						        begin
						        	if (i<=7)
						        	begin
						        		quad_spi_line_i<=command[7-i];
						        		i<=i+1;
						        	end
						        	else if (i>=8)
						        	begin
						        		i<=1;
						        		state<=state+1;
						        		quad_spi_line_i<=address[23];
						            //i<=i+1;
						        end
						    end
						        4'b0110            : //scrivo l' indirizzo
						        begin
						        	if (i<=23)
						        	begin
						        		quad_spi_line_i<=address[23-i];
						        		i<=i+1;
						        	end
						        	else if (i>=24)
						        	begin
						        		i<=1;
						        		state<=state+1;
						        		quad_spi_line_i<=data[511];
						            //cs_n<=1;
						            //i<=i+1;
						        end
						    end
						        4'b0111            : //scrivo i dati della pagina
						        begin
						        	if (i<=511)
						        	begin
						        		quad_spi_line_i<=data[511-i];
						        		i<=i+1;
						        	end
						        	else if (i>=512)
						        	begin
						        		i<=1;
						        		state<=state+1;
						        		cs_n<=1;
						            //i<=i+1;
						        end
						    end

						        4'b1000             : //lettura stato sr1 funzionante per attendere che la scrittura avvenga
						        begin

						        	state<=state+1;
						        	command<=8'h05;
						        end
						        4'b1001             : //chip select
						        begin
						        	cs_n<=0;
						        	state<=state+1;
						          //cs_n<=0;
						          quad_spi_line_i<=command[7];
						      end
						        4'b1010             : //invio comando
						        begin

						        	if (i<=7)
						        	begin
						        		quad_spi_line_i<=command[7-i];
						        		i<=i+1;
						        	end

						        	else if (i>=8)
						        	begin
						        		i<=0;
						        		state<=state+1;
						        		read_data[i]<=quad_spi_line_o;
						            //i<=i+1;
						        end
						    end
						        4'b1011             : //leggo il valore del registro per attendere che si abbassi il pin relativo alla scrittura
						        begin
						        	if (i<=7)
						        	begin
						        		read_data[i]<=quad_spi_line_o;
						        		i<=i+1;
						        	end
						        	else if (i==8)
						        	begin
						        		i<=i+1;
						        		cs_n<=1;
						        	end
						        	else if (i>=9)
						        	begin
						        		i<=1;
						        		if (read_data[7]==1'b1)
						        		begin
						        			state<=4'b1000;

						        		end
						        		else
						        		begin

						        			state<=0;
						        			done<=1;
						        		end
						           

						        end
						     end   




						    endcase
						end
						`READ:
						begin
							case(state)
					        4'b0000                 : //leggo dalla pagina auto incrementate fino a che non alzo il chip select
					        begin
					        	started<=0;
					        	state<=state+1;
					          command<=8'h03; //page read
					          //address<=32'h00000000;
					      end
					        4'b0001                 : //attivo il chip select
					        begin
					        	cs_n<=0;
					        	
					        	state<=state+1;
					        	quad_spi_line_i<=command[7];
					        end
					        4'b0010                 : //scrivo il comando
					        begin
					        	if (i<=7)
					        	begin
					        		quad_spi_line_i<=command[7-i];
					        		i<=i+1;
					        	end
					        	else if (i>=8)
					        	begin
					        		i<=1;
					        		state<=state+1;
					        		quad_spi_line_i<=address[23];
					            //i<=i+1;
					        end
					    end
					        4'b0011            : //scrivo l' indirizzo
					        begin
					        	if (i<=23)
					        	begin
					        		quad_spi_line_i<=address[23-i];
					        		i<=i+1;
					        	end
					        	else if (i>=24)
					        	begin
					        		i<=1;
					        		state<=state+1;
					        		read_data[i-1]<=quad_spi_line_o;
					            //cs_n<=1;
					            //i<=i+1;
					        end
					    end
					        4'b0100            : //leggo la pagina
					        begin
					        	if (i<=7)
					        	begin
					        		read_data[i]<=quad_spi_line_o;
					        		i<=i+1;
					        	end
					        	else if (i>=8)
					        	begin
					        		i<=1;
					        		state<=0;
					            //cs_n<=1;
					            //i<=i+1;
					            done<=1;
					        end
					    end

					endcase
				end
				default            : state<=4'b1111;

			endcase
		end

	
		ila ILA_inst (
			.clk(clk),
			.probe0(state[0]),
			.probe1(state[1]),
			.probe2(state[2]),
			.probe3(state[3]),
			.probe4(command[0]),
			.probe5(command[1]),
			.probe6(command[2]),
			.probe7(command[3]),
			.probe8(command[4]),
			.probe9(command[5]),
			.probe10(command[6]),
			.probe11(command[7]),
			.probe12(~clk_50_MHZ),
			.probe13(state[5]),
			.probe14(started),
			.probe15(quad_spi_line_o),
			.probe16(quad_spi_line_i),
			.probe17(read_data[1]),
			.probe18(read_data[2]),
			.probe19(read_data[3]),
			.probe20(read_data[4]),
			.probe21(read_data[5]),
			.probe22(read_data[6]),
			.probe23(read_data[7]),
			.probe24(done),
			.probe25(state[4]),
			.probe26(rst),
			.probe27(start),
			.probe28(avvio),
			.probe29(operation[0]),
			.probe30(operation[1])
			);

endmodule
