#devo fare lo swap di due byte consecutivi altrimenti vengono scritti invertiti
proc swap_half_word {data} { 
	set new_data ""
	for {set x 0} {$x<[string length $data]} {incr x 2} {
		append new_data [string range $data  $x+1 $x+1]
		append new_data [string range $data  $x $x]
	}
	return $new_data
}
proc searchinfile {filename component} {
	set mydict [dict create] 
	#uso dizionario perchè ad ogni frame (chiave) do più valori
	puts $component
	set file [open $filename]
	while {[gets $file line] != -1} {
	    if {[regexp "$component" $line all value]} {
	        
	        set line [string map {" " ""} $line]
	        #puts $line
	        set pos [string first 0x $line] 
	        set frame "0"
	        append frame [string range $line $pos+2 $pos+9] 
	        puts "frame $frame"
	        # prendo il frame
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
	        dict append mydict $frame $offset 
	    }
	} 
	#puts [dict get $mydict $frame]
	set bram ""
	#per ogni frame calcolo salto degli offset
	foreach frame [dict keys $mydict]  { 
		append bram $frame
		#append bram "\n"
		#append bram " "
		#append bram 00000000
		#append bram " "
		set i 0
		set f 0
		set frame_num 0
		set avoid_frame -1
		puts "prima bram $bram"
		set same_word 0
		#array set offset {}
		puts "dict [dict get $mydict $frame]"
		# per ogni offset vedo quanti salti ci sono
		set offset [dict get $mydict $frame]
		puts [lindex $offset 0]
		set frame_number [llength $offset]
		while { $frame_num< $frame_number } { 
				
			set f [expr [lindex $offset $frame_num] / 32]
			puts "numero frame $f"
			set f [expr $f-$i]
			puts "numero frame -i $f"
			set i [expr $i+$f ]
			#mi calcolo i salti da fare prima di arrivare al primo offset o tra gli offset
			# f è il numero di word per arrivare all' offset corrente
			# i è l' offset a cui i salti sono arrivati
			while {$f-1 >0} {
				#puts "qui"
				if {$f-1 >=15} {
					append bram 00000000F 
					set f [expr $f -15]
					
				} else {
					append bram 00000000
					puts [expr $f-1]
					append bram [format %X [expr $f-1]] 
					set f 0
					
				}
				
			}
			#puts "offset [lindex $offset $frame_num]"
			#puts "contatore $i"
			
			set off [expr [lindex $offset $frame_num]]
			#calcolo le mashere bit appartenti alla stessa maschera mi danno lo stesso i
			while {$i==[expr $off /32] } {
					puts "i $i"
					puts "off [expr $off /32]" 
					#append bram " salto"
					#append bram [format %X $avoid_frame] 
					#append bram " "
					#puts "avoid_frame $avoid_frame"
					#set avoid_frame -1
					#append bram "word"
					puts "offset $off"
					puts "stessa word $same_word"
					if {$same_word==0} {
						set word [expr 1 << [expr $off % 32]]
					} else {
					set word [expr $word | [expr 1 << [expr $off % 32]]]
					puts " sono qui"
					puts "word same_word [format %X [expr $word]]"
					}
					set same_word 1
					#append bram [format %X [expr $word]]
					#puts "word $word"
					#append bram [format %X [expr $offset % 32]]
					#puts [format %x [expr $offset % 32]]
					#append bram " "
					set frame_num [expr $frame_num +1]
					puts $frame_num
					set off [lindex $offset $frame_num]
					puts  [lindex $offset $frame_num]
					if { $frame_num ==32  } {
						set off [expr $i*32+32+1]
					}
					
				} 
				set word_length [string length[format %X [expr $word]]]
				while {$word_length<8 } {
					append bram 0
					set word_length [expr $word_length+1]
				}
				puts "dimensione word [string length $word]"
				append bram [format %X [expr $word]]
				append bram 0
				set same_word 0
				#set frame_num [expr $frame_num +1]
				puts "word [format %X [expr $word]]"

			#puts "numero word $f"
			puts "bram $bram"
			
			
			# while {$i<$offset} {
			# 		if {$same_word ==1} {
			# 			set same_word 0
			# 			#append bram "word"
			# 			append bram [format %08X $word]
			# 			#puts "word [format %X $word] "
			# 		}
			# 		#al massimo saltiamo 15 frame
			# 		if {$avoid_frame<15} {
			# 			set i [expr {$i + 32}]
			# 			set avoid_frame [expr {$avoid_frame + 1}]
			# 			puts "qui $avoid_frame"


			# 		} else {
			# 			#append bram " salto"
			# 			set i [expr {$i + 32}]
			# 			append bram 00000000 
			# 			#append bram [format %X $avoid_frame] 
			# 			#append bram " "
						
			# 			#append bram " "
						
			# 			#set avoid_frame -1
						
			# 		}
			# 	}

			# 	#questo if mi serve per capire se all' interno di una maschera devo mettere più uno
			# 	#poichè può darsi che due offset siano nella stessa word
				

			# 	if {$same_word ==0} {
			# 		#append bram " salto"
			# 		append bram [format %X $avoid_frame] 
			# 		#append bram " "
			# 		puts "avoid_frame $avoid_frame"
			# 		set avoid_frame -1
			# 		#append bram "word"
			# 		set word [expr 1 << [expr $offset % 32]]
			# 		#puts "word $word"
			# 		#append bram [format %X [expr $offset % 32]]
			# 		#puts [format %x [expr $offset % 32]]
			# 		#append bram " "
			# 		set f [expr {$f +1 }]
			# 		set same_word 1
			# 	} else {
					
			# 		set sec_word [expr 1 << [expr $offset % 32]]
			# 		#puts $sec_word
			# 		#puts "seconda word $sec_word" 
			# 		set f [expr {$f + 1}]
			# 		set word [expr $word | $sec_word] 
			# 		#questa or mi permette di mettere più offset nella stessa maschera
			# 		#puts $word
			# 		#append bram [format %X [expr $offset % 32]]
			# 		#append bram " "
			# 	}
			# puts "numero word $f"
			# puts "bram $bram"
			
		}
		#puts $i
		#puts "f_s $avoid_frame"
		#riempio di salti e zero fino a che non riempio il frame
		set i [expr $i*32]

		while {$i<3232} {
				
				if {$avoid_frame<15} {
					set i [expr {$i + 32}]
					set avoid_frame [expr {$avoid_frame + 1}]
					#puts "qui $avoid_frame"

				} else {
					#append bram "word "
					append bram 00000000 
					#append bram " "
					#append bram " salto"
					append bram [format %X $avoid_frame] 
					#append bram " "
					
					
					set avoid_frame -1
					#puts $i
					#puts $avoid_frame
				}
			}
			puts "bit a cui sono arrivato $i"
			#se non ho scritto l' ultimo salto
			if {$avoid_frame!=0} {
				#append bram "word "
				append bram 00000000 
				#append bram " "
				#append bram " salto"
				append bram [format %X [expr $avoid_frame-1]] 
				#append bram $avoid_frame
				#append bram " "
				set avoid_frame -1
			}
			#puts $i
			set i 0
			append bram "               "
	}
	#puts $bram
	#set bram [swap_half_word $bram]
	#puts $bram
	close $file

	set bram [string map {" " ""} $bram]
	set bram [get_parity $bram]
	puts $bram
	puts "lunghezza [string length $bram]"
	set f "/home/saverio/Scrivania/tesi/script/bram/test.mem"
	set fileId [open $f w]
	puts $fileId "@00000000"
	#scrivo i dati a word di 32 bit altrimenti il file .mem non li riconosce
	for {set x 0} {$x<[string length $bram]-8} {incr x 9} {
		
		puts $fileId [string range $bram $x $x+8]
	}
	set l_s [string range $bram $x end]
	#aggiungo zeri per far si di avere una word da 32
	#for {set x [string length $l_s]} {$x<9} {incr x } {
	#	append l_s 0
	#}
	puts $fileId $l_s
	close $fileId
	
}
proc search_for_frame {filename} {
 [searchinfile $filename "c_r/"]
 #[get_parity "FFFFFFFFA"]
}
proc get_parity {byte_string} {
	set par "0"
	set word "0"
	set parmask 800000000
	set bytemask 7F8000000
	set data ""
	for {set i 0} {$i<[expr [string length $byte_string]]} {incr i 9} {
		puts $i
		set byte [string range $byte_string $i $i+8]
		puts "byte $byte"
		for {set x 0} {$x<4} {incr x} {
		set par [expr $par |  [string range [format %X [expr [expr 0x$byte & [expr 0x$parmask>>$x*9]] <<9*$x+1+(3-$x)  ] ] 0 0]]
		puts "par $par"
		#puts [format %X [expr 0x$parmask>>$x*9]]
		#puts [format %X [expr [expr 0x$byte_string & [expr 0x$parmask>>$x*9]] << 9*$x+1+$x]]
		#puts [string range [format %X [expr [expr 0x$byte_string & [expr 0x$parmask>>$x*9]] << 9*$x+1+$x]] 0 0] 
		
			set word [expr $word | [expr 0x$byte & [expr 0x$bytemask >>$x*9]]>>3-$x ]
		
		
		puts "word [format %X  $word ]"
		}
		#set par [format %b $par]
		set par [format %X $par]
		set word [format %X  $word ] 
		while {[string length $word]<8} {
			set word "0$word"
		}
		
		append par $word
		puts "word modificata con parità $par"
		append data $par
		set par "0"
		set word "0"
	}
	return $data
	
}
