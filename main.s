.equ MASK_1, 0xFFFFFFFE
.equ LEDS_VERMELHOS, 0x10000000
/* ---------------------------- */

.equ SWITCH_ADDRESS, 0x10000040
.equ DISPLAY_7SEG_ADDRESS, 0x10000020

/* ------------------------ */
.equ DATA_REGISTER, 0x10001000  
.equ CONTROL_REGISTER, 0x10001004
.equ STACK, 0x10000

.equ MASK_RVALID, 0x8000
.equ MASK_DATA, 0xFF
.equ MASK_WSPACE, 0xFFFF

.equ BASE_ADDRESS_TIMER, 0x10002000

.org 0x20
# ------------------------- Prologo ------------------------- #
addi sp, sp, -32
stw ra, 28(sp)
# -------- Registradores de próposito geral (caller) -------- # 
stw r8, 24(sp)
stw r9, 20(sp)
stw r10, 16(sp)
stw r11, 12(sp)
stw r12, 8(sp)
stw r13, 4(sp)
stw r14, 0(sp)
# ----------------------------------------------------------- # 

/* Manipulador de exceções */
rdctl et, ipending
beq et, r0, OTHER_EXCEPTIONS
subi ea, ea, 4

andi r13, et, 1    
beq r13, r0, OTHER_INTERRUPTS 
call EXT_IRQ0

OTHER_INTERRUPTS:
/* Instruções que verificam outras interrupções de hardware devem ser colocadas aqui */
    br END_HANDLER

OTHER_EXCEPTIONS:
/* Instruções que verificam outros tipos de exceções devem ser colocadas aqui */

END_HANDLER:
    ldw ra, 28(sp)
    ldw r8, 24(sp)
    ldw r9, 20(sp)
    ldw r10, 16(sp)
    ldw r11, 12(sp)
    ldw r12, 8(sp)
    ldw r13, 4(sp)
    ldw r14, 0(sp)
    addi sp, sp, 32
    eret

.org 0x100
/* Rotina de serviço de interrupção para a interrupção de hardware desejada */
EXT_IRQ0:
    /* */
    addi sp, sp, -4
    stw ra, 0(sp)
    /* */
    
    movia r8, FLAG_LED
    ldw r9, 0(r8)

    movia r10, COPIA_END_LED
    ldw r11, 0(r10)

    movia r10, LEDS_VERMELHOS

    beq r9, r0, APAGAR_LED
    stwio r11, 0(r10)
    stw r0, 0(r8)

    FIM_INTERRUPCAO:
    /* Desabilitar bit TO para limpar interrupcao */
    movia r8, BASE_ADDRESS_TIMER
    movi r9, 0b10
    stwio r9, 0(r8)

    /* */
    ldw ra, (sp)
    addi sp, sp, 4
    /* */

    ret /* Retorna da rotina de serviço de interrupção */

    APAGAR_LED:
        stwio r0, 0(r10)
        movi r9, 1
        stw r9, 0(r8)
        br FIM_INTERRUPCAO

.global _start

_start:
    movia sp, STACK # configura end. do stack pointer
    mov fp, sp # copia end. inicial do sp ao frame pointer
    movia r4, DATA_REGISTER
    movia r5, CONTROL_REGISTER
    movia r6, TEXT_STRING
    movia r7, BUFFER
    movia r8, 0xA # ascii enter
    movia r9, BASE_ADDRESS_TIMER

    # ativar Timer (IRQ0) e Push Button (IRQ1) no ienable
    movi r15, 0b11
    wrctl ienable, r15

    # ativar bit pie - flag do processador que indica que existe uma interrupcao
    wrctl status, r15

    /* Habilitar interrupcoes do timer (intervalos de 500ms) */
    
    # estabelecer periodo de contagem (baixa e alta)
    movia r10, 25000000
    andi r11, r10, 0xFFFF # parte baixa
    srli r12, r10, 16 # parte alta
    stwio r11, 8(r9) # periodo de contagem inicial
    stwio r12, 12(r9) # periodo de contagem final

    /*
    habilitar bits de controle do timer (control register)

    ITO = 1 - habilitar interrupcoes
    CONT = 1 - timer funcionar continuamente
    START = 1 - inicie a contagem
    STOP = 0
    */
    movi r10, 0b0111
    stwio r10, 4(r9)

LOOP:
    ldb r9, 0(r6)
    beq r9, zero, POLLING_LEITURA /* a string é terminada em nulo */

    # Escrever "Entre com o comando: " no terminal
    POLLING_ESCRITA:
        ldwio r10, 0(r5)
        andhi r11, r10, MASK_WSPACE
        beq r11, r0, POLLING_ESCRITA
        stwio r9, 0(r4)
        addi r6, r6, 1

    br LOOP

POLLING_LEITURA:
    # Verifica se algum caractere foi enviado
    ldwio r10, 0(r4)
    andi r13, r10, MASK_RVALID
    andi r14, r10, MASK_DATA
    beq r13, r0, POLLING_LEITURA # loop enquanto não há caractere 

    stb r14, 0(r7) # Armazena no buffer o caracter
    addi r7, r7, 1 # Avança no buffer[++i]

# Escrever o input do teclado no terminal
POLLING_TECLADO:
    ldwio r10, 0(r5)
    andhi r11, r10, MASK_WSPACE
    beq r11, r0, POLLING_TECLADO
    stwio r14, 0(r4)
    beq r14, r8, INTERPRETADOR_DE_COMANDOS # Verifica se enter: fim do buffer
    br POLLING_LEITURA

# Interpretador não faz validação do que foi digitado (não trata casos diferentes)
INTERPRETADOR_DE_COMANDOS:
    movia r7, BUFFER # Armazena o valor buffer[0] em r7
    ldb r10, 0(r7)
    
    # Switch/case
    movi r11, 0x30 # '0'
    beq r10, r11, SE_0
    movi r11, 0x31 # '1'
    beq r10, r11, SE_1
    movi r11, 0x32 # '2'
    beq r10, r11, SE_2
    
SE_0:
    call LED
    br RETORNA
SE_1:
    call NUM_TRIANGULAR
    br RETORNA
SE_2:
    addi r7, r7, 1
    ldb r10, 0(r7)

    movi r6, 0x30

    beq r10, r11, SE_20
    # call CANCELA_CRONOMETRO
    br RETORNA

    SE_20:
        # call INICIA_CRONOMETRO

RETORNA:
    movia r6, TEXT_STRING
    movia r7, BUFFER # Limpar buffer
    br LOOP

.org 0x500

.global BUFFER
BUFFER:
.skip 20

TEXT_STRING:
.asciz "\nEntre com o comando: "

.end