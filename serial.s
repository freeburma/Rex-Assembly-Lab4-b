.text
.global main

main:
	# Set up $evec (Where we jump to when an exception occurs)
	movsg $1, $evec			#Retrieve the old handler's address
	sw $1, old_handler($0)	#Save it to memory
	la $1, handler			#Get our new handler's address
	movgs $evec, $1			#Tell the CPU to use this new address to handle exceptions
	
	# Set up $cctrl (Which interrupts we care about)
	addi $1, $0, 0x20A		#IRQ5 on, KU on (Kernel Mode), IE on
	movgs $cctrl, $1	
	
	# Set up serial device interrupts (Tell the device to generate interrupts)
	sw $0, 0x71004($0) 		# Acknowledge any old interrupts
	lw $1, 0x71002($0) 		# Load existing serial port configuration
	ori $1, $1, 0x100		# Turn on the Receive Interrupt Enable bit = $Serial Contlrol Register
	sw $1, 0x71002($0)		# Save new configuration back to the device
	
# The mainline code loop
mainline:
	sw $1, 0x73002($0)		# Write garbage to the SSDs
	sw $1, 0x73003($0)		# Just to see that this loop is working
	addi $1, $1, 1
	j mainline

# The Exception Handler
handler:
	# Why are we here?
	movsg $13, $estat		# Load status register
	
	andi $13, $13, 0xFDF0	        # If IRQ5 is the only bit set
	beqz $13, sp2_handler	        # Branch to our sp2_handler
	
	lw $13, old_handler($0)	#Else load the old handler's address
	jr $13				# And jump to that address

# The Serial Port 2 Exception Handler
sp2_handler:
	# Read from SP2, write to SP1
	lw $13, 0x70003($0)		# Is SP1 ready to transmit?
	andi $13, $13, 2
	beqz $13, sp2_handler
	
	lw $13, 0x71001($0)		# Load receive register in SP2 without first checking if it's ready (Naughty!) 
	sw $13, 0x70000($0)		# Transmit the value through SP1
	
	# Acknowledge the interrupt
	sw $0, 0x71004($0)		# Finished handling it!
	
	# Return from exception
	rfe				# Get back to what you were doing

.bss					# Ininitialised data segment
old_handler:				# A label to refer to the old handler's address
	.word					#Reserve one word to store the old handler's address
