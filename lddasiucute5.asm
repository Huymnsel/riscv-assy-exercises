.data
buffer: .space 256
token: .space 64

# Messages
msg_input: .string "\nEnter instruction: "
msg_valid_op: .string "\nOpcode: "
msg_valid_ok: .string ", valid.\n"
msg_err_op: .string "\nError: Invalid or unsupported opcode."
msg_err_op1: .string "Error: Invalid Operand 1."
msg_err_op2: .string "Error: Invalid Operand 2."
msg_err_op3: .string "Error: Invalid Operand 3."
msg_success: .string "Syntax is valid."
msg_continue: .string "\n\nContinue? (1=Yes, 0=No): "
msg_exit: .string "\Program ended\n"
newline: .string "\n"

# Database
# ins reg, 12bit-imm(reg) ===============================================
op_lw: .string "lw"
op_sw: .string "sw"
op_lb: .string "lb"
op_sb: .string "sb"
# END ins reg, 12bit-imm(reg) ===========================================

# ins reg, 20bit-imm ====================================================
op_lui: .string "lui"
op_auipc: .string "auipc"
# END ins reg, 20bit-imm ================================================

# ins reg, reg, 12bit-imm ===============================================
op_addi: .string "addi"
op_andi: .string "andi"
op_jalr: .string "jalr"
op_ori: .string "ori"
op_slti: .string "slti"
op_sltiu: .string "sltiu"
op_xori: .string "xori"
# END ins reg, reg, 12bit-imm ===========================================

# ins reg, reg, 5bit-imm ================================================
op_slli: .string "slli"
op_srli: .string "srli"
op_srai: .string "srai"
# END ins reg, reg, 5bit-imm ============================================

# R-Types
op_add: .string "add"
op_sub: .string "sub"
op_sll: .string "sll"
op_or: .string "or"
op_and: .string "and"

# B-Types
op_beq: .string "beq"
op_bne: .string "bne"
op_blt: .string "blt"
op_bge: .string "bge"

op_jal: .string "jal"

# Opcode Map: 
opcode_map:
.word op_lw, 1
.word op_lb, 1
.word op_sw, 10
.word op_sb, 10
.word op_lui, 2
.word op_auipc, 2
.word op_addi, 3
.word op_slli, 3
.word op_srli, 3
.word op_srai, 3
.word op_andi, 3
.word op_ori, 3
.word op_xori, 3
.word op_slti, 3
.word op_jalr, 3
.word op_add, 4
.word op_sub, 4
.word op_sll, 4
.word op_or, 4
.word op_and, 4
.word op_beq, 5
.word op_bne, 5
.word op_blt, 5
.word op_bge, 5
.word op_jal, 6
.word 0, 0

# Valid RISC-V Registers
regs: .string "zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2", "t3", "t4", "t5", "t6", "s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10", "s11", "a0", "a1", "a2", "a3", "a4", "a5", "a6", "a7", ""

.eqv KEYBOARD_CTRL 0xFFFF0000
.eqv KEYBOARD_DATA 0xFFFF0004
.eqv DISPLAY_CTRL  0xFFFF0008
.eqv DISPLAY_DATA  0xFFFF000C

.text
main:
program_loop:
    # Print prompt to display
    la s0, msg_input
print_prompt_loop:
    lb t2, 0(s0)
    beqz t2, init_buffer
    
wait_display_prompt:
    li t0, DISPLAY_CTRL
    lw t3, 0(t0)
    andi t3, t3, 0x1
    beqz t3, wait_display_prompt
    
    li t0, DISPLAY_DATA
    sw t2, 0(t0)
    
    addi s0, s0, 1
    j print_prompt_loop

init_buffer:
    # Initialize buffer pointer
    la s0, buffer

# Read input using MMIO Keyboard
input_loop:
    li t0, KEYBOARD_CTRL
    lw t1, 0(t0)
    andi t1, t1, 0x1        # Check ready bit
    beqz t1, input_loop     # Wait until ready

    li t0, KEYBOARD_DATA
    lw t2, 0(t0)            # Read character

    # Check for Enter key (newline)
    li t3, 10
    beq t2, t3, start_parse

    # Echo character to display
wait_display:
    li t0, DISPLAY_CTRL
    lw t3, 0(t0)
    andi t3, t3, 0x1        # Check ready bit
    beqz t3, wait_display

    li t0, DISPLAY_DATA
    sw t2, 0(t0)

    # Store character in buffer
    sb t2, 0(s0)
    addi s0, s0, 1
    j input_loop

start_parse:
    # Echo newline
    li t2, 10
wait_display_newline:
    li t0, DISPLAY_CTRL
    lw t3, 0(t0)
    andi t3, t3, 0x1
    beqz t3, wait_display_newline
    
    li t0, DISPLAY_DATA
    sw t2, 0(t0)

    # Null terminate buffer
    sb zero, 0(s0)
    la s1, buffer

    # Get and validate opcode
    jal get_next_token
    la a0, token
    jal find_opcode

    li t0, -1
    beq a0, t0, err_opcode
    mv s2, a0

    # Print validation message
    la a0, msg_valid_op
    jal print_string
    la a0, token
    jal print_string
    la a0, msg_valid_ok
    jal print_string

    # Check instruction type
    li t0, 1
    beq s2, t0, type_load
    li t0, 10
    beq s2, t0, type_store
    li t0, 2
    beq s2, t0, type_u
    li t0, 3
    beq s2, t0, type_i
    li t0, 4
    beq s2, t0, type_r
    li t0, 5
    beq s2, t0, type_b
    li t0, 6
    beq s2, t0, type_jal
    j done

# Instruction type handlers
type_load:
    jal check_reg_op1
    jal check_mem_offset_op2
    j success

type_store:
    jal check_reg_op1
    jal check_mem_offset_op2
    j success

type_u:
    jal check_reg_op1
    jal check_imm_op2
    j success

type_i:
    jal check_reg_op1
    jal check_reg_op2
    jal check_imm_op3
    j success

type_r:
    jal check_reg_op1
    jal check_reg_op2
    jal check_reg_op3
    j success

type_b:
    jal check_reg_op1
    jal check_reg_op2
    jal check_label_op3
    j success

type_jal:
    jal check_reg_op1
    jal check_label_op2
    j success

# Operand checkers
check_reg_op1:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal get_next_token
    la a0, token
    jal is_register
    beqz a0, e_op1
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

check_reg_op2:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal get_next_token
    la a0, token
    jal is_register
    beqz a0, e_op2
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

check_reg_op3:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal get_next_token
    la a0, token
    jal is_register
    beqz a0, e_op3
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

check_imm_op2:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal get_next_token
    la a0, token
    jal is_imm_val
    beqz a0, e_op2
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

check_imm_op3:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal get_next_token
    la a0, token
    jal is_imm_val
    beqz a0, e_op3
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

check_label_op2:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal get_next_token
    lb t0, token
    beqz t0, e_op2
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

check_label_op3:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal get_next_token
    lb t0, token
    beqz t0, e_op3
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

check_mem_offset_op2:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal get_next_token
    la a0, token
    jal is_imm_val
    beqz a0, e_op2
    jal get_next_token
    la a0, token
    jal is_register
    beqz a0, mem_base_err
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

# Print string to MMIO display
print_string:
    mv t5, a0
ps_loop:
    lb t2, 0(t5)
    beqz t2, ps_done
ps_wait:
    li t0, DISPLAY_CTRL
    lw t3, 0(t0)
    andi t3, t3, 0x1
    beqz t3, ps_wait
    
    li t0, DISPLAY_DATA
    sw t2, 0(t0)
    
    addi t5, t5, 1
    j ps_loop
ps_done:
    ret

# Tokenizer
get_next_token:
    la t0, token
    mv t1, s1
skip_space:
    lb t2, 0(t1)
    beqz t2, tok_end
    li t3, 32
    beq t2, t3, inc_skip
    li t3, 44
    beq t2, t3, inc_skip
    li t3, 40
    beq t2, t3, inc_skip
    li t3, 41
    beq t2, t3, inc_skip
    j copy_tok
inc_skip:
    addi t1, t1, 1
    j skip_space

copy_tok:
    lb t2, 0(t1)
    beqz t2, tok_done
    li t3, 32
    beq t2, t3, tok_done
    li t3, 44
    beq t2, t3, tok_done
    li t3, 10
    beq t2, t3, tok_done
    li t3, 40
    beq t2, t3, tok_done
    li t3, 41
    beq t2, t3, tok_done
    sb t2, 0(t0)
    addi t0, t0, 1
    addi t1, t1, 1
    j copy_tok
tok_done:
    sb zero, 0(t0)
    mv s1, t1
    ret
tok_end:
    sb zero, 0(t0)
    ret

# Find opcode
find_opcode:
    la t0, opcode_map
fo_loop:
    lw t1, 0(t0)
    beqz t1, fo_fail
    lw t2, 4(t0)
    mv t3, a0
    mv t4, t1
fo_cmp:
    lb t5, 0(t3)
    lb t6, 0(t4)
    bne t5, t6, fo_next
    beqz t5, fo_found
    addi t3, t3, 1
    addi t4, t4, 1
    j fo_cmp
fo_next:
    addi t0, t0, 8
    j fo_loop
fo_found:
    mv a0, t2
    ret
fo_fail:
    li a0, -1
    ret

# Check register
is_register:
    mv t0, a0
    la t1, regs
ir_scan:
    lb t2, 0(t1)
    beqz t2, ir_fail
    mv t3, t0
    mv t4, t1
ir_cmp:
    lb t5, 0(t3)
    lb t6, 0(t4)
    bne t5, t6, ir_next_word
    beqz t5, ir_match
    addi t3, t3, 1
    addi t4, t4, 1
    j ir_cmp
ir_next_word:
    addi t1, t1, 1
    lb t2, 0(t1)
    bnez t2, ir_next_word
    addi t1, t1, 1
    j ir_scan
ir_match:
    li a0, 1
    ret
ir_fail:
    li a0, 0
    ret

# Check immediate
is_imm_val:
    lb t0, 0(a0)
    beqz t0, iv_fail
    li t1, 45
    bne t0, t1, iv_digit
    addi a0, a0, 1
    lb t0, 0(a0)
iv_digit:
    li t1, 48
    blt t0, t1, iv_fail
    li t1, 57
    bgt t0, t1, iv_fail
    li a0, 1
    ret
iv_fail:
    li a0, 0
    ret

# Error handlers
err_opcode:
    la a0, msg_err_op
    jal print_string
    j ask_continue

e_op1:
    la a0, newline
    jal print_string
    la a0, msg_err_op1
    jal print_string
    j ask_continue

e_op2:
    la a0, newline
    jal print_string
    la a0, msg_err_op2
    jal print_string
    j ask_continue

mem_base_err:
    la a0, newline
    jal print_string
    la a0, msg_err_op2
    jal print_string
    j ask_continue

e_op3:
    la a0, newline
    jal print_string
    la a0, msg_err_op3
    jal print_string
    j ask_continue

success:
    la a0, newline
    jal print_string
    la a0, msg_success
    jal print_string
    j ask_continue

done:
ask_continue:
    # Ask if user wants to continue
    la a0, msg_continue
    jal print_string
    
    # Read user input (1 or 0)
wait_continue_input:
    li t0, KEYBOARD_CTRL
    lw t1, 0(t0)
    andi t1, t1, 0x1
    beqz t1, wait_continue_input
    
    li t0, KEYBOARD_DATA
    lw t2, 0(t0)
    
    # Echo the character
wait_echo_continue:
    li t0, DISPLAY_CTRL
    lw t3, 0(t0)
    andi t3, t3, 0x1
    beqz t3, wait_echo_continue
    
    li t0, DISPLAY_DATA
    sw t2, 0(t0)
    
    # Check if input is 1 (ascii)
    li t3, 49
    beq t2, t3, program_loop
    
    # Check if input is 0 (ascii)
    li t3, 48
    beq t2, t3, exit_program 
    
    # Invalid input, ask again
    j ask_continue

exit_program:
    la a0, msg_exit
    jal print_string
    li a7, 10
    ecall
