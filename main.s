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
    movia r13, 0xA # ascii enter

LOOP:
    ldb r11, 0(r6)
    beq r11, zero, POLLING_LEITURA /* a string é terminada em nulo */

    # Escrever "Entre com o comando: " no terminal
    POLLING_ESCRITA:
        ldwio r7, 0(r5)
        andhi r10, r7, MASK_WSPACE
        beq r10, r0, POLLING_ESCRITA
        stwio r11, 0(r4)
        addi r6, r6, 1

    br LOOP

POLLING_LEITURA:
    # Verifica se algum caractere foi enviado
    ldwio r7, 0(r4)
    andi r8, r7, MASK_RVALID
    andi r9, r7, MASK_DATA
    beq r8, r0, POLLING_LEITURA # loop enquanto não há caractere 

    stb r9, 0(r12) # Armazena no buffer o caracter
    addi r12, r12, 1 # Avança no buffer[++i]

# Escrever o input do teclado no terminal
POLLING_TECLADO:
    ldwio r7, 0(r5)
    andhi r10, r7, MASK_WSPACE
    beq r10, r0, POLLING_TECLADO
    stwio r9, 0(r4)
    beq r9, r13, INTERPRETADOR_DE_COMANDOS # Verifica se enter: fim do buffer
    br POLLING_LEITURA

# Interpretador não faz validação do que foi digitado (não trata casos diferentes)
INTERPRETADOR_DE_COMANDOS:
    movia r12, BUFFER # Armazena o valor buffer[0] em r12
    ldb r14, 0(r12)
    
    # Switch/case
    movi r6, 0x30
    beq r14, r6, SE_0
    movi r6, 0x31
    beq r14, r6, SE_1
    movi r6, 0x32
    beq r14, r10, SE_2
    
SE_0:
    addi r12, r12, 1
    ldb r14, 0(r12)

    beq r14, r0, SE_00
    call CANCELA_LED
    br RETORNA

    SE_00:
        call PISCA_LED

    br RETORNA
SE_1:
    call NUM_TRIANGULAR
    br RETORNA
SE_2:
    addi r12, r12, 1
    ldb r14, 0(r12)

    beq r14, r0, SE_20
    call CANCELA_CRONOMETRO
    br RETORNA

    SE_20:
        call INICIA_CRONOMETRO

RETORNA:
    movia r12, BUFFER # Limpar buffer
    br POLLING_LEITURA

TEXT_STRING:
.asciz "\nEntre com o comando: "

BUFFER:
.skip 20

.end