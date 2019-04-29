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
   input wire clk,
   input wire rst_i,
   input wire readstrobe_i, //avvia la lettura
   input wire r_w, //scrivo se 1 leggo se 0
   /*input wire d,
   output reg q, usato per il flip flop */ 
   output reg ready_o, //mi dice che l' operazione è terminata
   //output reg[4:0] state usato per debug
   input wire quad_spi_line_o, //MOSI
   output reg quad_spi_line_i,
   output reg cs_n
);
    reg [4:0] state;
    reg [9:0] i;
    wire    [31:0]  icap_data_i;
    reg     [31:0]  icap_data_o;
    reg     icap_enable;
    reg     icap_write;
    reg [7:0] num_frame=8'b11001010;
    wire    avvia_lettura;
    wire    reset;
    reg    avvio;
    reg [31:0] address_frame;
    reg [3231:0] data;
    reg [1183:0] prologe=1184'h30022001000000003002000100000000300080010000000020000000300080010000000720000000200000003001200102003fe53001c0010000000030018001036310933000800100000009200000003000c001000004013000a001000005013000c001000000003003000100000000200000002000000020000000200000002000000020000000200000002000000030002001;
    reg [159:0] prologe_1=160'h30008001000000012000000030004000500000CA;
    reg [3231:0] frame=3232'h100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000EC30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    reg [3231:0] dummy_frame=3232'h0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    reg [3839:0] epilogue=3840'h2000000020000000300080010000000a200000003000800100000003200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000003000800100000005200000003000200103be00003000c001000005013000a001000005012000000020000000300080010000000d;
    //serve per fare il flush dei dati
    reg [3231:0] noop_frame=3232'h2000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000;
        reg [1375:0] prologe_2=1376'h30022001000000003002000100000000300080010000000020000000300080010000000720000000200000003001200102003fe53001c0010000000030018001036310933000800100000009200000003000c001000004013000a001000005013000c0010000000030030001000000002000000020000000200000002000000020000000200000002000000020000000300020010000000030008001000000012000000030004000500000CA;
    
    reg [14911:0] dati={prologe,address_frame,prologe_1,data,dummy_frame,epilogue,noop_frame};

    reg ready;
    reg avvia_flash;
    reg flash_pronta;
    reg [23:0] address;
    reg [511:0] dati_da_salvare;
    reg [1:0] operazione_flash;
    reg flash;
    reg started;
    reg [9:0] addr;
    reg en_bram;
    //reg [14911:0] dati=14912'h30022001000000003002000100000000300080010000000020000000300080010000000720000000200000003001200102003fe53001c0010000000030018001036310933000800100000009200000003000c001000004013000a001000005013000c0010000000030030001000000002000000020000000200000002000000020000000200000002000000020000000300020010040011f30008001000000012000000030004000500000CA000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000EC0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000020000000300080010000000a200000003000800100000003200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000003000800100000005200000003000200103be00003000c001000005013000a001000005012000000020000000300080010000000d2000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000;
    //reg [4:0]   state;
    icap_template icap(.clk_i(clk),.data_i(icap_data_o),.write_i(icap_write),.en_i(icap_enable),.data_o(icap_data_i));
    bram frame_da_salvare(addr,clk,address_frame,en_bram,1'b0,32'h00000000,rst_i,4'b0000);
    //debouncer debounce1(.clk(clk),.PB(readstrobe_i),.PB_state(avvia_lettura));
    //debouncer debounce2(.clk(clk),.PB(rst_i),.PB_state(reset));
    controllore_flash controllore_flash(.clk_i(clk),.start(avvia_flash),.reset(rst_i),.data(dati_da_salvare),.address(address),
        .operation(operazione_flash),.done(flash_pronta),.quad_spi_line_i(quad_spi_line_i),
        .quad_spi_line_o(quad_spi_line_o),.cs_n(cs_n));
    //flip_flop_d ff_d(.data(d),.clk(clk_i),.q(q));
    initial begin
        state<=0;
        icap_enable<=1;
        icap_write<=1;
        ready_o<=1;
        avvio<=0;
        flash<=0;
        data<=frame;
        avvia_flash<=0;
        en_bram<=1;
         ready<=0;
         addr<=10'h000;
        //data_valid_o<=0;
    end
    //i dati devono essere scritti facendo il reverse di ogni gruppo di 8 bit presente in una word ed allo stesso modo devono essere letti
    //per i comandi dati all' icap riferirsi allo script ed alla documentazione UG470 dove vengono descritti dato che l' appoccio jtag ed icap funzionano con gli stessi comandi
    /*la differenza tra jtag ed icap sta nel fatto che icap richiede due segnali di controllo, uno per attivare 
    l' icap (abilitato basso) ed un altro che gestisce le scritture e le letture(basso indica la volonta di scrivere)
    per cambiare tra scrittura e lettura devo prima disattivare l' icap insieme al cambio di modalità e poi riattivarlo*/
    //per leggere un frame devo sempre leggere il famoso frame vuoto
    //per usare più volte questo design devo fare prima un reset per poter rifare il readback
    always @(posedge clk)
    begin
        if (rst_i) 
        begin
            i<=0;
            state<=10;
            ready_o<=1;
            avvio<=0;
             avvia_flash<=0;
             flash<=0;
              ready<=0;
            //data_valid_o<=0;
        end 
        else if (readstrobe_i) 
        begin
            state<=0;
            icap_enable<=1;//disabilitato icap
            icap_write<=1;//lettura
            icap_data_o<=32'hffffffff;
            ready_o<=0;
            avvio<=1;
             avvia_flash<=0;
             flash<=0;
             i<=0;
             addr<=10'h000;
              ready<=0;
            if (r_w==1'b0)
            begin
                state<=8;
            end
            //data_valid_o<=0;
        end
        else if(avvio)
        begin
            //per leggere da icap devo prima abilitarlo e poi abilitare la scrittura del bitstream
            //con le operazioni che devono essere eseguite per il significato delle operazioni
            // UG470 ogni volta che l' icap deve essere cambiato di stato (lettura/scrittura)
            //bisogna essere disabilitato, effettuato il cambio di stato e successivamente riabilitato
            //il nuovo stato dell' icap viene catturato quando l' icap viene riabilitato
            case(state)
            5'b00000:
            begin
                icap_enable<=0;//abilitato
                icap_write<=0;//scrittura
                state<=state+1;
                icap_data_o<=32'hffffffff;
            end 
            5'b00001:
            begin
                //icap_enable<=0;//abilitato
                //icap_write<=0;//scrittura
                state<=state+1;
                icap_data_o<=32'haa995566;
            end
            5'b00010: 
            begin
                state<=state+1;
                icap_data_o<=32'h20000000;
            end
            5'b00011: 
            begin
                state<=state+1;
                //RICORDARSI DI TOGLIERE QUESTI DUE STATI
                //icap_data_o<=32'h30008001;
            end
            5'b00100: 
            begin
                state<=state+1;
                //icap_data_o<=32'h00000008;
            end
            5'b00101: 
            begin
               
                if (i<=464)
                begin
                    i<=i+1;
                    icap_data_o<=dati[14911-i*32-:32];
                end
                else
                begin 
                     state<=state+1;
                     icap_data_o<=dati[31:0];
                end
                
            end
            5'b00110: 
            begin
                state<=state+1;
                icap_data_o<=32'h30008001;
            end
            5'b00111: 
            begin
                //state<=state+1;
                icap_data_o<=32'h00000003;
                icap_enable<=1;//disabilitato icap
                ready_o<=1; 
                icap_write<=1;
                state<=0;
                i<=0;
                avvio<=0;
            end
            //fino a qui scrittura
            /*default : 
            begin
                state<=30;
                avvio<=0;
                 icap_enable<=0;//disabilitato icap
                 icap_write<=0;//lettura
            end*/
            5'b01000:
            begin
                icap_enable<=0;//abilitato
                icap_write<=0;//scrittura
                state<=state+1;
                icap_data_o<=32'h20000000;
            end
            5'b01001:
            begin
                //icap_enable<=0;//abilitato
                //icap_write<=0;//scrittura
                state<=state+1;
                icap_data_o<=32'hffffffff;
            end
            5'b01010: 
            begin
                state<=state+1;
                icap_data_o<=32'haa995566;
            end
            5'b01011: 
            begin
                state<=state+1;
                icap_data_o<=32'h20000000;
            end
            5'b01100: 
            begin
                state<=state+1;
                icap_data_o<=32'h30008001;
            end
            5'b01101: 
            begin
                state<=state+1;
                icap_data_o<=32'h0000000c;
            end
            5'b01110: 
            begin
                state<=state+1;
                icap_data_o<=32'h20000000;
            end
            5'b01111: 
            begin
                state<=state+1;
                icap_data_o<=32'h20000000;
            end
            5'b10000: 
            begin
                state<=state+1;
                icap_data_o<=32'h20000000;
            end
            5'b10001: 
            begin
                state<=state+1;
                icap_data_o<=32'h20000000;
            end
            5'b10010: 
            begin
                state<=state+1;
                icap_data_o<=32'h30002001;
            end
            5'b10011: 
            begin
                state<=state+1;
                icap_data_o<=32'h00000000;
            end
            5'b10100: 
            begin
                state<=state+1;
                icap_data_o<=32'h30008001;
            end
            5'b10101: 
            begin
                state<=state+1;
                icap_data_o<=32'h00000004;
            end
            5'b10110: 
            begin
                state<=state+1;
                icap_data_o<=32'h30002001;
            end
            5'b10111: 
            begin
                state<=state+1;
                icap_data_o<=address_frame;
                //icap_data_o<=32'h00C00000;
                //icap_data_o<=32'h00420f1f;
                //icap_data_o<=32'h0040011f;
            end
            5'b11000: 
            begin
                state<=state+1;
                icap_data_o<=32'h28006000;
            end
            5'b11001: 
            begin
                state<=state+1;

                icap_data_o<=32'h480000CA;
            end
            5'b11010:
            begin
                        icap_data_o<=32'h20000000;
                        state<=state+1;
                        icap_enable<=1; //disabilito icap per fare cambio da scrittura a lettura
                        icap_write<=1; //lettura
            end
            5'b11011: 
                            begin
                                state<=state+1;
                                icap_data_o<=32'h20000000;
                                icap_enable<=0;//riabilito icap per leggere
                            end
            5'b11100: 
             begin
                
                if (i<8'b00000010)
                begin
                  i<=i+1;
                  icap_data_o<=32'h20000000;
                end
                else
                begin
                     state<=state+1;
                     i<=0;
                end
             end
            5'b11101:
            begin
                if (i < (num_frame/2)+2) 
                begin
                    i<=i+1;

                end
                else if( i>=((num_frame/2)+2) &&(i<(num_frame+2)) ) 
                begin
                   data[3231-((i-103)*32)-:32]<=icap_data_i;
                   i<=i+1;
                end
                else
                begin
                    i<=0;
                    state<=state+1;
                    icap_enable<=1;//disabilito icap
                    icap_write<=1;//imposto di default a lettura
                end
            end 
            5'b11110:
            begin
                if (i<1)
                begin
                    if (flash==0 )
                    begin
                        avvia_flash<=1'b1;
                        operazione_flash<=2'h0;
                        address<=0;
                        flash<=1;
                    end
                    else if (flash && !ready) 
                    begin
                        if (!flash_pronta)
                        begin
                            ready<=1;
                        end
                    end
                    else if (flash && ready) 
                    begin
                        avvia_flash<=1'b0; 
                        if (flash_pronta==1'b1)
                        begin
                         i<=i+1;
                         //avvia_flash<=1'b0;
                        ready<=0;
                         flash<=0;
                        end
                    end
                end
                else if (i>=1 && i<8)
                begin
                    if (flash==0)
                    begin
                        avvia_flash<=1'b1;
                        operazione_flash<=2'h1;
                        address<=24'h200*(i-1);
                        dati_da_salvare<=data[3231-(512*(i-1))-:512];
                        flash<=1;
                    end
                    else if (flash && !ready) 
                    begin
                        if (!flash_pronta)
                        begin
                            ready<=1;
                        end
                    end
                    else if (flash && ready)
                    begin
                        avvia_flash<=1'b0; 
                        if (flash_pronta==1'b1)
                        begin
                         i<=i+1;
                         //avvia_flash<=1'b0;
                         ready<=0;
                         flash<=0;
                        end
                    end
                    
                    
                end
                else if (i>=8 && i<15)
                begin
                    if (flash==0)
                    begin
                        avvia_flash<=1'b1;
                         address<=24'h200*(i-8);
                        operazione_flash<=2'h2;
                        flash<=1;
                    end
                     else if (flash &&! ready) 
                    begin
                        if (!flash_pronta)
                        begin
                            ready<=1;
                        end
                    end
                    else if (flash && ready)
                    begin
                        avvia_flash<=1'b0;
                        if (flash_pronta==1'b1)
                        begin
                            i<=i+1;
                            ready<=0;
                            flash<=0;
                        end
                    end
                end 
                else
                begin
                    i<=0;
                    state<=state+1;
                    ready_o<=1;
                    icap_enable<=0;
                    icap_write<=0;
                end
                //icap_data_o<=;
            end
            default : 
            begin
                state<=31;
                avvio<=0;
                 icap_enable<=0;
                icap_write<=0;
            end
        endcase
            /*case(state) macchina per lettura del frame
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
            endcase*/
        end
    end
    
ila_0 ILA_inst (
    .clk(clk),
    .probe0(i[0]), // input [0 : 0] PROBE0
    .probe1(i[1]), // input [0 : 0] PROBE1
    .probe2(i[2]), // input [0 : 0] PROBE2
    .probe3(i[3]), // input [0 : 0] PROBE3
    .probe4(i[4]), // input [0 : 0] PROBE4
    .probe5(i[5]), // input [0 : 0] PROBE5
    .probe6(i[6]), // input [0 : 0] PROBE6
    .probe7(readstrobe_i),
    .probe8(state[0]),
    .probe9(state[1]),
    .probe10(state[2]),
    .probe11(state[3]),
    .probe12(state[4]),
    .probe13(i[7]),
    .probe14(ready_o),
    .probe15(i[8]),
    .probe16(avvio),
    .probe17(quad_spi_line_i),
    .probe18(quad_spi_line_o),
    .probe19(i[9]),
    .probe20(icap_data_i)
 );
/*ila_2 ila(
    .clk(clk),
    .probe0(data));*/
endmodule
