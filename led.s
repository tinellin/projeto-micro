.equ LEDS_VERMELHOS, 0x10000000

.equ TEMP_BASE_ADDRESS, 0x10002000
.equ TEMP_CONTROL_STATUS, 0x4
.equ COUNTER_LOW_START, 0x8
.equ COUNTER_HIGH_START, 0xC
.equ TEMP_BASE_ADDRESS, 0x10002000
.equ TEMP_CONTROL_STATUS, 0x4
.equ COUNTER_LOW_START, 0x8
.equ COUNTER_HIGH_START, 0xC

.org 0x20
/* Exception handler */
rdctl et, ipending
beq et, r0, OTHER_EXCEPTIONS
subi ea, ea, 4

andi r13, et, 1
beq r13, r0, OTHER_INTERRUPTS
call EXT_IRQ0

OTHER_INTERRUPTS:
/* Instructions that check for other hardware interrupts should be placed here */
    br END_HANDLER

OTHER_EXCEPTIONS:
/* Instructions that check for other types of exceptions should be placed here */

END_HANDLER:
    eret
    .org 0x100
/* Interrupt-service routine for the desired hardware interrupt */
EXT_IRQ0:
    /* Instructions that handle the irql interrupt request should be placed here */

    # Boa prática para indicar que não há compartilhamento de registradores
    movia r7, DATA

    # Le o conteudo de r7 e da salva no proprio r7
    ldw  r7, (r7)

    # Reutilizando r4 no pti, pq é só mudado no _start uma vez
    stwio r7, 0(r4)

    # Inserindo 0 em TO para indicar que acabou a interrupção
    movia r11, TEMP_BASE_ADDRESS
    stwio r0, (r11)

    ret /* Return from the interrupt-service routine */

.global PISCA_LED
PISCA_LED:
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
    # ----------------------------------------------------------- #

	# PIE - FLAG DO PROCESSADOR PRA FALAR QUE EXISTE UMA INTERRUPCAO
    movi r7, 1
    wrctl status, r7
    
    movi r8, 0x1
	wrctl ienable, r8

    # ATIVAR O BOTAO KEY1 (BOTAO QUE ESTÁ SENDO USADO)
    movia r7, TEMP_CONTROL_STATUS
    stwio r8, 8(r7)

    movia r8, LEDS_VERMELHOS
    movia r9, BUFFER
	movia r12, TEMP_BASE_ADDRESS

    mov r10, r0
    mov r11, r0
	movia r13, 25000000

    addi r9, r9, 2 # avanca buffer p/ pos 2
    ldb r10, 0(r9) # r10 = primeiro caractere do xx-esimo LED
	addi r10, r10, -0x30
	beq r10, r0, NAO_SOMA
    movi r15, 0x9 # se o primeiro caractere for diferente de 0, somar 9
    add r10, r10, r15

	NAO_SOMA:
		addi r9, r9, 1 # avanca buffer p/ pos 3
		ldb r11, 0(r9) # r11 = segundo caractere do xx-esimo LED
		addi r11, r11, -0x30
		
		add r10, r10, r11 # soma os 2 caracteres

		movi r15, 1
		movi r14, '0'

		sll r15, r15, r10 # dar um shift a esquerda r11 vezes
		ldwio r14, 0(r8) # obter bits de LEDS_VERMELHOS
		or r15, r14, r15
		stwio r15, 0(r8)

		andi r10, r12, 0xFFFF
		srli r11, r12, 16

		stwio r10, COUNTER_LOW_START(r12)
		stwio r11, COUNTER_HIGH_START(r12)

		movi r10, 0x7
		stwio r10, TEMP_CONTROL_STATUS(r12)

		br JA_ACENDEU

    # ------------------------- Epilogo ------------------------- #
    JA_ACENDEU:
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
    # ----------------------------------------------------------- #

.global CANCELA_LED
CANCELA_LED:
    # movi r15, 0x3

DATA:
	.word 1