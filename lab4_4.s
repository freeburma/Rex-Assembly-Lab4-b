.data

chZero :
      .asciiz "0"

count : 
        .word 0
        
count2 : 
        .word 0
                

CR: 
        .word 13                # '\r' or 0xD
        
quotient: 
        .word 0  

semi: 
        .asciiz ":"     
        
minute : 
        .word 0
        
second : 
        .word 0                              
                
old_handler:				#A label to refer to the old handler's address
	.word 0
				#Reserve one word to store the old handler's address
.bss						#Ininitialised data segment
        .space 100
stack:    
     
.text
.global main

main:
        la      $sp, stack
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


	
# The Exception Handler
handler:
	# Why are we here?
	movsg $13, $estat		#Load status register
	
	andi $13, $13, 0xFFB0	        #If IRQ2 is the only bit set
	#beqz $13, sp_handler	        #Branch to our sp2_handler
	beqz $13, counter	        #Branch to our sp2_handler
	
	lw $13, old_handler($0)	        #Else load the old handler's address
	jr $13				#And jump to that address


	


counter:  
        lw      $13, count ($0)
        addi    $13, $13, 1                # Adding '1' to $3
        sw      $13, count ($0)
        
        # Getting to Minutes  
        lw      $13, count ($0)
        divi    $13, $13, 60
        sw      $13, minute ($0)
        
        # Getting to Seconds 
        lw      $13, count ($0)
        divi    $13, $13, 60
        sw      $13, second ($0)
        
       
char_second: 
        lw      $13, second ($0)
       
        remui   $13, $13, 10          # Get the remainder if the num is > 10
        addui   $13, $13, 48          # Convert to the digits
        
        subui   $sp, $sp, 1
        sw      $13, 0 ($sp)
        
        # 
        lw      $13, count2 ($0)       
        addi    $13, $13, 1
        sw      $13, count2 ($0)
        
        lw      $13, second ($0)
        divui   $13, $13, 10            # Getting the quotient
        sw      $13, second ($0)
        seqi    $13, $13, 0
        beqz    $13, char_second  
        
        # Checking the single digit 
        lw      $13, count2 ($0)
        seqi    $13, $13, 1
        beqz    $13, semiColon 
        subui   $sp, $sp, 1
        lw      $13, chZero ($0)
        sw      $13, 0 ($sp)             # Adding 0 
        
        
        # Increasing counter 2
        lw      $13, count2 ($0)
        addi    $13, $13, 1
        sw      $13, count2 ($0)
        
semiColon: 
        # Add colon char from the stack                 
        subui   $sp, $sp, 1
        lw      $13, semi ($0)
        sw      $13, 0 ($sp)
        
        # Increase stack count
        lw      $13, count2 ($0)
        addi    $13, $13, 1
        sw      $13, count2 ($0)

char_minute: 
        lw      $13, minute ($0)
       
        remui   $13, $13, 10          # Get the remainder if the num is > 10
        addui   $13, $13, 48          # Convert to the digits
        
        subui   $sp, $sp, 1
        sw      $13, 0 ($sp)
        
        # 
        lw      $13, count2 ($0)       
        addi    $13, $13, 1
        sw      $13, count2 ($0)
        
        lw      $13, minute ($0)
        divui   $13, $13, 10            # Getting the quotient
        sw      $13, minute ($0)
        seqi    $13, $13, 0
        beqz    $13, char_minute                       
        
        
        # Check 4 digits 
        lw      $13, count2 ($0)
        seqi    $13, $13, 4
        beqz    $13, carryReturn
        subui   $sp, $sp, 1
        lw      $13, chZero ($0)
        sw      $13, 0 ($sp)
        
        # Increasing counter 2
        lw      $13, count2 ($0)
        addi    $13, $13, 1
        sw      $13, count2 ($0)        

carryReturn: 
        subui   $sp, $sp, 1
        lw      $13, CR ($0)
        sw      $13, 0 ($sp)
        
        # Increasement in count2
        lw      $13, count2 ($0)
        addi    $13, $13, 1
        sw      $13, count2 ($0)


display: 
        
checkTransmit: 
	lw      $13, 0x70003 ($0)
	andi    $13, $13, 2
	beqz    $13,  checkTransmit	
        #jr $ra
	                   	        
        
        lw $13, 0 ($sp)
        sw $13, 0x70000 ($0)
        addui   $sp, $sp, 1
	
	lw      $13, count2 ($0)
	subi    $13, $13, 1
	sw      $13, count2 ($0)
	seqi    $13, $13, 0
	beqz    $13, display
	
	# Acknowledge the interrupt
	sw $0, 0x72003($0)		#Finished handling it!
	
	# Return from exception
	rfe			        #Get back to what you were doing



	



