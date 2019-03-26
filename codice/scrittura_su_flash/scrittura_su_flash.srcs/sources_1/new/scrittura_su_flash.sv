`timescale 1ns / 1ps
`default_nettype wire
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.03.2019 07:44:37
// Design Name: 
// Module Name: scrittura_su_flash
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

//inserire cloacking wizard per avere clock a 50 MHZ da inserire in startupe, dopodichè leggere blog per capire come ha fatto
// prima di dare un comando bisogna far si che venga catturato il chip select basso al falling edge del clock, invece i dati vengono catturati al rising
module scrittura_su_flash(
    input wire clk,
    // output reg clk_50_MHZ,
    input wire rst,
    input wire start,
    //input wire [31:0] data_in,
    //input wire r_w,
    //output reg [31:0] data_o,
    input wire quad_spi_line_o,
    output  reg quad_spi_line_i,
   //output reg wp,
    //output reg quad_spi_line_o,
    output reg cs_n
    
    //output sck
    );
    //wire quad_spi_line_o;
    //reg quad_spi_line_i;
    wire reset;
    wire avvia_op;
    reg avvio;
    reg [5:0] state;
    reg [7:0] command;
    reg [511:0] dati;
    reg [12:0] i;
    reg [7:0] dati_letti;
    reg [31:0] data_o;
    reg [23:0] address;
    reg done;
    reg avvia;
    wire clk_50_MHZ;
    reg abilita_clk;
    debouncer debounce1(.clk(clk),.PB(rst),.PB_state(avvia_op));
    debouncer debounce2(.clk(clk),.PB(start),.PB_state(reset));
       //assign quad_spi_line =quad_spi_line_o ? rw : quad_spi_line_i;
     //spi_master(reset,clk,1'b0,avvia,command,1'b0,quad_spi_line, cs_n,sck,quad_spi_line,done,dati_letti); //mlb 0 LSB altrimenti BSB
     //tri_state tri_state(quad_spi_line_i,rw,quad_spi_line_o,quad_spi_line);
     clk_wiz_0 clk_gen(.clk_in1(clk),.clk_out1(clk_50_MHZ_180),.clk_out2(clk_50_MHZ));
     STARTUPE2
     #(
     .PROG_USR("FALSE"),
     .SIM_CCLK_FREQ(0.0)
     )
       STARTUPE2_inst
     (
       .CFGCLK     (),
       .CFGMCLK    (),
       .EOS        (),
       .PREQ       (),
       .CLK        (1'b0),
       .GSR        (1'b0),
       .GTS        (1'b0),
       .KEYCLEARB  (1'b0),
       .PACK       (1'b0),
       .USRCCLKO   (~clk_50_MHZ),  // First three cycles after config ignored, see AR# 52626
       .USRCCLKTS  (abilita_clk),     // 0 to enable CCLK output
       .USRDONEO   (1'b1),     // Shouldn't matter if tristate is high, but generates a warning if tied low.
       .USRDONETS  (1'b1)      // 1 to tristate DONE output
     );
     initial 
             begin
               avvio<=0;
               state<=7;
               cs_n<=1;
               avvio<=0;
               i<=0;
               quad_spi_line_i<=1'b1;
               data_o<=32'h00000000;
               address<=32'h00000000;
               abilita_clk<=1'b0;
               //wp<=1'b1;
             end
            
              always @(posedge clk_50_MHZ)
             
                       begin
                           if (reset) 
                           begin
                               state<=6'b111111;
                               avvio<=0;
                               i<=0;
                               abilita_clk<=1'b0;
                               cs_n<=1;
                           end 
                           else if (avvia_op) 
                           begin
                               state<=6'b000000;
                               avvio<=1;
                               //cs_n<=0;
                               i<=1;
                               abilita_clk<=1'b0;
                               //wp<=1'b1;
                               //bus_clk<=clk;
                               //data_valid_o<=0;
                           end
                           else if(avvio)
                           begin
                               case(state)
                                6'b000000: //abilito la scrittura asserendo WREN
                                begin
                                    i<=1;
                                    state<=state+1;
                                    command<=8'h06; //'h06
				                end
                                6'b000001: //attivo il chip select
                                begin
                                    cs_n<=0;
				                    state<=state+1;
				                    //abilita_clk<=1'b0;
                                    quad_spi_line_i<=command[7];
                                end
                                6'b000010://invio il comando, attivo chip select
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
                                   //abilita_clk<=1'b1;
                                   cs_n<=1;
                                   //i<=i+1;
                                 end
                                end
                                
                                
                                
                                
                                
                                
                                
                                
                               6'b000011: //lettura stato RSR1 lo faccio per capire se la scrittura è andata a buon fine
                               begin
                                
                                state<=state+1;
                                command<=8'h05;
                               end
                               6'b000100://asserisco il chip select
                               begin
                                cs_n<=0;
                                 state<=state+1;
                                  //cs_n<=0;
                                 quad_spi_line_i<=command[7];
                               end
                               6'b000101://invio il comando
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
                                   dati_letti[i]<=quad_spi_line_o;
                                   //i<=i+1;
                                 end
                               end
                               6'b000110://leggo il valore del registro
                               begin
                                  if (i<=7)
                                    begin
                                     dati_letti[i]<=quad_spi_line_o;
                                     i<=i+1;
                                    end                             
                                    else if (i>=8)
                                    begin
                                      i<=1;
                                     cs_n<=1;
                                     
                                     //abilita_clk<=1'b1;
                                     state<=state+1;
                                    end
                               end
 
 
 
 
 
 
 
 
                                                                 
                                 6'b000111: //cancello la pagina (vengono messi tutti i bit a 1 di una pagina di 4KB)
                                 begin
                                  state<=state+1;
                                  command<=8'h20; //page erase
                                  address<=32'h00000000;  
                                 end//fine lettura funzionante 
			                    6'b001000: //attivo il chip select
                                begin
                                    cs_n<=0;
				                    state<=state+1;
                                    quad_spi_line_i<=command[7];
                                end
			                    6'b001001://invio il comando
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
			                    6'b001010://invio indirizzo della pagina
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
			                    
			                    
			                    
			                    
			                    
			                    
			                    
			                    
			                    
                       6'b001011: //lettura stato RSR1 funzionante per attendere che la cancellazione avvenga
		               begin
		                
		                state<=state+1;
		                command<=8'h05;
		               end
		               6'b001100://asserisco il chip select
		               begin
		                cs_n<=0;
		                 state<=state+1;
		                  //cs_n<=0;
		                 quad_spi_line_i<=command[7];
		               end
		               6'b001101://invio il comando
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
		                   dati_letti[i]<=quad_spi_line_o;
		                   //i<=i+1;
		                 end
		               end
		               6'b001110://leggo il valore del registro per vedere se il bit 1 (partendo da sinistra si abbassi)
		               begin
		                  if (i<=7)
		                    begin
		                     dati_letti[i]<=quad_spi_line_o;
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
		                      if (dati_letti[7]==1'b1)
		                      begin
		                        state<=6'b001011;
		                        
		                      end
		                      else
		                      begin
		                        
		                        state<=state+1;
		                      end
		                     //abilita_clk<=1'b1;
		                     
		                    end
		               end
		               
		               
		               
		               
		               
		               
		               
		               
		               
		               
		                      6'b001111: //abilito la scrittura perchè ogni volta che scrivo e leggo si azzera WLEN(che mi permette di effettuare,
		                                 // una operazione sulla board
                               begin
                                   i<=1;
                                   state<=state+1;
                                   command<=8'h06; //'h06
                               end
                               6'b010000: //attivo il chip select
                               begin
                                   cs_n<=0;
                                   state<=state+1;
                                   //abilita_clk<=1'b0;
                                   quad_spi_line_i<=command[7];
                               end
                               6'b010001://invio il comando, attivo chip select
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
                                  //abilita_clk<=1'b1;
                                  cs_n<=1;
                                  //i<=i+1;
                                end
                               end
                               
                               
                               
                               
                               
                               6'b010010: //scrivo nella pagina 512 bit
                               begin
                               state<=state+1;
                               command<=8'h02; //page program
                               address<=32'h00000000; 
                               dati<=512'h7a000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000010; 
                               end
                               6'b010011: //attivo il chip select
                               begin
                               cs_n<=0;
                               state<=state+1;
                               quad_spi_line_i<=command[7];
                               end
                               6'b010100: //scrivo il comando
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
                               6'b010101: //scrivo l' indirizzo
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
                                   quad_spi_line_i<=dati[511];
                                   //cs_n<=1;
                                   //i<=i+1;
                               end
                               end
                               6'b010110: //scrivo i dati della pagina
                               begin
                               if (i<=511)
                               begin
                                   quad_spi_line_i<=dati[511-i];
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
                               
                              6'b010111: //lettura stato sr1 funzionante per attendere che la scrittura avvenga
                              begin
                               
                               state<=state+1;
                               command<=8'h05;
                              end
                              6'b011000://chip select
                              begin
                               cs_n<=0;
                                state<=state+1;
                                 //cs_n<=0;
                                quad_spi_line_i<=command[7];
                              end
                              6'b011001://invio comando
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
                                  dati_letti[i]<=quad_spi_line_o;
                                  //i<=i+1;
                                end
                              end
                              6'b011010://leggo il valore del registro per attendere che si abbassi il pin relativo alla scrittura
                              begin
                                 if (i<=7)
                                   begin
                                    dati_letti[i]<=quad_spi_line_o;
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
                                     if (dati_letti[7]==1'b1)
                                     begin
                                       state<=6'b010111;
                                       
                                     end
                                     else
                                     begin
                                       
                                       state<=state+1;
                                     end
                                    //abilita_clk<=1'b1;
                                    
                                   end
                              end
                               
                               
                               
                               
                               
                               
                                                                                               
			                    6'b011011: //leggo dalla pagina auto incrementate fino a che non alzo il chip select
			                    begin
				                    state<=state+1;
                                    command<=8'h03; //page read
				                    address<=32'h00000000; 
				                end
			                    6'b011100: //attivo il chip select
                                begin
                                    cs_n<=0;
				                    state<=state+1;
                                    quad_spi_line_i<=command[7];
                                end
			                    6'b011101: //scrivo il comando
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
                               6'b011110: //scrivo l' indirizzo
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
                                        dati_letti[i-1]<=quad_spi_line_o;
                                               //cs_n<=1;
                                               //i<=i+1;
                                    end
                                end
                               6'b011111: //leggo la pagina
                                begin
                                    if (i<=7)
                                    begin
                                        dati_letti[i]<=quad_spi_line_o;
                                        i<=i+1;
                                    end
                                    else if (i>=8) 
                                    begin
                                        i<=1;
                                        state<=state+1;
                                        //cs_n<=1;
                                               //i<=i+1;
                                    end
                                end
                              
                               
                                 default: state<=6'b111111;
                                 
                                 endcase
                               end
                               
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
                                      .probe14(i[0]),
                                      .probe15(quad_spi_line_o),
                                      //.probe13(quad_spi_line[1]),
                                      //.probe14(quad_spi_line[2]),
                                      //.probe15(quad_spi_line[3]),
                                      .probe16(quad_spi_line_i),
                                      .probe17(dati_letti[1]),
                                      .probe18(dati_letti[2]),
                                      .probe19(dati_letti[3]),
                                      .probe20(dati_letti[4]),
                                      .probe21(dati_letti[5]),
                                      .probe22(dati_letti[6]),
                                      .probe23(dati_letti[7]),
                                      .probe24(cs_n),
                                      .probe25(state[4]),
                                      .probe26(i[1]),
                                      .probe27(i[2]),
                                      .probe28(i[3]),
                                      .probe29(i[4]),
                                      .probe30(i[5])
                                      );
                        
endmodule
