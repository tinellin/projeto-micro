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

.global LED
LED:
    # ------------------------- Prologo ------------------------- #
    addi sp, sp, -40 # make a 36-byte frame
    stw ra, 36(sp)
    stw fp, 32(sp)
    # -------- Registradores de próposito geral (caller) -------- # 
    stw r8, 28(sp)
    stw r9, 24(sp)
    stw r10, 20(sp)
    stw r11, 16(sp)
    stw r12, 12(sp)
    stw r13, 8(sp)
    stw r14, 4(sp)
    stw r15, 0(sp)
    # ----------------------------------------------------------- # 
    addi fp, sp, 32

    movia r8, LEDS_VERMELHOS
    movia r9, BUFFER
    movia r10, COPIA_END_LED

    /* Carregar bits LED atuais */
    ldw r11, 0(r10)
    stwio r11, 0(r8)

    addi r9, r9, 1  # avanca buffer p/ pos 1
    ldb r10, 0(r9)  # r10: armazena bit de pisca ou cancela LED

    mov r11, r0
    mov r12, r0

    addi r9, r9, 1 # avanca buffer p/ pos 2
    ldb r11, 0(r9) # r11: primeiro caractere xx-esimo LED
    addi r11, r11, -0x30
    beq r11, r0, NAO_SOMA
    movi r15, 0x9 # se o primeiro caractere for diferente de 0, somar 9
    add r11, r11, r15

	NAO_SOMA:
        addi r9, r9, 1 # avanca buffer p/ pos 3
        ldb r12, 0(r9) # r12: segundo caractere xx-esimo LED
        addi r12, r12, -0x30
        
        add r11, r12, r11 # soma os 2 caracteres

        movi r15, 0x30
        bne r10, r15, CANCELA_LED

        movi r14, 0x0

        movi r15, 0x1
        sll r15, r15, r11 # shift de r15 a esquerda r11 vezes
        ldwio r14, 0(r8) # obter bits de LEDS_VERMELHOS
        or r15, r14, r15 # nao apagar os leds que ja estavam acesos, e adicionar um novo led aceso
        stwio r15, 0(r8)

        br EPILOGO

	CANCELA_LED:
		movia r15, MASK_1
		rol r15, r15, r11
		ldwio r14, 0(r8) # obter bits de LEDS_VERMELHOS
		and r15, r15, r14 # apagar bit desejado, e manter os outros bits acesos 
		stwio r15, 0(r8)

# ------------------------- Epilogo ------------------------- #
EPILOGO:
	/* Copiar endereco do LED para a memoria */
	movia r9, COPIA_END_LED
	ldwio r10, 0(r8)
	stw r10, 0(r9)
    
	ldw ra, 36(sp)
	ldw fp, 32(sp)
	ldw r8, 28(sp)
	ldw r9, 24(sp)
	ldw r10, 20(sp)
	ldw r11, 16(sp)
	ldw r12, 12(sp)
	ldw r13, 8(sp)
	ldw r14, 4(sp)
	ldw r15, 0(sp)
	addi sp, sp, 40

	ret
# ----------------------------------------------------------- #

.global NUM_TRIANGULAR
NUM_TRIANGULAR:
  # ------------------------- Prologo ------------------------- #
  addi sp, sp, -40
  stw ra, 36(sp)
  stw fp, 32(sp)
  # -------- Registradores de próposito geral (caller) -------- # 
  stw r8, 28(sp)
  stw r9, 24(sp)
  stw r10, 20(sp)
  stw r11, 16(sp)
  stw r12, 12(sp)
  stw r13, 8(sp)
  stw r14, 4(sp)
  stw r15, 0(sp)
  # ----------------------------------------------------------- # 
  addi fp, sp, 32

  movia r8, SWITCH_ADDRESS
  movia r13, DISPLAY_7SEG_ADDRESS
  mov r10, r0 # resultado

  /* Calcular numero triangular */

  ldwio r9, 0(r8) # obter conteudo do switch

  # beq r9, r0, EPILOGO # se switch = 0, nao calcular num. triangular

  movi r11, 0x1 # contador p/ n*(r10)
  addi r10, r9, 0x1 # r10 = (n+1)
  mov r12, r10 # r12 = r10

  LOOP_NUM: /* mudar nome dps */
    add r10, r12, r10 # n*(r10)
    addi r11, r11, 0x1 # contador++
    bne r11, r9, LOOP_NUM
  
  srli r10, r10, 1 # n*(r10) / 2

  /* Mostrar no display 7 segmentos */
  movia r8, DISPLAY_7SEG_MAP
  # movi r9, 6 # qtd maxima de display 7seg usados pelo switch, maior numero representavel 262.143
  # movi r11, 0 # i = 0
  LOOP_7SEG_DISPLAY:
  # verificação

  slli r10, r10, 2 # obtem indice da tabela (indice = r11 * 2)
  add r11, r8, r10 # obtem endereco da tabela (r13 = BASE_ADDRESS + indice)
  ldw r11, 0(r11)
  stwio r11, 0(r13) # carrega num. triangular no display 7seg                          
  ret

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
VALOR           CODIGO 7 SEG
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
*/
DISPLAY_7SEG_MAP:
.word 0x3f, 0x6, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x7, 0xff, 0x67

TEXT_STRING:
.asciz "\nEntre com o comando: "

.end