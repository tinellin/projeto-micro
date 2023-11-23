.equ MASK_1, 0xFFFFFFFE
.equ LEDS_VERMELHOS, 0x10000000

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

.global COPIA_END_LED
COPIA_END_LED:
.word 0