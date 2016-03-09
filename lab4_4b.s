

# Lab 4 question 4
# Read from switches and display to SSD as hex
# Using timer interrupt to interrupt every second
# Displaying the time (minute and second) since the program started

.data
CR:                                 # carriage return ascii value
    .word 0xd
COLON:                              # colon character
    .asciiz ":"
ZERO:                               # xero character
    .asciiz "0"
int_count:                          # interrupt counter
    .word 0
second:                             # seconds part
    .word 0
minute:                             # minute part
    .word 0
stack_cnt:                          # stack size counter
    .word 0
.bss
    .space 100
stack:

OLD_HANDLER:    
    .word 

.text
.global main

main:
    la      $sp,    stack           # point stack pointer to stack

init_timer:
    # Save old_handler
    movsg   $13,    $evec
    sw      $13,    OLD_HANDLER($0)

    # Store this handler's address
    la      $13,    handler                    
    movgs   $evec,  $13             
    
    # Set HW interrupts + IE
    movsg   $13,    $cctrl          # mov $cctrl to $13
    ori     $13,    $13,    0xff0   # enable all interrupts first then
    xori    $13,    $13,    0xff0   # disable all interrupts
    ori     $13,    $13,    0x42    # set only IRQ2 and IE bits
    movgs   $cctrl, $13             # mov $13 to $cctrl
    
    # Set timer interrupt settings
    sw      $0,     0x72003($0)     # acknowledge any old interrupts
    sw      $0,     0x72000($0)     # reset timer control
    addi    $13,    $0,     0x960   # timer interrupts every second
    sw      $13,    0x72001($0)     # store setting to load register
    addi    $13,    $0,     0x3     # set auto restart and timer enable
    sw      $13,    0x72000($0)     # store in control register
    
display:
    # Read switches and display value to SSD
    lw      $5,     0x73000($0)     # load parallel switch register to $5
    sw      $5,     0x73003($0)     # display to the right SSD  
    add     $6,     $5,     $0      # put a copy of $5 to $6
    srli    $6,     $6,     4       # shift to the right 4 times
    sw      $6,     0x73002($0)     # display to the left SSD
    j       display                 # loop indefinitely
 
handler:
    # Check if IRQ2 is interrupting and handle if it is
    movsg   $13,    $estat          # get value of exception status register
    andi    $13,    $13,    0xffb0  # is only IRQ2 interrupting?
    beqz    $13,    interrupt_func  # zero if only IRQ2 is interrupting
    lw      $13,    OLD_HANDLER($0) # not IRQ2, so load old handler
    jr      $13                     # go to $13, the old handler

interrupt_func:
    # increment interrupt counter
    lw      $13,    int_count($0)       
    addi    $13,    $13,    1           
    sw      $13,    int_count($0)    
   
    # Break down int_count into minutes and seconds
    lw      $13,    int_count($0)   # make a copy of the count
    divi    $13,    $13,    60
    sw      $13,    minute($0)      # quotient goes to minutes
    
    lw      $13,    int_count($0)
    remi    $13,    $13,    60
    sw      $13,    second($0)      # remainder goes to seconds

convert_second:    
    # Convert the seconds part to ascii value
    lw      $13,    second($0)      # load counter value          
    remi    $13,    $13,    10      # get remainder
    addi    $13,    $13,    48      # add 48 to convert to ascii
    subui   $sp,    $sp,    1       # make space in stack 
    sw      $13,    0($sp)          # store in stack

    # Increment stack counter
    lw      $13,    stack_cnt($0)   # get stack counter
    addi    $13,    $13,    1       # increment stack counter
    sw      $13,    stack_cnt($0)

    # Get quotient and store as new second value
    lw      $13,    second($0)      # load again counter value
    divi    $13,    $13,    10      # get quotient 
    sw      $13,    second($0)      # store quotient
    seqi    $13,    $13,    0       # if quotient is zero, end of conversion
    beqz    $13,    convert_second

    # Check if stack counter is 1 (single digit seconds) then pad zero
    lw      $13,    stack_cnt($0)
    seqi    $13,    $13,    1
    beqz    $13,    add_colon       # stack already has 2 items
    subui   $sp,    $sp,    1
    lw      $13,    ZERO($0)
    sw      $13,    0($sp)          # add 0 to stack as padding

    # Increment stack counter
    lw      $13,    stack_cnt($0)
    addi    $13,    $13,    1
    sw      $13,    stack_cnt($0)

add_colon:
    # Add colon character to the stack
    subui   $sp,    $sp,    1
    lw      $13,    COLON($0)
    sw      $13,    0($sp)

    # Increment stack counter
    lw      $13,    stack_cnt($0)
    addi    $13,    $13,    1
    sw      $13,    stack_cnt($0)

convert_minute:    
    # Convert the minutes part to ascii value
    lw      $13,    minute($0)      # load counter value          
    remi    $13,    $13,    10      # get remainder
    addi    $13,    $13,    48      # add 48 to convert to ascii
    subui   $sp,    $sp,    1       # make space in stack 
    sw      $13,    0($sp)          # store in stack

    # Increment stack counter
    lw      $13,    stack_cnt($0)   # get stack counter
    addi    $13,    $13,    1       # increment stack counter
    sw      $13,    stack_cnt($0)

    # Get quotient and store as new minute value
    lw      $13,    minute($0)      # load again counter value
    divi    $13,    $13,    10      # get quotient 
    sw      $13,    minute($0)      # store quotient
    seqi    $13,    $13,    0       # if quotient is zero, end of conversion
    beqz    $13,    convert_minute

    # Check if stack counter is 4 (single digit minutes) then pad zero
    lw      $13,    stack_cnt($0)
    seqi    $13,    $13,    4
    beqz    $13,    add_cr          # stack already has 5 items
    subui   $sp,    $sp,    1
    lw      $13,    ZERO($0)
    sw      $13,    0($sp)          # add 0 to stack as padding

    # Increment stack counter
    lw      $13,    stack_cnt($0)
    addi    $13,    $13,    1
    sw      $13,    stack_cnt($0)

add_cr:
    # Add carriage return character to the stack
    subui   $sp,    $sp,    1
    lw      $13,    CR($0)
    sw      $13,    0($sp)

    # Increment stack counter
    lw      $13,    stack_cnt($0)
    addi    $13,    $13,    1
    sw      $13,    stack_cnt($0)
    
transmit:
    # Transmit the converted value to serial port 1
 
check_serial1:
    lw      $13,    0x70003($0)     # load to $13 the serial port 1 status
    andi    $13,    $13,    0x2     # check if TDS bit is set
    beqz    $13,    check_serial1   # if not set, then check again
    
    lw      $13,    0($sp)          # load top stack value
    sw      $13,    0x70000($0)     # transmit    
    addui   $sp,    $sp,    1       # reset stack
    
    lw      $13,    stack_cnt($0)   # load stack counter
    subi    $13,    $13,    1       # decrement
    sw      $13,    stack_cnt($0)   # store 
    seqi    $13,    $13,    0       # check if there's still item on stack
    beqz    $13,    transmit
    
    sw      $0,     0x72003($0)     # acknowledge interrupt
    rfe                            # return from exception 
  

