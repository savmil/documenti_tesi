#mi server per trasformare una strina binaria in esadecimale
proc setHexBinTbl {} {
  global array arrayHexBinVal

  set arrayHexBinVal(0000) 0
  set arrayHexBinVal(0001) 1
  set arrayHexBinVal(0010) 2
  set arrayHexBinVal(0011) 3
  set arrayHexBinVal(0100) 4
  set arrayHexBinVal(0101) 5
  set arrayHexBinVal(0110) 6
  set arrayHexBinVal(0111) 7
  set arrayHexBinVal(1000) 8
  set arrayHexBinVal(1001) 9
  set arrayHexBinVal(1010) A
  set arrayHexBinVal(1011) B
  set arrayHexBinVal(1100) C
  set arrayHexBinVal(1101) D
  set arrayHexBinVal(1110) E
  set arrayHexBinVal(1111) F

}
proc searchinfile {filename component &list_net &frame} {
	puts $component
	set file [open $filename]
	array set list_offset {}
	#ottengo la lista dei componenti che voglio esportare
	upvar 1 ${&list_net} l_n 
	upvar 1 ${&frame} frame
	puts "qui"
	set number_offset 0
	while {[gets $file line] != -1} {
		#pulisco il frame per evitare di avere copie multiple
		
		#cerco stringhe che hanno il node del componente
	    if {[regexp "$component" $line all value]} {
	        set frame ""
	        set line [string map {" " ""} $line]
	        #puts $line
	        set pos [string first 0x $line] 
	        # prendo il frame
	        append frame [string range $line $pos+2 $pos+9] 
	        puts $frame
	        
	        set netpos [string first "Net=" $line] 
	        #ottengo il valore Net= dal .ll
	        set net [string range $line $netpos+4 end] 
	        puts "net [string range $line $netpos+4 end] "
	        set offset ""
	        set i 10
	        set check_number [string range $line $pos+$i $pos+$i]
	        #questo while mi serve per prendere i valori di offset dopo il frame, perchè dopo offset ho carattere
	        #l'offset presente nel .ll
	        while {[string is integer $check_number]} { 
	        	set i [expr {$i + 1}]
	        	#puts $check_number
	        	append offset $check_number
	        	set check_number [string range $line $pos+$i $pos+$i]
	        }
	        append offset " "
	        #puts $offset
	        append list_offset($number_offset) $offset
	        append l_n($offset) $net
	        set number_offset [expr $number_offset +1]
	    }

	} 
	puts "frame $frame"
	array set list_net [array get l_n]
	close $file
	return [array get list_offset]
}
proc changebit {filename_source filename_dest list_offset_source list_offset_dest list_net_source list_net_dest frame_dest} {
	set file [open $filename_source]
	set file1 [open $filename_dest]
	set bit_number 0
	set line_number 0
	set frame_number 0
	set frame ""
	set frame_da_scrivere ""
	setHexBinTbl
	global arrayHexBinVal
	array set l_o_s $list_offset_source
	array set l_o_d $list_offset_dest
	array set l_n_s $list_net_source
	array set l_n_d $list_net_dest
	array set to_change_source {}
	array set to_change_dest {}
	puts "qui"
	#mi serve per ottenere dal file sorgente i bit da scrivere nel file di destinazione
	while {[gets $file line] != -1} {
			set line_number [expr $line_number+1]
			#mi interessano solo le linee che non sono dummy
			if $line_number>101 {
				set current_line [expr {$line_number-101}]
				set number_of_bit_in_line [expr $current_line * [string length $line]]

				while {$bit_number<$number_of_bit_in_line} {
					set bit_number [expr $bit_number+1]
				
					set pos_in_line [expr [expr $current_line * [string length $line]]-$bit_number ]
					
					 #la stringa del readback va letta da destra a sinistra
					set string_pos [expr $bit_number - [expr {$line_number-101} * [string length $line]]]

				
					#al valore dell' offset aggiungo 1 perchè non parto da 0
					if {[expr $l_o_s($frame_number)+1] == $bit_number} {
						#mi salvo la posizione del bit nel file sorgente ed il valore da sostituire
						append to_change_source($bit_number) [string index $line $pos_in_line]
						if {$frame_number >= [expr [array size l_o_s] -1] } {
							
						} else { 
							
							set frame_number [expr $frame_number +1]
						}
						puts "qui"
					
				}
				
			}
		}
	}
	puts "informazioni da scambiare sorgente [array get to_change_source] "
	#creo una lista dei valori che devo scrivere nel file di destinazione con le loro posizioni
	foreach  {key value}  [array get l_n_s] {
    	foreach  {key1 value1}  [array get l_n_d] {
    		if {$value==$value1 } {
    			puts $to_change_source([expr $key+1])
    			append to_change_dest([expr $key1+1]) $to_change_source([expr $key+1])
    			puts "chiavi $key $key1 "
    		}
    	}
	}
	puts "informazioni da scambiare destinazione [array get to_change_dest] "
	set bit_number 0
	set line_number 0
	set frame_number 0
	#creo il frame modificato da caricare
	while {[gets $file1 line] != -1} {
			set line_number [expr $line_number+1]
			if $line_number>101 {
				set current_line [expr {$line_number-101}]
				set number_of_bit_in_line [expr $current_line * [string length $line]]
				#puts "bit nella linea $number_of_bit_in_line"
				#set current_line [expr $current_line+1]
				puts "line $line"
				#puts $line_number
				while {$bit_number<$number_of_bit_in_line} {
					set bit_number [expr $bit_number+1]
					#set pos_in_line [expr $bit_number+31-[expr $current_line * [string length $line]] ]
					#puts "qui"
					set pos_in_line [expr [expr $current_line * [string length $line]]-$bit_number ]
					#puts "qui"
					#puts "pos $pos_in_line"
					#puts [expr [expr [expr $number_of_bit_in_line+1] *[string length $line]] -$bit_number]
					 #la stringa del readback va letta da destra a sinistra
					set string_pos [expr $bit_number - [expr {$line_number-101} * [string length $line]]]

					#puts "string_pos $string_pos"
					#al valore dell' offset aggiungo 1 perchè non parto da 0
					#puts "offset dest $l($frame_number) "
					if {[expr $l_o_d($frame_number)+1] == $bit_number} {
						puts "da scambiare $to_change_dest($bit_number)"
						#puts $l($frame_number)
						#puts "qui"
						if {$frame_number >= [expr [array size l_o_d] -1] } {
							
						} else { 
							
							set frame_number [expr $frame_number +1]
						}
						#puts $frame_number [string index $line $pos_in_line]
						append frame $to_change_dest($bit_number)

					} else {
						
						#puts "qui [string index $line1 $pos_in_line]"
						append frame  [string index $line $pos_in_line]
					}
					#puts "carattere [string index $line $pos_in_line]"
					#puts $bit_number
					#puts "linea $line_number"
				}
				
			}
			
			if {$line_number>101} {
				#devo invertire la stringa prima di salvarla altrimenti la scrivo al contrario
				set frame [string reverse $frame]

				puts "frame 32 $frame"
				

				puts "qui $frame"
				#trasformo il valore binario in uno esadecimale
				for { set a 0}  {$a < [string length $frame]} {incr a 4} {
					puts "stringa [string range $frame $a $a+3] "
   					append frame32 $arrayHexBinVal([string range $frame $a $a+3])

				}
				puts "frame $frame32"
				#append frame_da_scrivere $frame
				#append frame_da_scrivere "\n"
				append frame_da_scrivere $frame32
				set frame32 ""
				set frame ""
				#append frame_da_scrivere "\n"	
			}
	    }
	    #scrivo su un file tutti i comandi per far si da caricare il frame modificato
	    set f "/home/saverio/Scrivania/tesi/script/bitstream_da_inviare.txt"
		set fileId [open $f w]
		puts $fileId "2000000020000000300080010000000b3001200102007FFF30008001000000073001800113631093300080010000000130002001"
		puts $fileId "$frame_dest"
		puts $fileId "30004000500000CA"
		puts $fileId $frame_da_scrivere
		puts $fileId "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000300080010000000a30008001000000033000800100000005300080010000000d200000002000000020000000"
		#puts $frame_da_scrivere
		close $fileId
}
#viegono richiesti i due .ll dei diversi design
proc swapbit {filename filename1} {
	#open_hw
  	#connect_hw_server
    #open_hw_target -jtag_mode true
    array set list_net_source {}
    array set list_net_dest {}
    set frame_source ""
    set frame_dest ""
    #source /home/saverio/Scrivania/tesi/script/Lettura_scrittura_frame_jtag.tcl
    # ottengo la lista degli offset dei bit del componente
	array set list_offset_source_file [searchinfile $filename "c_r/" list_net_source frame_source]
	array set list_offset_dest_file [searchinfile $filename1 "c_r/" list_net_dest frame_dest]
	set file_dest /home/saverio/Scrivania/tesi/script/due_registri
	set file_source /home/saverio/Scrivania/tesi/script/bit_registro.rdbk
	#puts [array get list_net_source]
	#leggo il frame dal dispositivo destinatario
	#leggi_frame $file_source $frame_source 2 1
	puts $frame_dest
	puts $frame_source
	puts "changebit $frame_source"
	puts [array get list_net_source]
	#mi permette di modificare i file da caricare
	changebit $file_source $file_dest [array get list_offset_source_file] [array get list_offset_dest_file] [array get list_net_source] [array get list_net_dest] $frame_dest
	#scrivi_bitstream /home/saverio/Scrivania/tesi/script/bitstream_da_inviare.txt
	#close_hw
	
}
