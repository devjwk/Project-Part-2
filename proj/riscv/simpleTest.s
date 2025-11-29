############################################################
# Software-Scheduled Pipeline Test Program (Hazard-Free)
# RARS-Compatible + NOP-free (replaced with addi x0,x0,0)
############################################################

    .text
    .globl _start

############################################################
# Program Entry
############################################################
_start:
    # Initialize stack pointer
    la      t0, stack_top
    addi    sp, t0, 0


###############################
# U-Type Instructions
###############################
    lui     x5, 0x00010          # x5 = 0x00010000
    auipc   x6, 0                # x6 = PC + offset


###############################
# Register Initialization
###############################
    addi    x1, x0, 5            # x1 = 5
    addi    x2, x0, 3            # x2 = 3


###############################
# R-Type Instructions
###############################
    add     x7,  x1, x2          # x7 = 8
    sub     x8,  x1, x2          # x8 = 2
    and     x9,  x1, x2          # x9 = 1
    or      x10, x1, x2          # x10 = 7
    xor     x11, x1, x2          # x11 = 6
    slt     x12, x2, x1          # x12 = 1


###############################
# I-Type Instructions
###############################
    addi    x13, x1, 10          # x13 = 15
    andi    x14, x1, 1           # x14 = 1
    xori    x15, x1, 2           # x15 = 7
    ori     x16, x1, 8           # x16 = 13
    slti    x17, x2, 5           # x17 = 1


###############################
# Store / Load
###############################
    addi    x3, x0, 100          # base = 100
    addi    x4, x0, 42           # value = 42
    sw      x4, 0(x3)            # MEM[100] = 42

    addi    x0, x0, 0            # NOP replacement (load-use stall)
    lw      x18, 0(x3)           # x18 = 42


###############################
# Branch Test
###############################
    addi    x19, x0, 1
    addi    x20, x0, 1
    beq     x19, x20, BRANCH_OK  # taken

    addi    x0, x0, 0            # NOP replacement #1
    addi    x0, x0, 0            # NOP replacement #2

BRANCH_OK:
    addi    x21, x0, 99          # x21 = 99


###############################
# Jump Instructions
###############################
    jal     x22, TARGET
    addi    x0, x0, 0            # NOP replacement for jal hazard

RETURN_POINT:
    jalr    x23, 0(x22)

TARGET:
    addi    x24, x0, 55


############################################################
# exit (halt)
############################################################
exit:
    wfi                            # wait for interrupt → RARS halt
    j exit                         # safety loop


############################################################
# Data Section
############################################################
    .data
    .align 4

stack_mem:
    .space 512
stack_top:
