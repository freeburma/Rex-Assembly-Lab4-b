

.data 
     old_vector: 
           .word 0 
     TIMER_BASE : 
            .word 72003
            
.equ        CONTROL,    0
.equ        DELAY,      1
.equ        COUNT,      2
.equ        ACK,        3                         


.bss
      .space 1000 
stack: 

.text
.global main
main: 

      # Timer : 
      # Set the TImer HW wiht interrupts enable 
      lw    $1, TIMER_BASE ($0)     # calling Timer Control Reg
      sw    $0, 0x72003 ($0)        # Time rinterrupt ack reg
      addui $3, $0, 2400            # 1 sec
      addui $3, $0, 0x3             # enable bit on 
      sw    $3, 0x72000 ($0)
      
      movsg       $2, $evec
      sw    $2, old_vector ($0)
      la    $2, handler
      movgs       $evec, $2
      addi  $2, $0, 0x22            # 34
      movgs       $cctrl, $2
      
      
      
      addi  $9, $0, 'X'
      
      
      
reading :   
      lw    $1, 0x73000 ($0)        # Switches Reg
      
      sw    $1, 0x73003 ($0)        # Right SSD
      srli  $1, $1, 4
      sw    $1, 0x73002 ($0)        # Left SSD
      jr    $ra
      
      
         
      
handler : 
      sw          $0, 0x7f000 ($0)        # ack the interrupt if 
      movsg       $13, $estat
      
      seqi        $13, $13, 32
      
      bnez        $13, handle_interrupt
      
# L1: 
      lw    $3, 2 ($1)                    # read the current count
      
check : 
      # Get the first serial port status 
      lw    $11, 0x70003 ($0)
      
      andi  $11, $11, 0x2
      
      beqz  $11, check  
      
      sw    $9, 0x70000 ($0)   
      
      rfe      
      
handle_interrupt : 
      
      
      lw    $13, old_vector ($0)
      
     jr $13
      
           
