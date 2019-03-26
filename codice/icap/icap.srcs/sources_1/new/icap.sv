`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.03.2019 22:23:23
// Design Name: 
// Module Name: icap
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

module icap(
   input wire clk_i,
   input wire rst_i,
   input wire readstrobe_i,
   input wire d,
   output reg q,
   //output reg [31:0] data_o,
   output reg ready_o,
   output reg[4:0] state
   //output reg data_valid_o
);
    reg [7:0] i;
    wire    [31:0]  icap_data_i;
    reg     [31:0]  icap_data_o;
    reg     icap_enable;
    reg     icap_write;
    reg [7:0] num_frame=8'b11001010;
    wire    avvia_lettura;
    wire    reset;
    reg    avvio;
    //reg [4:0]   state;
    icap_template icap(.clk_i(clk_i),.data_i(icap_data_o),.write_i(icap_write),.en_i(icap_enable),.data_o(icap_data_i));
    debouncer debounce1(.clk(clk_i),.PB(readstrobe_i),.PB_state(avvia_lettura));
    debouncer debounce2(.clk(clk_i),.PB(rst_i),.PB_state(reset));
    flip_flop_d ff_d(.data(d),.clk(clk_i),.q(q));
    initial begin
        state<=0;
        icap_enable<=1;
        icap_write<=1;
        ready_o<=1;
        avvio<=0;
        //data_valid_o<=0;
    end
    //i dati devono essere scritti facendo il reverse di ogni gruppo di 8 bit presente in una word ed allo stesso modo devono essere letti
    //per i comandi dati all' icap riferirsi allo script ed alla documentazione UG407 dove vengono descritti dato che l' appoccio jtag ed icap funzionano con gli stessi comandi
    /*la differenza tra jtag ed icap sta nel fatto che icap richiede due segnali di controllo, uno per attivare 
    l' icap (abilitato basso) ed un altro che gestisce le scritture e le letture(basso indica la volonta di scrivere)
    per cambiare tra scrittura e lettura devo prima disattivare l' icap insieme al cambio di modalità e poi riattivarlo*/
    //per leggere un frame devo sempre leggere il famoso frame vuoto
    //per usare più volte questo design devo fare prima un reset per poter rifare il readback
    always @(posedge clk_i)
    begin
        if (reset) 
        begin
            i<=0;
            state<=10;
            ready_o<=1;
            avvio<=0;
            //data_valid_o<=0;
        end 
        else if (avvia_lettura) 
        begin
            state<=0;
            icap_enable<=1;//disabilitato
            icap_write<=1;//lettura
            icap_data_o<=32'hffffffff;
            ready_o<=0;
            avvio<=1;
            //data_valid_o<=0;
        end
        else if(avvio)
        begin
            case(state)
                5'b00001:
                begin
                    icap_enable<=0;//abilitato
                    icap_write<=0;//scrittura
                    state<=state+1;
                    icap_data_o<=32'h20000000;
                end
                5'b00000:
                begin
                    //icap_enable<=0;//abilitato
                    //icap_write<=0;//scrittura
                    state<=state+1;
                    icap_data_o<=32'hffffffff;
                end
                5'b00010: 
                begin
                    state<=state+1;
                    icap_data_o<=32'haa995566;
                end
                5'b00011: 
                begin
                    state<=state+1;
                    icap_data_o<=32'h20000000;
                end
                5'b00100: 
                begin
                    state<=state+1;
                    icap_data_o<=32'h30008001;
                end
                5'b00101: 
                begin
                    state<=state+1;
                    icap_data_o<=32'h0000000c;
                end
                5'b00110: 
                begin
                    state<=state+1;
                    icap_data_o<=32'h20000000;
                end
                5'b00111: 
                begin
                    state<=state+1;
                    icap_data_o<=32'h20000000;
                end
                5'b01000: 
                begin
                    state<=state+1;
                    icap_data_o<=32'h20000000;
                end
                5'b01001: 
                begin
                    state<=state+1;
                    icap_data_o<=32'h20000000;
                end
                5'b01010: 
                begin
                    state<=state+1;
                    icap_data_o<=32'h30002001;
                end
                5'b01011: 
                begin
                    state<=state+1;
                    icap_data_o<=32'h00000000;
                end
                5'b01100: 
                begin
                    state<=state+1;
                    icap_data_o<=32'h30008001;
                end
                5'b01101: 
                begin
                    state<=state+1;
                    icap_data_o<=32'h00000004;
                end
                5'b01110: 
                begin
                    state<=state+1;
                    icap_data_o<=32'h30002001;
                end
                5'b01111: 
                begin
                    state<=state+1;
                    icap_data_o<=32'h0040011f;
                end
                5'b10000: 
                begin
                    state<=state+1;
                    icap_data_o<=32'h28006000;
                end
                5'b10001: 
                begin
                    state<=state+1;
                    icap_data_o<=32'h480000CA;
                end
                5'b10010:
                begin
                            icap_data_o<=32'h20000000;
                            state<=state+1;
                            icap_enable<=1; //disabilito icap per fare cambio da scrittura a lettura
                            icap_write<=1; //lettura
                end
                5'b10011: 
                                begin
                                    state<=state+1;
                                    icap_data_o<=32'h20000000;
                                    icap_enable<=0;//riabilito icap per leggere
                                end
                5'b10100: 
                 begin
                    
                    if (i<8'b00000010)
                    begin
                      i<=i+1;
                      icap_data_o<=32'h20000000;
                    end
                    else
                    begin
                         state<=state+1;
                    end
                 end
                5'b10101:
                begin
                   
                    if (i < num_frame) 
                    begin
                        i<=i+1;

                    end
                    else
                    begin
                        state<=state+1;
                        icap_enable<=1;//disabilito icap
                        icap_write<=1;//imposto di default a lettura
                    end
                end 
                5'b10100:
                begin
                    state<=state+1;
                    ready_o<=1;
                    icap_enable<=0;
                    icap_write<=0;
                    //icap_data_o<=;
                end
                default : 
                begin
                    state<=30;
                    avvio<=0;
                end
            endcase
        end
    end
    
ila_0 ILA_inst (
    .clk(clk_i),
    .probe0(state[0]), // input [0 : 0] PROBE0
    .probe1(state[1]), // input [0 : 0] PROBE1
    .probe2(state[2]), // input [0 : 0] PROBE2
    .probe3(state[3]), // input [0 : 0] PROBE3
    .probe4(state[4]), // input [0 : 0] PROBE4
    .probe5(icap_write), // input [0 : 0] PROBE5
    .probe6(icap_enable), // input [0 : 0] PROBE6
    .probe7(avvia_lettura),
    .probe8(icap_data_i[0]),
    .probe9(icap_data_i[1]),
    .probe10(icap_data_i[2]),
    .probe11(icap_data_i[3]),
    .probe12(icap_data_i[4]),
    .probe13(icap_data_i[5]),
    .probe14(icap_data_i[6]),
    .probe15(icap_data_i[7]),
    .probe16(icap_data_i[8]),
    .probe17(icap_data_i[9]),
    .probe18(icap_data_i[10]),
    .probe19(icap_data_i[11]),
    .probe20(icap_data_i[12]),
    .probe21(icap_data_i[13]),
    .probe22(icap_data_i[14]),
    .probe23(icap_data_i[15]),
    .probe24(icap_data_i[16]),
    .probe25(icap_data_i[17]),
    .probe26(icap_data_i[18]),
    .probe27(icap_data_i[19]),
    .probe28(icap_data_i[20]),
    .probe29(icap_data_i[21]),
    .probe30(icap_data_i[22]),
    .probe31(icap_data_i[23]),
    .probe32(icap_data_i[24]),
    .probe33(icap_data_i[25]),
    .probe34(icap_data_i[26]),
    .probe35(icap_data_i[27]),
    .probe36(icap_data_i[28]),
    .probe37(icap_data_i[29]),
    .probe38(icap_data_i[30]),
    .probe39(icap_data_i[31]),
    .probe40(clk_i)
 );
endmodule
