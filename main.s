.equ DATA_REGISTER, 0x10001000  
.equ CONTROL_REGISTER, 0x10001004
.equ STACK, 0x10000

.equ MASK_RVALID, 0x8000
.equ MASK_DATA, 0xFF
.equ MASK_WSPACE, 0xFFFF

.equ BASE_ADDRESS_TIMER, 0x10002000

.equ PUSH_BUTTON_MASK, 0x10000058
.equ PUSH_BUTTON_ADDRESS, 0x1000005C

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
    andi r12, et, 0b10 # verifica se ha interrupcao no IRQ1 (PUSH BUTTON)
    beq r12, r0, END_HANDLER # vai para o epilogo
    call EXT_IRQ1 # chama o IRQ1

OTHER_EXCEPTIONS:
/* Instruções que verificam outros tipos de exceções devem ser colocadas aqui */

END_HANDLER:
    /* Epilogo */
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
/* Rotina de servico de interrupcao para a interrupcao de hardware desejada */
/* Interrupcao do timer */
EXT_IRQ0:
    /* Tratando interrupcao de LED */

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

    /* Tratando interrupcao do cronometro */

    INTERRUP_CRONOMETRO:
    
    movia r8, FLAG_CRONOMETRO
    movi r14, 10000

    ldw r10, 0(r8) # r10 = FLAG_CRONOMETRO
    movi r14, 0

    beq r10, r14, CRONOMETRO_INATIVO # FLAG_CRONOMETRO = 0 => cronometro inativo

    movia r8, CONTAGEM_ATIVA
    ldw r11, 0(r8) # r11 = CONTAGEM_ATIVA
    beq r11, r0, CRONOMETRO_INATIVO # se contagem = 0 => cronometro pausado, logo nao chama cronometro
    call CRONOMETRO

    CRONOMETRO_INATIVO:
    addi r10, r10, 1
    movi r10, 0

    /* Desabilitar bit TO para limpar interrupcao */
    movia r8, BASE_ADDRESS_TIMER
    movi r9, 0b10
    stwio r9, 0(r8)

    /* */
    ldw ra, (sp)
    addi sp, sp, 4
    /* */

    ret /* Retorna da rotina de servico de interrupcao */

    APAGAR_LED:
        stwio r0, 0(r10)
        movi r9, 1
        stw r9, 0(r8)
        br INTERRUP_CRONOMETRO

EXT_IRQ1:
    /* Prologo */
    addi sp, sp, -4
    stw ra, 0(sp)
    /* */

    movia r8, PUSH_BUTTON_ADDRESS
    
    ldwio r9, 0(r8)
    movi r10, 0b10
    beq r10, r9, PAUSAR_CONTAGEM
    br SAIR_INTERRUPCAO

    PAUSAR_CONTAGEM:
    movia r11, CONTAGEM_ATIVA
    ldw r12, 0(r11)
    beq r12, r0, RESUMIR_CONTAGEM
    stw r0, 0(r11)
    br SAIR_INTERRUPCAO

    RESUMIR_CONTAGEM:
    movi r13, 1
    stw r13, 0(r11)

    SAIR_INTERRUPCAO:
    /* Sair da interrupcao */
    stwio r0, 0(r8)

    /* Epilogo */ 
    ldw ra, (sp)
    addi sp, sp, 4
    /* */

    ret

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
    movia r13, PUSH_BUTTON_MASK

    /* Ativar interrupcao no Push Button */
    movi r11, 0b0010 # ativando KEY1
    stwio r11, 0(r13)

    # ativar Timer (IRQ0) e Push Button (IRQ1) no ienable
    movi r15, 0b11
    wrctl ienable, r15

    # ativar bit pie - flag do processador que indica que existe uma interrupcao
    wrctl status, r15

    /* Habilitar interrupcoes do timer (intervalos de 500ms) */
    
    # estabelecer periodo de contagem (baixa e alta)
    movia r10, 50000000
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
    movia r11, FLAG_CRONOMETRO
    ldw r12, 0(r11)
    beq r12, r0, CALL # Se cronometro ativo, desativa-lo
    stw r0, 0(r11)

    movia r11, DISPLAY_CRONOMETRO_CONTROL

    /* Limpar contadores do cronometro, caso esteja ativo */
    stb r0, 0(r11)
    stb r0, 4(r11)
    stb r0, 8(r11)
    stb r0, 12(r11)

    CALL:
    call NUM_TRIANGULAR
    br RETORNA
SE_2:
    addi r7, r7, 1
    ldb r10, 0(r7)

    beq r10, r0, CANCELA_CRONOMETRO

    /* Inicia cronometro */
    movia r11, FLAG_CRONOMETRO
    movi r7, 1
    stw r7, 0(r11) # FLAG_CRONOMETRO = 1
    movia r11, CONTAGEM_ATIVA
    stw r7, 0(r11) # CONTAGEM_ATIVA = 1

    br RETORNA

    CANCELA_CRONOMETRO:
        stw r0, 0(r11) # FLAG_CRONOMETRO = 0

RETORNA:
    movia r6, TEXT_STRING
    movia r7, BUFFER # Limpar buffer
    br LOOP

.org 0x500

FLAG_LED:
.word 0

.global COPIA_END_LED
COPIA_END_LED:
.word 0

.global BUFFER
BUFFER:
.skip 20

/*
    Controla os 4 displays 7seg para apresentar a contagem em:
    4        3         2        1
    milhar | centena | dezena | unidade
*/
.global DISPLAY_CRONOMETRO_CONTROL
DISPLAY_CRONOMETRO_CONTROL:
.word 0, 0, 0, 0

FLAG_CRONOMETRO:
.word 0

/* 
    1 - A contagem esta resumida
    0 - A contagem esta pausada
 */
CONTAGEM_ATIVA:
.word 0

/*
VALOR         CODIGO 7 SEG
0             0111111 => 0x3f
1             0000110 => 0x6
2             1011011 => 0x5b
3             1001111 => 0x4f
4             1100110 => 0x66
5             1101101 => 0x6d
6             1111101 => 0x7d
7             0000111 => 0x7
8             1111111 => 0xff
9             1100111 => 0x67
A             1110111 => 0x77
B             1111100 => 0x1f
C             0111001 => 0x39
D             1011110 => 0x5e
E             1111001 => 0x79
F             1110001 => 0x71
*/
DISPLAY_7SEG_MAP:
.byte 0x3f, 0x6, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x7, 0xff, 0x67, 0x77, 0x7c, 0x39, 0x5e, 0x79, 0x71

TEXT_STRING:
.asciz "\nEntre com o comando: "

.end