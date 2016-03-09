.bss
      .space 1000 
stack: 

.text
.global main
main: 
      addi  $9, $0, 'X'
      
      jal reading
      
      j handler
      j main
      
reading :   
      lw    $1, 0x73000 ($0)
      
      sw    $1, 0x73003 ($0) 
      srli  $1, $1, 4
      sw    $1, 0x73002 ($0)
      jr    $ra
      
      
check : 
      # Get the first serial port status 
      lw    $11, 0x70003 ($0)
      
      andi  $11, $11, 0x2
      
      beqz  $11, check  
      
      sw    $9, 0x70000 ($0)                
      
handler : 
      movsg       $13, $estat
      
      andi        $13, $13, 0xfef0
      
      bnez        $13, handle_interrupt
      
      lw    $13, old_vector ($0)
      jr    $13
      
handle_interrupt : 
      movsg       $4, $evec
      
      sw    $4, old_vector ($0)
      
      la    $4, handler
      
      movgs       $evec, $4
      
old_vector: 
      .word 0            
