.data
buffer:         .space 256
pilha:          .space 400
erro_subfluxo:  .asciiz "Erro: Pilha underflow\n"
erro_token:     .asciiz "Erro: Token invalido\n"
erro_operandos: .asciiz "Erro: Muitos operandos\n"
erro_div_zero:  .asciiz "Erro: Divisao por zero\n"

.text
.globl main

main:
#     
##### Incialização da pilha e leitura da entrada do usuário
    la $s0, pilha             # Inicializa ponteiro da pilha
    li $v0, 8
    la $a0, buffer
    li $a1, 256
    syscall                   # Le entrada do usuario
# Remove \n do buffer digitado pelo usuário
    la $t0, buffer
strip_newline:
    lb $t1, ($t0)
    beq $t1, '\n', replace_null
    beqz $t1, process_input
    addiu $t0, $t0, 1
    j strip_newline
replace_null:
    sb $zero, ($t0)
process_input:
    la $t0, buffer            # Reinicializa ponteiro do buffer

#
##### Processamento e execução das operações
# Separa os tokens e prepara para a operção aritmética
processar_entrada: 
    lb $t1, ($t0)
    beqz $t1, final_processamento
    beq $t1, ' ', proximo_char
    move $t2, $t0
encontrar_fim_token:
    addiu $t0, $t0, 1
    lb $t1, ($t0)
    beqz $t1, token_encontrado
    bne $t1, ' ', encontrar_fim_token
token_encontrado:
    move $t3, $t0
    subu $t4, $t0, $t2
    li $t5, 1
    bne $t4, $t5, nao_operador
    lb $t5, ($t2)
    beq $t5, '+', operador
    beq $t5, '-', operador
    beq $t5, '*', operador
    beq $t5, '/', operador
nao_operador:
    jal tratar_numero
    j proximo_token
operador:
    jal tratar_operador
proximo_token:
    move $t0, $t3
proximo_char:
    addiu $t0, $t0, 1
    j processar_entrada

#
##### Execução das operações e tratamento do resultado
final_processamento:
    la $t5, pilha
    subu $t6, $s0, $t5
    bne $t6, 4, erro_muitos_operandos
    lw $a0, ($t5)
    li $v0, 1
    syscall                   # Imprime resultado
    j sair
# Retira os valores numéricos da pilha e realiza a operação do mesmo
tratar_operador:
    la $t5, pilha
    subu $t6, $s0, $t5
    blt $t6, 8, erro_subfluxo_pilha
    addiu $s0, $s0, -4
    lw $t7, ($s0)            # Pop operando direito
    addiu $s0, $s0, -4
    lw $t8, ($s0)            # Pop operando esquerdo
    lb $t9, ($t2)
    # Funções para as operações
    beq $t9, '+', fazer_soma
    beq $t9, '-', fazer_subtracao
    beq $t9, '*', fazer_multiplicacao
    beq $t9, '/', fazer_divisao
fazer_soma:
    addu $t0, $t8, $t7
    j empilhar_resultado
fazer_subtracao:
    subu $t0, $t8, $t7
    j empilhar_resultado
fazer_multiplicacao:
    mult $t8, $t7
    mflo $t0
    j empilhar_resultado
fazer_divisao:
    beqz $t7, erro_divisao_zero
    div $t8, $t7
    mflo $t0
# Após a operação, empilha o resultado
empilhar_resultado:
    sw $t0, ($s0)
    addiu $s0, $s0, 4
    jr $ra
tratar_numero:
    li $v1, 0                 # Inicializa n�mero
    li $t5, 0                 # Offset
    li $t6, 1                 # Sinal positivo
    lb $t7, ($t2)
    bne $t7, '-', converter_digitos
    li $t6, -1                # Sinal negativo
    addiu $t5, $t5, 1
converter_digitos:
    addu $t8, $t2, $t5
    lb $t7, ($t8)
    blt $t7, '0', erro_token_invalido
    bgt $t7, '9', erro_token_invalido
    sub $t7, $t7, '0'
    mul $v1, $v1, 10
    addu $v1, $v1, $t7
    addiu $t5, $t5, 1
    blt $t5, $t4, converter_digitos
    mul $v1, $v1, $t6
    sw $v1, ($s0)
    addiu $s0, $s0, 4
    jr $ra
# Tratamento de erros
erro_subfluxo_pilha:
    la $a0, erro_subfluxo
    li $v0, 4
    syscall
    j sair
erro_token_invalido:
    la $a0, erro_token
    li $v0, 4
    syscall
    j sair
erro_muitos_operandos:
    la $a0, erro_operandos
    li $v0, 4
    syscall
    j sair
erro_divisao_zero:
    la $a0, erro_div_zero
    li $v0, 4
    syscall
sair:
    li $v0, 10
    syscall
