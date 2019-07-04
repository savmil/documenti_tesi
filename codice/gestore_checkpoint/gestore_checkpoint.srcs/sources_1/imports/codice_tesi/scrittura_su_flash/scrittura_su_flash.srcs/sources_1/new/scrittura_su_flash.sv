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
			  input wire clk_i,
			  input wire rst,
			  input wire start,
			  input wire [1:0]operation, //operation
			  input wire [511:0] data_in,
			  output reg [511:0] data_out,
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
			  reg [2:0] passaggio;				  
			  wire clk_50_MHZ; //bus maximum velocity for all operation
			  reg activate_clk; //permits clock signal to pilot sck of flash low activated
			  //mi serve perché le operazioni su flash hanno bisogno di un clock a velocità diversa
			  //rispetto a quello del FPGA
			  clk_wiz_0 clk_gen(.reset(rst),.clk_in1(clk_i),.clk_out1(clk_50_MHZ));
			  //mi permette di utilizzare il pin del clock della flash tramite la porta USRCCLK0
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
			  .USRCCLKTS (1'b0), // 0 to enable CCLK output
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
			  	passaggio<=0;
			  	quad_spi_line_i<=1'b1;
			  	//address<=32'h00000000;
			  	done<=1;
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
					done<=1;
					started<=0;
				end
				else if (start)
				begin
					state<=4'b0000;
					avvio<=1;
					done<=0;
			      cs_n<=1;
			      i<=1;
			      activate_clk<=1'b0;

			      started<=avvio;
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
			      4'b0010: //invio il comando, attivo chip select
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
				        		quad_spi_line_i<=data_in[511];
				            //cs_n<=1;
				            //i<=i+1;
				        end
				    end
				        4'b0111            : //scrivo i dati della pagina
				        begin
				        	if (i<=511)
				        	begin
				        		quad_spi_line_i<=data_in[511-i];
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
				        			avvio<=0;
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
					        	i<=1;
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
					        	else if (i==24) // aggiungo per non leggere il primo bit
			        			begin
			        				i<=i+1;
			        			end
			        			else if (i>=25)
					        	begin
					        		i<=1;
					        		state<=state+1;
					        		data_out[511]<=quad_spi_line_o;
					            //cs_n<=1;
					            //i<=i+1;
					        end
					    end
					        4'b0100            : //leggo la pagina
					        begin
					        	if (i<=511)
					        	begin
					        		data_out[511-i]<=quad_spi_line_o;
					        		i<=i+1;
					        	end
					        	else if (i>=512)
					        	begin
					        		i<=1;
					        		state<=0;
					            cs_n<=1;
					            //i<=i+1;
					             avvio<=0;
					            done<=1;
					            passaggio<=passaggio+1;
					        end
					    end

					endcase
				end
		default            
		begin 
			state<=4'b1111;
			
		end

	endcase
end
/*ila_0 ILA_inst (
    .clk(clk_i),
    .probe0({10'h000}), // input [0 : 0] PROBE0
    .probe1({1'b0,i[12:10]}), // input [0 : 0] PROBE1
    .probe2(i[9:0]), // input [0 : 0] PROBE2
    .probe3({4'b0000,data_out[511:480]}), // input [0 : 0] PROBE3
    .probe4({4'b0000,data_out[479:448]}), // input [0 : 0] PROBE4
    .probe5({4'b0000,data_out[447:416]}), // input [0 : 0] PROBE5
    .probe6({4'b0000,data_out[415:384]}), // input [0 : 0] PROBE6
    .probe7(operation),
    .probe8({done,avvio}),
    .probe9({quad_spi_line_i,quad_spi_line_o}),
    .probe10(data_out[383:352]),
    .probe11({~clk_50_MHZ,1'b0}),
    .probe12(data_out[351:320]),
    .probe13(data_out[319:288]),
    .probe14({1'b0,state}),
    .probe15({4'b0000,data_out[31:0]})
 );*/
 ila_3 ila_icap(
    .clk(clk_i),
    .probe0({state,data_out[507:0]}),
    .probe1({~clk_50_MHZ,i[3:0]}),
    .probe2(quad_spi_line_o),
    .probe3(read_data));
/*ila_0 ILA_inst (
.clk(clk_i),
.probe0(i[0]), // input [0 : 0] PROBE0
.probe1(i[1]), // input [0 : 0] PROBE1
.probe2(i[2]), // input [0 : 0] PROBE2
.probe3(i[3]), // input [0 : 0] PROBE3
.probe4(i[4]), // input [0 : 0] PROBE4
.probe5(i[5]), // input [0 : 0] PROBE5
.probe6(i[6]), // input [0 : 0] PROBE6
.probe7(avvio),
.probe8(state[0]),
.probe9(state[1]),
.probe10(state[2]),
.probe11(state[3]),
.probe12(operation[0]),
.probe13(operation[1]),
.probe14(done),
.probe15(started),
.probe16(start),
.probe17(quad_spi_line_i),
.probe18(quad_spi_line_o),
.probe19(clk_50_MHZ)
);*/

endmodule


