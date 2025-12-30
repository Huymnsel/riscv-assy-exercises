.data
buffer: .space 256
token: .space 64

# Opcode Map Logic:
# The 2nd number (1, 10, 2...) acts as a "Function Selector" or "Type ID".
# The parser uses this ID to determine which validation subroutine to call.
opcode_map:
.word op_lw, 1        # ID 1 -> Load (check reg, address)
.word op_lb, 1
.word op_lh, 1
.word op_lbu, 1
.word op_lhu, 1
.word op_sw, 10       # ID 10 -> Store (check reg, address)
.word op_sb, 10
.word op_sh, 10
.word op_lui, 2       # ID 2 -> U-Type (check reg, 20-bit imm)
.word op_auipc, 2
.word op_addi, 3      # ID 3 -> I-Type (check reg, reg, 12-bit imm)
.word op_slli, 7      # ID 7 -> Shift (check reg, reg, 5-BIT IMM)
.word op_srli, 7      
.word op_srai, 7      
.word op_andi, 3
.word op_ori, 3
.word op_xori, 3
.word op_slti, 3
.word op_sltiu, 3
.word op_jalr, 3
.word op_add, 4       # ID 4 -> R-Type (check 3 regs)
.word op_sub, 4
.word op_sll, 4
.word op_slt, 4
.word op_sltu, 4
.word op_xor, 4
.word op_srl, 4
.word op_sra, 4
.word op_or, 4
.word op_and, 4
.word op_beq, 5       # ID 5 -> Branch (check 2 regs, label)
.word op_bne, 5
.word op_blt, 5
.word op_bge, 5
.word op_bltu, 5
.word op_bgeu, 5
.word op_jal, 6       # ID 6 -> Jal (check reg, label)
.word 0, 0            # Sentinel value to mark end of array

# ... (Regs array and MMIO constants) ...

.text
main:
program_loop:
    la s0, msg_input
print_prompt_loop:
    lb t2, 0(s0)
    beqz t2, init_buffer
    # Logic: MMIO Polling for Display
    # Loop continuously reading DISPLAY_CTRL until the Ready bit (bit 0) is 1.
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
    mv s9, s0               # Save buffer start address for boundary check

input_loop:
    # Logic: MMIO Polling for Keyboard
    # Loop until KEYBOARD_CTRL Ready bit is 1, indicating a key press.
    li t0, KEYBOARD_CTRL
    lw t1, 0(t0)
    andi t1, t1, 0x1
    beqz t1, input_loop
    li t0, KEYBOARD_DATA
    lw t2, 0(t0)
    
    # Logic: Special Key Handling
    li t3, 8                # Backspace ASCII
    beq t2, t3, handle_backspace
    li t3, 127              # DEL ASCII
    beq t2, t3, handle_backspace
    li t3, 10               # Enter/Newline ASCII
    beq t2, t3, start_parse # Trigger parsing sequence on Enter

wait_display:
    # [Display polling logic omitted for brevity - same as above]
    li t0, DISPLAY_CTRL
    lw t3, 0(t0)
    andi t3, t3, 0x1
    beqz t3, wait_display
    li t0, DISPLAY_DATA
    sw t2, 0(t0)
    sb t2, 0(s0)            # Logic: Store character into buffer memory
    addi s0, s0, 1          # Advance buffer pointer
    j input_loop

handle_backspace:
    # Logic: Prevent backspacing past the start of the buffer
    beq s0, s9, input_loop
    addi s0, s0, -1         # Logic: Move pointer back to overwrite last char
    la t4, backspace_seq    # Logic: Send destructive backspace sequence to terminal
backspace_display_loop:
    lb t2, 0(t4)
    beqz t2, input_loop
    # [Display polling logic]
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
    # [Newline display logic omitted]
    li t2, 10
wait_display_newline:
    li t0, DISPLAY_CTRL
    lw t3, 0(t0)
    andi t3, t3, 0x1
    beqz t3, wait_display_newline
    li t0, DISPLAY_DATA
    sw t2, 0(t0)
    
    sb zero, 0(s0)          # Logic: Append Null Terminator to finalize string
    la s1, buffer           # Reset parsing pointer s1 to start of buffer
    jal get_next_token      # Logic: Extract the first word (Opcode)
    la a0, token
    jal find_opcode         # Logic: Search opcode_map for Type ID
    
    li t0, -1
    beq a0, t0, err_opcode  # Logic: Check if opcode was found (ID != -1)
    mv s2, a0               # Logic: Store Type ID in s2 for dispatching
    
    # [Success message printing logic omitted]
    la a0, msg_valid_op
    jal print_string
    la a0, token
    jal print_string
    la a0, msg_valid_ok
    jal print_string

    # Logic: Dispatcher / Switch-Case
    # Compare Type ID (s2) and jump to specific format validator
    li t0, 1
    beq s2, t0, type_load
    li t0, 10
    beq s2, t0, type_store
    li t0, 2
    beq s2, t0, type_u
    li t0, 3
    beq s2, t0, type_i
    li t0, 7
    beq s2, t0, type_shift  # Logic: Special handling for 5-bit shift limit
    li t0, 4
    beq s2, t0, type_r
    li t0, 5
    beq s2, t0, type_b
    li t0, 6
    beq s2, t0, type_jal
    j done

# --- VALIDATION LOGIC BLOCK ---

type_load:
    # Logic: Validates format 'lw reg, offset(reg)'
    jal check_reg_op1       # 1. Destination Register
    jal check_address_op2   # 2. Address format (imm + base reg)
    j success

type_store:
    # Logic: Validates format 'sw reg, offset(reg)'
    jal check_reg_op1       # 1. Source Register
    jal check_address_op2   # 2. Address format
    j success

type_u:
    # Logic: Validates format 'lui reg, imm'
    jal check_reg_op1
    jal check_20bit_imm_op2 # Logic: Checks for 20-bit overflow
    j success

type_i:
    # Logic: Validates format 'addi reg, reg, imm'
    jal check_reg_op1
    jal check_reg_op2
    jal check_12bit_imm_op3 # Logic: Checks for signed 12-bit overflow
    j success

type_shift:
    # Logic: Validates format 'slli reg, reg, shamt'
    jal check_reg_op1
    jal check_reg_op2
    jal check_5bit_imm_op3  # Logic: CRITICAL - Checks if immediate is 0-31
    j success

# [Other types follow similar logic pattern]
type_r:
    jal check_reg_op1
    jal check_reg_op2
    jal check_reg_op3
    j success

type_b:
    jal check_reg_op1
    jal check_reg_op2
    jal check_label_op3     # Logic: Checks if op3 is a valid label format
    j success

type_jal:
    jal check_reg_op1
    jal check_label_op2
    j success

# --- CORE CHECKING ALGORITHMS ---

check_is_register:
    mv t0, a0
    lb t1, 0(t0)
    
    # Logic: Try parsing as 'x' notation (x0-x31)
    li t2, 'x'
    beq t1, t2, check_x_register
    
    # Logic: Try finding match in ABI name list (zero, sp, ra...)
    la t1, regs
ir_scan:
    lb t2, 0(t1)
    beqz t2, ir_fail        # End of list reached, no match
    mv t3, t0
    mv t4, t1
ir_cmp:                     # String compare loop
    lb t5, 0(t3)
    lb t6, 0(t4)
    bne t5, t6, ir_next_word
    beqz t5, ir_match       # Exact match found
    addi t3, t3, 1
    addi t4, t4, 1
    j ir_cmp
ir_next_word:
    # Logic: Skip to next word in the 'regs' null-terminated string list
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
    # Logic: Parse numbers following 'x' and ensure range [0, 31]
    addi t0, t0, 1
    lb t1, 0(t0)
    # [Digit validation omitted]
    li t2, '0'
    sub t3, t1, t2          # Convert char to int
    addi t0, t0, 1
    lb t1, 0(t0)
    beqz t1, check_x_range_single # Single digit (x0-x9) -> Valid
    
    # Logic: Handle 2nd digit calculation: val = digit1 * 10 + digit2
    li t4, 10
    mul t3, t3, t4
    li t2, '0'
    sub t4, t1, t2
    add t3, t3, t4
    
    # Logic: Range check (Must be <= 31)
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
    beqz a1, imm5_fail      # Logic: Check parsing status (1=success)
    
    # Logic: Range Check [0, 31]
    bltz a0, imm5_fail      # Must be positive
    li t0, 31
    bgt a0, t0, imm5_fail   # Must be <= 31
    lw ra, 0(sp)
    addi sp, sp, 4
    li a0, 1
    ret

# [Other immediate checks (12-bit, 20-bit) follow same range check logic]
# ...

check_is_address:
    # Logic: Parses 'offset(base)'
    # 1. Scan for open parenthesis '('
    # 2. Extract substring before '(' as Offset
    # 3. Extract substring inside '()' as Register
    # 4. Validate both parts independently
    
    # ... [Implementation omitted for brevity] ...
    jal check_is_12bit_imm  # Validate Offset part
    # ...
    jal check_is_register   # Validate Base Register part
    # ...
    ret

parse_immediate:
    # Logic: State Machine for Number Parsing
    # 1. Check sign ('-')
    # 2. Check base prefix ('0x' -> Hex, otherwise -> Decimal)
    # 3. Accumulate value based on base
    
    mv t0, a0
    lb t1, 0(t0)
    beqz t1, parse_fail
    li t6, 0                # Logic: Flag for negative numbers
    li t2, '-'
    bne t1, t2, check_hex
    li t6, 1                # Set negative flag
    addi t0, t0, 1
    lb t1, 0(t0)

check_hex:
    # Logic: Detect '0x' or '0X' prefix
    li t2, '0'
    bne t1, t2, parse_decimal
    addi t0, t0, 1
    lb t1, 0(t0)
    li t2, 'x'
    beq t1, t2, parse_hex
    li t2, 'X'
    beq t1, t2, parse_hex
    addi t0, t0, -1         # Backtrack if just '0'
    j parse_decimal

parse_hex:
    addi t0, t0, 1
    li t3, 0
hex_loop:
    # Logic: Hex conversion algorithm: result = (result << 4) + new_digit
    lb t1, 0(t0)
    beqz t1, parse_done
    # [Char to Int conversion logic omitted]
hex_add:
    slli t3, t3, 4          # Shift left by 4 (multiply by 16)
    add t3, t3, t1
    addi t0, t0, 1
    j hex_loop

parse_decimal:
    li t3, 0
dec_loop:
    # Logic: Decimal conversion algorithm: result = (result * 10) + new_digit
    lb t1, 0(t0)
    beqz t1, parse_done
    # [Char to Int conversion logic omitted]
    li t4, 10
    mul t3, t3, t4          # Multiply by 10
    add t3, t3, t1
    addi t0, t0, 1
    j dec_loop

parse_done:
    beqz t6, parse_success
    neg t3, t3              # Logic: Apply 2's complement if negative flag was set

parse_success:
    mv a0, t3
    li a1, 1                # Logic: Return Status = Valid
    ret

check_address_op2:
    # Logic: Helper function to isolate the address token
    # It scans past spaces/commas to find the start of the address,
    # then copies characters until a space/comma/newline is found.
    # Finally, it calls the core logic `check_is_address`.