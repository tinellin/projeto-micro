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

  /* Calcular numero triangular (maior num. triangular representavel 32.385 - 7E81)*/

  ldwio r9, 0(r8) # obter conteudo do switch
  beq r9, r0, FIM /* mudar para EPILOGO */

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
  
  # Limpar display 7 seg
  stbio r0, 0(r13)
  stbio r0, 1(r13)
  stbio r0, 2(r13)
  stbio r0, 3(r13)

  /* Apresentar valor em hexadecimal no display 7 seg */

  # primeiro grupo de 4 bits
  andi r9, r10, 0xF # pegar 0-3 bits
  add r11, r8, r9
  ldb r12, 0(r11)
  stbio r12, 0(r13)
  
  movi r9, 0xF
  blt r10, r9, FIM

  # segundo grupo de 4 bits
  andi r9, r10, 0xF0 # pegar 4 - 7 bits
  srli r9, r9, 4 # trazer os bits para o inicio da palavra
  add r11, r8, r9
  ldb r12, 0(r11)
  stbio r12, 1(r13) # escreve no display 7 seg
  
  movi r9, 0xFF
  blt r10, r9, FIM /* mudar para EPILOGO */

  # terceiro grupo de 4 bits
  andi r9, r10, 0xF00 # pegar 7 - 11
  srli r9, r9, 8 # trazer os bits para o inicio da palavra
  add r11, r8, r9
  ldb r12, 0(r11)
  stbio r12, 2(r13) # escreve no display 7 seg

  movi r9, 0xFFF
  blt r10, r9, FIM /* mudar para EPILOGO */

  # quarto grupo de 4 bits
  andi r9, r10, 0xF000 # pegar 12 - 15
  srli r9, r9, 12 # trazer os bits para o inicio da palavra
  add r11, r8, r9
  ldb r12, 0(r11)
  stbio r12, 3(r13) # escreve no display 7 seg
  
  FIM:
  /* EPILOGO */
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