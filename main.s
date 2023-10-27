.equ DATA_REGISTER, 0x10001000  
.equ CONTROL_REGISTER, 0x10001004
.equ MASK_RVALID, 0x8000
.equ MASK_DATA, 0xFF
.equ MASK_WSPACE, 0xFFFF

.global _start

_start:
    movia r4, DATA_REGISTER
    movia r5, CONTROL_REGISTER
    movia r6, TEXT_STRING
    movia r12, BUFFER

LOOP:
    ldb r11, 0(r6)
    beq r11, zero, POOLING_LEITURA /* a string é terminada em nulo */

    POOLING_ESCRITA:
        ldwio r7, 0(r5)
        andhi r10, r7, MASK_WSPACE
        beq r10, r0, POOLING_ESCRITA
        stwio r11, 0(r4)
        addi r6, r6, 1

    br LOOP

POOLING_LEITURA:
    ldwio r7, 0(r4)
    andi r8, r7, MASK_RVALID
    andi r9, r7, MASK_DATA

    beq r8, r0, POOLING_LEITURA

    stb r9, 0(r12)
    addi r12, r12, 1

POOLING_TECLADO:
    ldwio r7, 0(r5)
    andhi r10, r7, MASK_WSPACE
    beq r10, r0, POOLING_TECLADO
    stwio r9, 0(r4)
    br POOLING_LEITURA

TEXT_STRING:
.asciz "\nEntre com o comando: "

BUFFER:
.skip 20

.end