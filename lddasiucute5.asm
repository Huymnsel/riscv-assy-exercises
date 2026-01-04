.data
buffer: .space 256
token: .space 64

# Messages
msg_input:     .string "\nNhap lenh assembler: "
msg_valid_op:  .string "\nOpcode: "
msg_valid_ok:  .string ", hop le.\n"
msg_err_op:    .string "\nLoi: Opcode khong hop le hoac chua duoc ho tro.\n"
msg_err_op1:   .string "\nLoi: Toan hang thu nhat khong hop le.\n"
msg_err_op2:   .string "\nLoi: Toan hang thu hai khong hop le.\n"
msg_err_op3:   .string "\nLoi: Toan hang thu ba khong hop le.\n"
msg_err_range: .string "\nLoi: Hang so tuc thoi nam ngoai pham vi cho phep.\n"
msg_err_addr:  .string "\nLoi: Dinh dang dia chi khong hop le.\n"
msg_success:   .string "\nCu phap lenh hop le.\n"
msg_continue:  .string "\nTiep tuc chuong trinh? (1=Co, 0=Khong): "
msg_exit:      .string "\nChuong trinh ket thuc.\n"
newline:       .string "\n"
backspace_seq: .byte 8, 32, 8, 0

# Database 
op_lw: .string "lw"
op_lb: .string "lb"
op_lh: .string "lh"
op_lbu: .string "lbu"
op_lhu: .string "lhu"
op_sw: .string "sw"
op_sb: .string "sb"
op_sh: .string "sh"
op_lui: .string "lui"
op_auipc: .string "auipc"
op_addi: .string "addi"
op_slli: .string "slli"
op_srli: .string "srli"
op_srai: .string "srai"
op_andi: .string "andi"
op_ori: .string "ori"
op_xori: .string "xori"
op_slti: .string "slti"
op_sltiu: .string "sltiu"
op_jalr: .string "jalr"
op_add: .string "add"
op_sub: .string "sub"
op_sll: .string "sll"
op_slt: .string "slt"
op_sltu: .string "sltu"
op_xor: .string "xor"
op_srl: .string "srl"
op_sra: .string "sra"
op_or: .string "or"
op_and: .string "and"
op_beq: .string "beq"
op_bne: .string "bne"
op_blt: .string "blt"
op_bge: .string "bge"
op_bltu: .string "bltu"
op_bgeu: .string "bgeu"
op_jal: .string "jal"

# Opcode Map
opcode_map:
.word op_lw, 1
.word op_lb, 1
.word op_lh, 1
.word op_lbu, 1
.word op_lhu, 1
.word op_sw, 10
.word op_sb, 10
.word op_sh, 10
.word op_lui, 2
.word op_auipc, 2
.word op_addi, 3
.word op_slli, 7
.word op_srli, 7
.word op_srai, 7
.word op_andi, 3
.word op_ori, 3
.word op_xori, 3
.word op_slti, 3
.word op_sltiu, 3
.word op_jalr, 3
.word op_add, 4
.word op_sub, 4
.word op_sll, 4
.word op_slt, 4
.word op_sltu, 4
.word op_xor, 4
.word op_srl, 4
.word op_sra, 4
.word op_or, 4
.word op_and, 4
.word op_beq, 5
.word op_bne, 5
.word op_blt, 5
.word op_bge, 5
.word op_bltu, 5
.word op_bgeu, 5
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
    la s0, buffer
    mv s9, s0

input_loop:
    li t0, KEYBOARD_CTRL
    lw t1, 0(t0)
    andi t1, t1, 0x1
    beqz t1, input_loop
    li t0, KEYBOARD_DATA
    lw t2, 0(t0)
    li t3, 8
    beq t2, t3, handle_backspace
    li t3, 127
    beq t2, t3, handle_backspace
    li t3, 10
    beq t2, t3, start_parse
wait_display:
    li t0, DISPLAY_CTRL
    lw t3, 0(t0)
    andi t3, t3, 0x1
    beqz t3, wait_display
    li t0, DISPLAY_DATA
    sw t2, 0(t0)
    sb t2, 0(s0)
    addi s0, s0, 1
    j input_loop

handle_backspace:
    beq s0, s9, input_loop
    addi s0, s0, -1
    la t4, backspace_seq
backspace_display_loop:
    lb t2, 0(t4)
    beqz t2, input_loop
wait_display_bs:
    li t0, DISPLAY_CTRL
    lw t3, 0(t0)
    andi t3, t3, 0x1
    beqz t3, wait_display_bs
    li t0, DISPLAY_DATA
    sw t2, 0(t0)
    addi t4, t4, 1
    j backspace_display_loop

start_parse:
    li t2, 10
wait_display_newline:
    li t0, DISPLAY_CTRL
    lw t3, 0(t0)
    andi t3, t3, 0x1
    beqz t3, wait_display_newline
    li t0, DISPLAY_DATA
    sw t2, 0(t0)
    sb zero, 0(s0)
    la s1, buffer
    jal get_next_token
    la a0, token
    jal find_opcode
    li t0, -1
    beq a0, t0, err_opcode
    mv s2, a0
    la a0, msg_valid_op
    jal print_string
    la a0, token
    jal print_string
    la a0, msg_valid_ok
    jal print_string
    li t0, 1
    beq s2, t0, type_load
    li t0, 10
    beq s2, t0, type_store
    li t0, 2
    beq s2, t0, type_u
    li t0, 3
    beq s2, t0, type_i
    li t0, 7
    beq s2, t0, type_shift
    li t0, 4
    beq s2, t0, type_r
    li t0, 5
    beq s2, t0, type_b
    li t0, 6
    beq s2, t0, type_jal
    j done

type_load:
    jal check_reg_op1
    jal check_address_op2
    j success

type_store:
    jal check_reg_op1
    jal check_address_op2
    j success

type_u:
    jal check_reg_op1
    jal check_20bit_imm_op2
    j success

type_i:
    jal check_reg_op1
    jal check_reg_op2
    jal check_12bit_imm_op3
    j success

type_shift:
    jal check_reg_op1
    jal check_reg_op2
    jal check_5bit_imm_op3
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

# ============================================
# GET NEXT TOKEN - Extracts next token from buffer
# Input: s1 = current position in buffer
# Output: token buffer filled, s1 updated
# ============================================
get_next_token:
    la t0, token
    mv t1, s1
skip_whitespace:
    lb t2, 0(t1)
    beqz t2, token_end
    li t3, 32
    beq t2, t3, skip_ws_inc
    li t3, 9
    beq t2, t3, skip_ws_inc
    li t3, 44
    beq t2, t3, skip_ws_inc
    j start_extract
skip_ws_inc:
    addi t1, t1, 1
    j skip_whitespace

start_extract:
    lb t2, 0(t1)
    beqz t2, token_end
    li t3, 32
    beq t2, t3, token_end
    li t3, 9
    beq t2, t3, token_end
    li t3, 44
    beq t2, t3, token_end
    li t3, 10
    beq t2, t3, token_end
    sb t2, 0(t0)
    addi t0, t0, 1
    addi t1, t1, 1
    j start_extract

token_end:
    sb zero, 0(t0)
    mv s1, t1
    ret

# ============================================
# FIND OPCODE - Search for opcode in map
# Input: a0 = token address
# Output: a0 = type code (-1 if not found)
# ============================================
find_opcode:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw s0, 4(sp)
    mv s0, a0
    la t0, opcode_map
find_loop:
    lw t1, 0(t0)
    beqz t1, find_not_found
    mv t2, s0
    mv t3, t1
compare_loop:
    lb t4, 0(t2)
    lb t5, 0(t3)
    bne t4, t5, find_next
    beqz t4, find_match
    addi t2, t2, 1
    addi t3, t3, 1
    j compare_loop
find_next:
    addi t0, t0, 8
    j find_loop
find_match:
    lw a0, 4(t0)
    lw s0, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 8
    ret
find_not_found:
    li a0, -1
    lw s0, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 8
    ret

# ============================================
# PRINT STRING - Display string via MMIO
# Input: a0 = string address
# ============================================
print_string:
    mv t0, a0
print_loop:
    lb t1, 0(t0)
    beqz t1, print_done
wait_display_ps:
    li t2, DISPLAY_CTRL
    lw t3, 0(t2)
    andi t3, t3, 0x1
    beqz t3, wait_display_ps
    li t2, DISPLAY_DATA
    sw t1, 0(t2)
    addi t0, t0, 1
    j print_loop
print_done:
    ret

# ============================================
# CHECK FUNCTIONS
# ============================================

check_is_register:
    mv t0, a0
    lb t1, 0(t0)
    li t2, 'x'
    beq t1, t2, check_x_register
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

check_x_register:
    addi t0, t0, 1
    lb t1, 0(t0)
    li t2, '0'
    blt t1, t2, ir_fail
    li t2, '9'
    bgt t1, t2, ir_fail
    li t2, '0'
    sub t3, t1, t2
    addi t0, t0, 1
    lb t1, 0(t0)
    beqz t1, check_x_range_single
    li t2, '0'
    blt t1, t2, ir_fail
    li t2, '9'
    bgt t1, t2, ir_fail
    li t4, 10
    mul t3, t3, t4
    li t2, '0'
    sub t4, t1, t2
    add t3, t3, t4
    addi t0, t0, 1
    lb t1, 0(t0)
    bnez t1, ir_fail
    bltz t3, ir_fail
    li t4, 31
    bgt t3, t4, ir_fail
    li a0, 1
    ret

check_x_range_single:
    li a0, 1
    ret

check_is_5bit_imm:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal parse_immediate
    beqz a1, imm5_fail
    bltz a0, imm5_fail
    li t0, 31
    bgt a0, t0, imm5_fail
    lw ra, 0(sp)
    addi sp, sp, 4
    li a0, 1
    ret

imm5_fail:
    lw ra, 0(sp)
    addi sp, sp, 4
    li a0, 0
    ret

check_is_12bit_imm:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal parse_immediate
    beqz a1, imm12_fail
    li t0, -2048
    blt a0, t0, imm12_fail
    li t0, 2047
    bgt a0, t0, imm12_fail
    lw ra, 0(sp)
    addi sp, sp, 4
    li a0, 1
    ret

imm12_fail:
    lw ra, 0(sp)
    addi sp, sp, 4
    li a0, 0
    ret

check_is_20bit_imm:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal parse_immediate
    beqz a1, imm20_fail
    li t0, -524288
    blt a0, t0, imm20_fail
    li t0, 524287
    bgt a0, t0, imm20_fail
    lw ra, 0(sp)
    addi sp, sp, 4
    li a0, 1
    ret

imm20_fail:
    lw ra, 0(sp)
    addi sp, sp, 4
    li a0, 0
    ret

check_is_label:
    mv t0, a0
    lb t1, 0(t0)
    beqz t1, label_fail
    li t2, '_'
    beq t1, t2, label_check_rest
    li t2, 'A'
    blt t1, t2, label_fail
    li t2, 'Z'
    ble t1, t2, label_check_rest
    li t2, 'a'
    blt t1, t2, label_fail
    li t2, 'z'
    bgt t1, t2, label_fail

label_check_rest:
    addi t0, t0, 1
label_loop:
    lb t1, 0(t0)
    beqz t1, label_valid
    li t2, '_'
    beq t1, t2, label_continue
    li t2, '0'
    blt t1, t2, label_fail
    li t2, '9'
    ble t1, t2, label_continue
    li t2, 'A'
    blt t1, t2, label_fail
    li t2, 'Z'
    ble t1, t2, label_continue
    li t2, 'a'
    blt t1, t2, label_fail
    li t2, 'z'
    bgt t1, t2, label_fail

label_continue:
    addi t0, t0, 1
    j label_loop

label_valid:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal find_opcode
    lw ra, 0(sp)
    addi sp, sp, 4
    li t0, -1
    bne a0, t0, label_fail
    li a0, 1
    ret

label_fail:
    li a0, 0
    ret

check_is_address:
    addi sp, sp, -8
    sw ra, 0(sp)
    sw s0, 4(sp)
    mv s0, a0
    mv t0, s0
find_paren:
    lb t1, 0(t0)
    beqz t1, addr_fail
    li t2, '('
    beq t1, t2, found_paren
    addi t0, t0, 1
    j find_paren

found_paren:
    mv t1, s0
    la t2, token
extract_offset:
    beq t1, t0, offset_done
    lb t3, 0(t1)
    sb t3, 0(t2)
    addi t1, t1, 1
    addi t2, t2, 1
    j extract_offset

offset_done:
    sb zero, 0(t2)
    la a0, token
    jal check_is_12bit_imm
    beqz a0, addr_fail
    addi t0, t0, 1
    la t2, token
extract_reg:
    lb t3, 0(t0)
    beqz t3, addr_fail
    li t4, ')'
    beq t3, t4, reg_done
    sb t3, 0(t2)
    addi t0, t0, 1
    addi t2, t2, 1
    j extract_reg

reg_done:
    sb zero, 0(t2)
    addi t0, t0, 1
    lb t3, 0(t0)
    bnez t3, addr_fail
    la a0, token
    jal check_is_register
    lw s0, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 8
    ret

addr_fail:
    lw s0, 4(sp)
    lw ra, 0(sp)
    addi sp, sp, 8
    li a0, 0
    ret

parse_immediate:
    mv t0, a0
    lb t1, 0(t0)
    beqz t1, parse_fail
    li t6, 0
    li t2, '-'
    bne t1, t2, check_hex
    li t6, 1
    addi t0, t0, 1
    lb t1, 0(t0)

check_hex:
    li t2, '0'
    bne t1, t2, parse_decimal
    addi t0, t0, 1
    lb t1, 0(t0)
    li t2, 'x'
    beq t1, t2, parse_hex
    li t2, 'X'
    beq t1, t2, parse_hex
    addi t0, t0, -1
    j parse_decimal

parse_hex:
    addi t0, t0, 1
    li t3, 0
hex_loop:
    lb t1, 0(t0)
    beqz t1, parse_done
    li t2, '0'
    blt t1, t2, parse_fail
    li t2, '9'
    ble t1, t2, hex_digit
    li t2, 'A'
    blt t1, t2, parse_fail
    li t2, 'F'
    ble t1, t2, hex_upper
    li t2, 'a'
    blt t1, t2, parse_fail
    li t2, 'f'
    bgt t1, t2, parse_fail
    li t2, 'a'
    sub t1, t1, t2
    addi t1, t1, 10
    j hex_add

hex_upper:
    li t2, 'A'
    sub t1, t1, t2
    addi t1, t1, 10
    j hex_add

hex_digit:
    li t2, '0'
    sub t1, t1, t2

hex_add:
    slli t3, t3, 4
    add t3, t3, t1
    addi t0, t0, 1
    j hex_loop

parse_decimal:
    li t3, 0
dec_loop:
    lb t1, 0(t0)
    beqz t1, parse_done
    li t2, '0'
    blt t1, t2, parse_fail
    li t2, '9'
    bgt t1, t2, parse_fail
    li t4, 10
    mul t3, t3, t4
    li t2, '0'
    sub t1, t1, t2
    add t3, t3, t1
    addi t0, t0, 1
    j dec_loop

parse_done:
    beqz t6, parse_success
    neg t3, t3

parse_success:
    mv a0, t3
    li a1, 1
    ret

parse_fail:
    li a0, 0
    li a1, 0
    ret

# ============================================
# OPERAND CHECKERS
# ============================================

check_reg_op1:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal get_next_token
    la a0, token
    jal check_is_register
    beqz a0, e_op1
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

check_reg_op2:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal get_next_token
    la a0, token
    jal check_is_register
    beqz a0, e_op2
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

check_reg_op3:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal get_next_token
    la a0, token
    jal check_is_register
    beqz a0, e_op3
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

check_5bit_imm_op3:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal get_next_token
    la a0, token
    jal check_is_5bit_imm
    beqz a0, e_op3
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

check_12bit_imm_op3:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal get_next_token
    la a0, token
    jal check_is_12bit_imm
    beqz a0, e_op3
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

check_20bit_imm_op2:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal get_next_token
    la a0, token
    jal check_is_20bit_imm
    beqz a0, e_op2
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

check_label_op2:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal get_next_token
    la a0, token
    jal check_is_label
    beqz a0, e_op2
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

check_label_op3:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal get_next_token
    la a0, token
    jal check_is_label
    beqz a0, e_op3
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

check_address_op2:
    addi sp, sp, -4
    sw ra, 0(sp)
    jal get_next_token
    la a0, token
    jal check_is_address
    beqz a0, addr_op2_fail
    lw ra, 0(sp)
    addi sp, sp, 4
    ret

addr_op2_fail:
    lw ra, 0(sp)
    addi sp, sp, 4
    j e_op2

# ============================================
# ERROR HANDLERS
# ============================================

err_opcode:
    la a0, msg_err_op
    jal print_string
    j done

e_op1:
    la a0, msg_err_op1
    jal print_string
    j done

e_op2:
    la a0, msg_err_op2
    jal print_string
    j done

e_op3:
    la a0, msg_err_op3
    jal print_string
    j done

success:
    la a0, msg_success
    jal print_string
    j done

# ============================================
# CONTINUE OR EXIT
# ============================================

done:
    la a0, msg_continue
    jal print_string
wait_continue_input:
    li t0, KEYBOARD_CTRL
    lw t1, 0(t0)
    andi t1, t1, 0x1
    beqz t1, wait_continue_input
    li t0, KEYBOARD_DATA
    lw t2, 0(t0)
wait_display_continue:
    li t0, DISPLAY_CTRL
    lw t3, 0(t0)
    andi t3, t3, 0x1
    beqz t3, wait_display_continue
    li t0, DISPLAY_DATA
    sw t2, 0(t0)
    li t3, '1'
    beq t2, t3, program_loop
    li t3, '0'
    beq t2, t3, exit_program
    j wait_continue_input

exit_program:
    la a0, msg_exit
    jal print_string
    li a7, 10
    ecall
