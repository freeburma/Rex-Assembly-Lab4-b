.text 
.global main

main : 
      addi $1, $0, '0'
      addi $3, $0, 3
      
      # This will loop until the TDS bits is enable 
tds:       
      # Getting the status of the Serial 1
      lw    $2, 0x71003 ($0)      
      
      # Check the Transmit Data Sent (TDS) bit is enable 
      andi  $2, $2, 0x2             # TDS bit is at the second place on the Serial Status Regitser - 0x2 = Oxb0010 in base 2
      
      beqz $2, tds

display :
          
      # Get the data 
      sw    $1, 0x70000 ($0)
      subi    $3, $3, 1  
      bnez $3, tds
      jr $ra
      
      
      
      
