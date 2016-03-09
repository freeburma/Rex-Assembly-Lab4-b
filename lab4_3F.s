.data     


count: 
        .word 48                

CR: 
        .word 13                # '\r' or 0xD
        

                
old_handler:				#A label to refer to the old handler's address
	.word 0
				#Reserve one word to store the old handler's address

stack:    

.text
.global main

main:
        lw      $11, count ($0)
        add   $5, $0, $11
        add   $6, $0, $11
        add   $7, $0, $11
        add   $8, $0, $11
Timer: 
        # Clearing the old interrupts of Timer Interrupt Acknowledge Register
        sw $0, 0x72003 ($0)        
        sw $0, 0x72000 ($0)
        addi    $13, $0, 2400
        
        sw      $13, 0x72001 ($0)        # Put value to the timer
        addi    $13, $0, 0x3             # enable timer start
        sw      $13, 0x72000 ($0)        # Store the result Timer Contlrol Register     
	
	
ExceptionControl: 
	# Set up $evec (Where we jump to when an exception occurs)
	movsg $1, $evec			# Retrieve the old handler's address
	sw $1, old_handler($0)	        # Save it to memory - Currently it's nothing
	
	la $1, handler			# Get our new handler's address
	movgs $evec, $1			# Tell the CPU to use this new address to handle exceptions
	
	# Set up $cctrl (Which interrupts we care about)
	addi $1, $0, 0x04A		#IRQ1 on, KU on (Kernel Mode), IE on
	movgs $cctrl, $1	
	

	
loadSwitches:
	lw $2, 0x73000 ($0)             # loading the switches values 
	sw      $2, 0x73003 ($0)
	
	
	srli $2, $2, 4
	
	
	sw $2, 0x73002($0)		# Store the values in left SSD
	
	j loadSwitches
	
checkTransmit: 
	lw      $13, 0x70003 ($0)
	andi    $13, $13, 2
	beqz    $13,  checkTransmit
	jr      $ra        
	
# The Exception Handler
handler:
	# Why are we here?
	movsg $13, $estat		#Load status register
	
	andi $13, $13, 0xFFB0	        #If IRQ2 is the only bit set
	beqz $13, sp_handler	        #Branch to our sp2_handler
	
	
	lw $13, old_handler($0)	        #Else load the old handler's address
	jr $13				#And jump to that address
       

# The Serial Port 1 Exception Handler
sp_handler: 
       addui    $5, $5, 1
       sgti     $10, $5, 57            # char '9'
       beqz     $10, display
       addui    $5, $0, 48              # to convert to char '0' to '9'
       
       addui    $6, $6, 1
       sgti     $10, $6, 57            # char '9'
       beqz     $10, display
       addui    $6, $0, 48              # to convert to char '0' to '9'

       addui    $7, $7, 1
       sgti     $10, $7, 57            # char '9'
       beqz     $10, display
       addui    $7, $0, 48              # to convert to char '0' to '9'
       
       addui    $8, $8, 1
      
       
display:
        jal     checkTransmit
	addui   $13, $0, 13             # 'CR' 0xD
	sw      $13, 0x70000 ($0)

        jal     checkTransmit
	sw      $8, 0x70000 ($0)	
	
        jal     checkTransmit
	sw      $7, 0x70000 ($0)

        jal     checkTransmit
        sw      $6, 0x70000 ($0)			

        jal     checkTransmit
        sw      $5, 0x70000 ($0)	
		
	# Acknowledge the interrupt
	sw $0, 0x72003($0)		#Finished handling it!
	
	# Return from exception
	rfe			        #Get back to what you were doing



	



