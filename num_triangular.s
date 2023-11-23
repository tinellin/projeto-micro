.equ SWITCH_ADDRESS, 0x10000040
.equ DISPLAY_7SEG_ADDRESS, 0x10000020

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
  
# ------------------------- Epilogo ------------------------- #
EPILOGO:
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