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
`define READ 2'h0  
`define WRITE 2'h1
`define RESET 2'h2
module icap(
   input wire clk,
   input wire rst_i,
   input wire readstrobe_i, //avvia la lettura
   input wire [1:0] r_w, //scrivo se 1 leggo se 0
   /*input wire d,
   output reg q, usato per il flip flop */ 
   output reg ready_o, //mi dice che l' operazione è terminata
   //output reg[4:0] state usato per debug
   input wire quad_spi_line_o, //MOSI
   output reg quad_spi_line_i,
   output reg ritorno,
   output reg cs_n
);
    reg [4:0] state;
    reg [9:0] i;
    reg [4:0] j;//mi serve per contare il salto della bram
    reg    [31:0]  icap_data_i;//dati letti dall' icap
    reg     [31:0]  icap_data_o;//dati scritti utilizzando l' icap
    reg     icap_enable; //abilita icap
    reg     icap_write; //decide se l'icap viene usato in lettura o in scrittura
    reg [7:0] num_frame=8'b11001010;
    /*wire    avvia_lettura;
    wire    reset; utilizzati dai debouncer per debug del singolo componente*/
    reg    avvio; //avvia FSM Icap
    reg ready; //Icap ha terminato la sua operazione

    reg [9:0] addr;//indirizzo dato alla bram
    reg en_bram;// abilito le operazioni sulla bram
    reg [35:0] val_bram;//indirizzo letto dalla BRAM di cui fare il checkpoint
    reg [3231:0] data;//utilizzato per debug all' inizio è uguale al valore di frame può essere sovrascritto in questo 
                      //esempio quando si legge dall' icap
    reg [31:0] address_frame=32'h00000000;
    //frame iniziale per la configuzione
    //reg [1183:0] prologe=1184'h30022001000000003002000100000000300080010000000020000000300080010000000720000000200000003001200102003fe53001c0010000000030018001036310933000800100000009200000003000c001000004013000a001000005013000c001000000003003000100000000200000002000000020000000200000002000000020000000200000002000000030002001;
                                              
    
    //restante parte del frame inizile per la configurazione dato dopo il valore dell' indirizzo
    //reg [159:0] prologe_1=160'h30008001000000012000000030004000500000CA;
    //reg [3231:0] frame=3232'h100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000EC30000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    //frame dummy deve essere dato prima della scrittura di tutti i frame
    //reg [3231:0] dummy_frame=3232'h0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
    //reg [3839:0] epilogue=3840'h2000000020000000300080010000000a200000003000800100000003200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000003000800100000005200000003000200103be00003000c001000005013000a001000005012000000020000000300080010000000d;
    //serve per fare il flush dei dati controllore se inutile
    //reg [3231:0] noop_frame=3232'h2000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000;
    //reg [1375:0] prologe_2=1376'h30022001000000003002000100000000300080010000000020000000300080010000000720000000200000003001200102003fe53001c0010000000030018001036310933000800100000009200000003000c001000004013000a001000005013000c0010000000030030001000000002000000020000000200000002000000020000000200000002000000020000000300020010000000030008001000000012000000030004000500000CA;
    //reg [7103:0] dati;
    reg [7263:0] dati;
    //reg [14911:0] dati;
    //reg [14911:0] dati=14912'h30022001000000003002000100000000300080010000000020000000300080010000000720000000200000003001200102003fe53001c0010000000030018001036310933000800100000009200000003000c001000004013000a001000005013000c0010000000030030001000000002000000020000000200000002000000020000000200000002000000020000000300020010040011f30008001000000012000000030004000500000CA000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000EC0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000020000000300080010000000a200000003000800100000003200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000003000800100000005200000003000200103be00003000c001000005013000a001000005012000000020000000300080010000000d2000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000;

    reg avvia_flash; //avvia operazione su flash
    reg flash_pronta; //la flash è pronta per ricevere un comando
    reg [23:0] address; //indirizzo in cui la flash può scrivere
    reg [511:0] dati_da_salvare; //per il momento salvo 512 bit alla volta ma la flash permette anceh il salvataggio
                                 // di un maggiore quantità di dati
    reg [511:0] dati_da_leggere;                            
    reg [1:0] operazione_flash; //indica l' operazione da fare sulla flash
    reg flash; //indica se ho dato la configurazione alla flash
    reg [7:0] read_data;
    //reg started;
   

   reg [31:0] risultato_and;
   reg [35:0] buffer;
   reg [35:0] buffer1;
   reg [35:0] buffer2;
   reg [35:0] buffer3;
   reg [35:0] buffer4;
   reg [1:0]counter1;
   reg [1:0]counter2;
   reg [1:0]counter3;
    reg [1:0]counter4;
   reg [1:0] scelta=0;
   
   //reg reset_flash;
    //reg [14911:0] dati=14912'h30022001000000003002000100000000300080010000000020000000300080010000000720000000200000003001200102003fe53001c0010000000030018001036310933000800100000009200000003000c001000004013000a001000005013000c0010000000030030001000000002000000020000000200000002000000020000000200000002000000020000000300020010040011f30008001000000012000000030004000500000CA000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000EC0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002000000020000000300080010000000a200000003000800100000003200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000003000800100000005200000003000200103be00003000c001000005013000a001000005012000000020000000300080010000000d2000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000200000002000000020000000;
    //reg [4:0]   state;
    reg [31:0] counter;
    reg enable_counter;
    counter_reg #(.prova(1)) c_r 
  (.out(counter),.enable(enable_counter),.clk(clk),.reset(rst_i));
    icap_template icap(.clk_i(clk),.data_i(icap_data_o),.write_i(icap_write),.en_i(icap_enable),.data_o(icap_data_i));
    bram frame_da_salvare(addr,clk,val_bram,en_bram,1'b0,36'h000000000,rst_i,4'b0000);
    //debouncer debounce1(.clk(clk),.PB(readstrobe_i),.PB_state(avvia_lettura));
    //debouncer debounce2(.clk(clk),.PB(rst_i),.PB_state(reset));
    controllore_flash controllore_flash(.clk_i(clk),.start(avvia_flash),.reset(rst_i),.data_in(dati_da_salvare),.data_out(dati_da_leggere),.address(address),
        .operation(operazione_flash),.done(flash_pronta),.quad_spi_line_i(quad_spi_line_i),
        .quad_spi_line_o(quad_spi_line_o),.cs_n(cs_n),.read_data(read_data));

    comparator comp (.clk(clk),.first_operand(buffer[35:4]),.second_operand(icap_data_i),.result(risultato_and));
    //flip_flop_d ff_d(.data(d),.clk(clk_i),.q(q));
    initial begin
        state<=0;
        icap_enable<=1;
        icap_write<=1;
        ready_o<=1;
        avvio<=0;
        flash<=0;
        //data<=frame;
        avvia_flash<=0;
        en_bram<=1;
         ready<=0;
         addr<=10'h000;
         //reset_flash<=1;

        
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
        state<=0;
        ready_o<=1;
        avvio<=0;
        avvia_flash<=0;
        flash<=0;
        ready<=0;
        addr<=10'h000;
        //reset_flash<=1;
            //data_valid_o<=0;
            icap_enable<=1;//disabilitato icap
            icap_write<=1;//lettura
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
            //data_valid_o<=0;
          end
          else if(avvio)
          begin
            //per leggere da icap devo prima abilitarlo e poi abilitare la scrittura del bitstream
            //con le operazioni che devono essere eseguite per il significato delle operazioni
            // UG470 ogni volta che l' icap deve essere cambiato di stato (lettura/scrittura)
            //bisogna essere disabilitato, effettuato il cambio di stato e successivamente riabilitato
            //il nuovo stato dell' icap viene catturato quando l' icap viene riabilitato
            case(r_w)
              `RESET:
              begin
                case(state)
                  5'b00000:
                  begin
                    icap_write<=0;//scrittura
                    icap_enable<=0;//abilitato //dovrei aspettare un ciclo di clock prima che icap si abiliti
                    state<=state+1;

                    icap_data_o<=32'hffffffff;
                  end
                  5'b00001:
                  begin
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
                     icap_data_o<=32'h30020001;
                  end
                   5'b00100:
                  begin
                     state<=state+1;
                     icap_data_o<=32'h00400000;
                  end
                   5'b00101:
                  begin
                     state<=state+1;
                     icap_data_o<=32'h20000000;
                  end
                   5'b00110:
                  begin
                     state<=state+1;
                     icap_data_o<=32'h30008001;
                  end
                   5'b00111:
                  begin
                     state<=state+1;
                     icap_data_o<=32'h0000000F;

                  end
                endcase
              end

                 
              `WRITE:
              begin
                case(state)
                  5'b00000:
                  begin
                    //reset_flash<=0;
                    ritorno<=0;
                    addr<=10'h000;
                    if (i>=0 && i<7)
                    begin
                      if (flash==0)
                      begin
                        avvia_flash<=1'b1;
                        operazione_flash<=2'h2;//scrivo il frame
                        address<=24'h000000+i*512;
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

                          if (i==0)
                          begin

                            data[3231-:512]<=dati_da_leggere;


                          end
                          else if(i==6)
                          begin
                            data[159:0]<=dati_da_leggere[511:352];


                            i<=i+1;

                          end
                          else 
                          begin
                            data[2719-(i-1)*512-:512]<=dati_da_leggere;

                          end
                          ready<=0;
                          flash<=0;
                          i<=i+1;
                         //avvia_flash<=1'b0;

                       end
                     end



                   end
                   else
                   begin
                     /*dati<={224'h300080010000000B3000800100000007300180011363109330002001,
                    val_bram[31:0],
                    128'h300080010000000130004000500000CA,
                    data,
                    3232'h0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,
                    256'h300080010000000a300080010000000d20000000200000002000000020000000};*/
                    dati<={384'h300080010000000B3001200102007FFF3000800100000007200000002000000020000000300180011363109330002001,
                    val_bram[31:0],
                    128'h300080010000000130004000500000CA,
                    data,
                    3232'h0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000,
                    256'h3001200102003FE520000000200000002000000020000000300080010000000a};
                    state<=state+1;

                    i<=0;

                    icap_write<=0;//scrittura
                    icap_enable<=0;//abilitato //dovrei aspettare un ciclo di clock prima che icap si abiliti

                    //reset_flash<=1;
                    icap_data_o<=32'hffffffff;
                  end

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

               //if (i==0)
                //begin
                  icap_data_o<=32'h20000000;
                  
                  state<=state+1;
                  i<=0;
                  

                  
                /*end
                else if (i==1)
                begin
                   i<=i+1;
                   icap_data_o<=32'h30008001;
                end
                else if (i==2)
                begin
                   icap_data_o<=32'h0000000B;
                   i<=0;
                   state<=state+1;
                 end*/


                //addr<=10'h000;//mi serve per dire quale frame voglio scrivere, letto dalla bram
              end
              5'b00011: 
              begin
                i<=i+1;
                if (i<=225)
                begin
                  
                  icap_data_o<=dati[7263-i*32-:32];
                end 
                else if(i==226)
                begin 
                   icap_data_o<=dati[31:0];
                end
                else
                begin
                   state<=state+1;
                   icap_data_o<=32'h20000000;
                   i<=0;
                end
             end
             5'b00100: 
             begin
              state<=state+1;
              icap_data_o<=32'h20000000;
              icap_enable<=1;
              icap_write<=1;//disabilitato icap

            end
            5'b00101: 
            begin
              
                  ready_o<=1; 

                  state<=31;
                  avvio<=0;
                end
              endcase
            end
            //fino a qui scrittura
            /*default : 
            begin
                state<=30;
                avvio<=0;
                 icap_enable<=0;//disabilitato icap
                 icap_write<=0;//lettura
               end*/

               `READ:
               begin
                case(state)
                  5'b00000:
                  begin
                    ritorno<=0;
                     addr<=10'h000;//mi serve per dire quale frame voglio leggere, letto dalla bram
                icap_enable<=0;//abilitato
                icap_write<=0;//scrittura
                state<=state+1;
                icap_data_o<=32'h20000000;
              end
              5'b00001:
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
                icap_data_o<=32'h00000005;
              end
              5'b00110: 
              begin
                state<=state+1;
                icap_data_o<=32'h30008001;
              end
              5'b00111: 
              begin
                state<=state+1;
                icap_data_o<=32'h0000000c;

                
              end
              5'b01000: 
              begin
                state<=state+1;
                icap_data_o<=32'h20000000;
                 ritorno<=1;

              end
              5'b01001: 
              begin
                state<=state+1;
                icap_data_o<=32'h20000000;
              end
              5'b01010: 
              begin
                state<=state+1;
                icap_data_o<=32'h20000000;
              end
              5'b01011: 
              begin
                state<=state+1;
                icap_data_o<=32'h20000000;
              end
              5'b01100: 
              begin
                state<=state+1;
                icap_data_o<=32'h30002001;
              end
              5'b01101: 
              begin
                state<=state+1;
                icap_data_o<=32'h00000000;
              end
              5'b01110: 
              begin
                state<=state+1;
                icap_data_o<=32'h30008001;
              end
              5'b01111: 
              begin
                state<=state+1;
                icap_data_o<=32'h00000004;
              end
              5'b10000: 
              begin
                state<=state+1;
                icap_data_o<=32'h30002001;
                
                addr<=10'h001;//devo iniziare a leggere la prima maschera ed il salto
              end
              5'b10001: 
              begin
                state<=state+1;
                icap_data_o<=val_bram[31:0];
                addr<=10'h002;//devo iniziare a leggere la prima maschera ed il salto
                //icap_data_o<=32'h00C00000;
                //icap_data_o<=32'h00420f1f;
                //icap_data_o<=32'h0040011f;
                
              end
              5'b10010: 
              begin
                state<=state+1;
                icap_data_o<=32'h28006000;
                addr<=10'h003;//devo iniziare a leggere la prima maschera ed il salto
                buffer<=val_bram;
                
              end
              5'b10011: 
              begin
                state<=state+1;
                icap_data_o<=32'h480000CA;
                addr<=10'h004;//devo iniziare a leggere la prima maschera ed il salto
                buffer1<=val_bram;

              end
              5'b10100:
              begin
                icap_data_o<=32'h20000000;
                state<=state+1;
                        icap_enable<=1; //disabilito icap per fare cambio da scrittura a lettura
                        icap_write<=1; //lettura
                         //addr<=10'h005;//devo iniziare a leggere la prima maschera ed il salto
                          buffer2<=val_bram;
                      end
                      5'b10101: 
                      begin
                        state<=state+1;
                        icap_data_o<=32'h20000000;
                        icap_enable<=0;//riabilito icap per leggere
                        buffer3<=val_bram;

                      end
                5'b10110: 
                              begin

                if (i<8'b00000010) //perdo tre colpi di clock per far si che l' icap si avvii
                begin
                  i<=i+1;
                  icap_data_o<=32'h20000000;
                  //reset_flash<=0;
                  //buffer4<=val_bram;
                end
                else
                begin
                 state<=state+1;
                 i<=0;
                     j<=0;//inizializzo counter salto
                   end
                 end
            5'b10111: //leggo due frame perchè uno è il dummy l' altro è quello voluto
            begin
                if (i < ((num_frame/2)+4) )//quando i ==2 inizia a leggere il dummy frame ad i==105 primo frame utile
                begin
                  i<=i+1;
                  counter1<=2;
                  counter2<=2;
                  counter3<=2;
                  scelta<=0;

                end
                else if( (i>=((num_frame/2)+4)) &&(i<(num_frame+4)) ) //il più 4 è un numero perchè ci mette più tempo di un frame per darmi idati
                begin
                  data[3231-((i-105)*32)-:32]<=risultato_and;
                  if(j[3:0]==buffer[3:0])
                  begin

                    if (scelta==0)
                    begin
                      buffer<=buffer1;                               
                      scelta<=1;
                      counter1<=1;
                    end

                    if( scelta==1)
                    begin
                      buffer<=buffer2;
                      scelta<=2;
                      counter2<=1;
                    end

                    if( scelta==2)
                    begin
                      buffer<=buffer3;
                      counter3<=1;
                      scelta<=0;
                    end

                    

                    addr<=addr+1;
                    j<=0; 

                    if (counter1==0)
                    begin
                      buffer1<=val_bram;
                      counter1<=2;
                    end

                    if (counter2==0)         
                    begin
                      buffer2<=val_bram;
                      counter2<=2;
                    end

                    if (counter3==0)
                    begin
                      buffer3<=val_bram;
                      counter3<=2;
                    end
                
                            /*buffer<=buffer1;
                            buffer1<=buffer2;
                            buffer2<=val_bram;*/


                          end
                          else
                          begin
                        //data[3231-((i-103)*32)-:32]<=32'h00000000;
                        j<=j+1;

                        
                      end

                      if (counter1>0 && counter1<=1)
                      begin
                        counter1<=counter1-1;
                      end

                      if (counter2>0 && counter2<=1)
                      begin
                        counter2<=counter2-1;
                      end

                      if (counter3>0 && counter3<=1)
                      begin
                        counter3<=counter3-1;
                      end
                    //if(((buffer2[3:0]==4'b0000) && (buffer1[3:0]==4'b0000)&&(buffer[3:0]==4'b0000))||((buffer2[3:0]==4'b0000) && (shift==1'b1)) || ((buffer2[3:0]==4'b0001) && (shift==1'b1)) || ((j==buffer[3:0]-2)&& (shift==1'b1)) )
                    /*if((j==buffer[3:0]-2) ||((buffer2[3:0]==4'b0000) &&(shift==1'b1)||((buffer2[3:0]==4'b0001) &&(shift==1'b1)))
                    begin
                        addr<=addr+1;
                        shift<=1'b0;
                      end*/
                      i<=i+1;

                    end
                    else
                    begin
                      if(i==206)
                      begin
                      icap_enable<=1;//disabilito icap
                       icap_write<=0;//scrittura
                       i<=i+1;
                     end
                     else  if(i==207)
                     begin
                       icap_enable<=0;//abilito icap
                       i<=i+1;
                       
                     end
                     else  if(i==208)
                     begin
                      icap_data_o<=32'h30008001;
                      i<=i+1;
                    end
                    else  if(i==209)
                    begin
                      icap_data_o<=32'h00000006;
                      i<=i+1;
                    end
                     else  if(i==210)
                     begin
                      icap_data_o<=32'h30008001;
                      i<=i+1;
                    end
                    else  if(i==211)
                    begin
                      icap_data_o<=32'h0000000D;
                      i<=i+1;
                    end
                    else  if(i==212)
                    begin
                      i<=0;
                       icap_enable<=1;//disabilito icap
                       state<=state+1;
                     end




                   end
                 end 
                 5'b11000:
                 begin
                  if (i<1)
                  begin
                    if (flash==0 ) //dico prima quale operazione devo fare sulla flash
                    begin
                      avvia_flash<=1'b1;
                      operazione_flash<=2'h0;//cancello la pagina
                      address<=0;
                      flash<=1;
                    end
                    else if (flash && !ready) // mi serve per attendere che la FSM dell flash parta
                                              //clock generato a 50 MHz non stabile
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
                      operazione_flash<=2'h1;//scrivo il frame
                      address<=24'h200*(i-1);
                      if (i==7)
                      begin
                        dati_da_salvare[511:352]<=data[159:0];
                        dati_da_salvare[351:0]<=0;

                      end
                      else
                      begin
                        dati_da_salvare<=data[3231-(512*(i-1))-:512];
                      end
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
                  ready_o<=1;
                  //reset_flash<=1;

                end
                else
                begin
                  i<=0;
                  state<=31;
                  ready_o<=1;
                   avvio<=0;
                end
                //icap_data_o<=;
              end

            endcase
          end
        endcase
        end
      end
    
ila_0 ILA_inst (
    .clk(clk),
    .probe0(addr), // input [0 : 0] PROBE0
    .probe1(j), // input [0 : 0] PROBE1
    .probe2(i), // input [0 : 0] PROBE2
    .probe3(buffer), // input [0 : 0] PROBE3
    .probe4(buffer1), // input [0 : 0] PROBE4
    .probe5({4'b1111,risultato_and}), // input [0 : 0] PROBE5
    .probe6({4'b1111,val_bram[35:4]}), // input [0 : 0] PROBE6
    .probe7(counter1),
    .probe8(r_w),
    .probe9({readstrobe_i,avvio}),
    .probe10(icap_data_i),
    .probe11(scelta),
    .probe12(icap_data_o),
    .probe13(buffer2[35:4]),
    .probe14(state),
    .probe15({4'b1111,address})
 );
/*ila_2 ila(
    .clk(clk),
    .probe0(data));*/
    ila_3 ila_icap(
    .clk(clk),
    .probe0(dati_da_leggere),
    .probe1({flash_pronta,ready,i[2:0]}),
    .probe2(1'b0),
    .probe3(8'h0));
endmodule
