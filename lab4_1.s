.text
.global main

main:

# This will read the switches value and display it on both SSD

	
	# Set up $evec (Where we jump to when an exception occurs)
	movsg $1, $evec			# Retrieve the old handler's address
	sw $1, old_handler($0)	        # Save it to memory - Currently it's nothing
	
	la $1, handler			# Get our new handler's address
	movgs $evec, $1			# Tell the CPU to use this new address to handle exceptions
	
	# Set up $cctrl (Which interrupts we care about)
	addi $1, $0, 0x02A		#IRQ1 on, KU on (Kernel Mode), IE on
	movgs $cctrl, $1	
	
	
	
loadSwitches:
	lw $2, 0x73000 ($0)             # loading the switches values 
	sw $2, 0x73003($0)		# Store the values in left SSD
	#andi $2, $2, 1
	srli $2, $2, 4
	sw $2, 0x73002($0)		# Store the values in Right SSD
	j loadSwitches
	

	
# The Exception Handler
handler:
	# Why are we here?
	movsg $13, $estat		#Load status register
	
	andi $13, $13, 0xFFD0	        #If IRQ1 is the only bit set
	beqz $13, sp_handler	        #Branch to our sp2_handler
	
	lw $13, old_handler($0)	        #Else load the old handler's address
	jr $13				#And jump to that address


	
# The Serial Port 1 Exception Handler
sp_handler: 
checkTransmit: 
	lw      $13, 0x70003 ($0)
	andi    $13, $13, 2
	beqz    $13,  checkTransmit
	
 
        addi $13, $0, 'X'                # Adding 'X' to $3
        
   
              	
	sw $13, 0x70000($0)		#Transmit the value through SP1
	
	
	# Acknowledge the interrupt
	sw $0, 0x7F000($0)		#Finished handling it!
	
	# Return from exception
	rfe			        #Get back to what you were doing



.bss						#Ininitialised data segment
old_handler:				#A label to refer to the old handler's address
	.word					#Reserve one word to store the old handler's address
