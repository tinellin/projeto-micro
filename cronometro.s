.equ DISPLAY_7SEG_ADDRESS, 0x10000020

.global CRONOMETRO
CRONOMETRO:
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

    movia r8, DISPLAY_7SEG_ADDRESS
    movia r9, DISPLAY_CRONOMETRO_CONTROL
    movia r12, DISPLAY_7SEG_MAP
    movi r15, 9 # tamanho maximo para contagem

    ldw r10, 0(r9)
    bgt r10, r15, INCREMENTA_DEZENA # se unidade > 9, incrementa dezena e reseta unidade
    br DISPLAY_CRONOMETRO   

    INCREMENTA_DEZENA:
      ldw r10, 4(r9)
      stw r0, 0(r9) # unidade = 0
      addi r10, r10, 1 # dezena++
      /*
           M   C  D U
        Se x x++ 10 0
      */
      bgt r10, r15, INCREMENTA_CENTENA # se dezena > 9 incrementa centena e reseta dezena
      stw r10, 4(r9) # senao escreve no cronometro
      br DISPLAY_CRONOMETRO

    INCREMENTA_CENTENA:
    ldw r10, 8(r9)
    stw r0, 4(r9) # dezena = 0
    addi r10, r10, 1 # centena++
    /*
            M C  D U
      Se x++ x 10 0
    */
    bgt r10, r15, INCREMENTA_MILHAR # se centena > 9 incrementa centena e reseta
    stw r10, 8(r9) # senao escreve no cronometro
    br DISPLAY_CRONOMETRO

    INCREMENTA_MILHAR:
    ldw r10, 12(r9)
    stw r0, 8(r9) # centena = 0
    addi r10, r10, 1 # milhar++
    /*
            M C  D U
      Se x++ x 10 0
    */
    bgt r10, r15, RESET # se milhar > 9 incrementa centena e reseta
    stw r10, 12(r9) # senao escreve no cronometro
    br DISPLAY_CRONOMETRO

    RESET:
    stw r0, 0(r9)
    stw r0, 4(r9)
    stw r0, 8(r9)
    stw r0, 12(r9)

    DISPLAY_CRONOMETRO:
    movia r9, DISPLAY_CRONOMETRO_CONTROL
    movi r14, 0 
    movi r15, 4 # maximo uso 4 displays

    LOOP_CRONOMETRO_DISPLAY:
      bge r14, r15, FIM_LOOP_CRONOMETRO_DISPLAY

      ldw r10, 0(r9) # obter valor do controle
      add r13, r12, r10 # obter endereco mapeado na tabela

      ldb r13, 0(r13)
      stbio r13, 0(r8)

      addi r9, r9, 4 # incrementar valor de controle
      addi r8, r8, 1 # avancar no display
      addi r14, r14, 1 # incrementar loop

      br LOOP_CRONOMETRO_DISPLAY
    
    FIM_LOOP_CRONOMETRO_DISPLAY:
    
    /* Incrementar unidade */
    movia r9, DISPLAY_CRONOMETRO_CONTROL
    ldw r10, 0(r9)
    addi r10, r10, 1
    stw r10, 0(r9)

    # -------- Epilogo -------- #
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