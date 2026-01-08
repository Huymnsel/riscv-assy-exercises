.data
# Buffers for input and token storage
buffer: .space 256          # Buffer to store user input instruction
token: .space 64            # Buffer to store extracted tokens

# User interface messages
msg_input: .string "\nEnter instruction: "
msg_valid_op: .string "\nOpcode: "
msg_valid_ok: .string ", valid.\n"
msg_err_op: .string "\nError: Invalid or unsupported opcode."
msg_err_op1: .string "Error: Invalid Operand 1."
msg_err_op2: .string "Error: Invalid Operand 2."
msg_err_op3: .string "Error: Invalid Operand 3."
msg_success: .string "Syntax is valid."
msg_continue: .string "\n\nContinue? (1=Yes, 0=No): "
msg_exit: .string "\nProgram ended\n"
newline: .string "\n"
backspace_seq: .byte 8, 32, 8, 0  # Backspace display sequence: BS, SPACE, BS

# RISC-V opcode strings
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

# Opcode mapping table: [opcode_string_address, instruction_type]
# Type codes: 1=Load, 2=U-type, 3=I-type, 4=R-type, 5=Branch, 6=J-type, 7=Shift-Imm, 10=Store
opcode_map:
	.word op_lw, 1          # Load instructions
	.word op_lb, 1 
	.word op_lh, 1
	.word op_lbu, 1
	.word op_lhu, 1
	.word op_sw, 10         # Store instructions
	.word op_sb, 10
	.word op_sh, 10
	.word op_lui, 2         # Upper Immediate instructions
	.word op_auipc, 2
	.word op_slli, 7        # Shift Immediate instructions
	.word op_srli, 7
	.word op_srai, 7
	.word op_addi, 3        # I-type instructions
	.word op_andi, 3
	.word op_ori, 3
	.word op_xori, 3
	.word op_slti, 3
	.word op_sltiu, 3
	.word op_jalr, 3
	.word op_add, 4         # R-type instructions
	.word op_sub, 4
	.word op_sll, 4
	.word op_slt, 4
	.word op_sltu, 4
	.word op_xor, 4
	.word op_srl, 4
	.word op_sra, 4
	.word op_or, 4
	.word op_and, 4
	.word op_beq, 5         # Branch instructions
	.word op_bne, 5
	.word op_blt, 5
	.word op_bge, 5
	.word op_bltu, 5
	.word op_bgeu, 5
	.word op_jal, 6         # J-type instruction
	.word 0, 0              # End marker

# Register name table (null-terminated strings)
regs: .string "zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2", "t3", "t4", "t5", "t6", "s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10", "s11", "a0", "a1", "a2", "a3", "a4", "a5", "a6", "a7", ""

# Memory-mapped I/O addresses for keyboard and display
.eqv KEYBOARD_CTRL 0xFFFF0000
.eqv KEYBOARD_DATA 0xFFFF0004
.eqv DISPLAY_CTRL  0xFFFF0008
.eqv DISPLAY_DATA  0xFFFF000C

.text
main:
program_loop:
	# Print input prompt character by character
	la s0, msg_input
print_prompt_loop:
	lb t2, 0(s0)                    # Load next character
	beqz t2, init_buffer            # If null terminator, done printing
wait_display_prompt:
	li t0, DISPLAY_CTRL
	lw t3, 0(t0)                    # Check display ready bit
	andi t3, t3, 0x1
	beqz t3, wait_display_prompt    # Wait until display is ready
	li t0, DISPLAY_DATA
	sw t2, 0(t0)                    # Write character to display
	addi s0, s0, 1                  # Move to next character
	j print_prompt_loop

init_buffer:
	# Initialize buffer pointer
	la s0, buffer                   # s0 = current position in buffer
	mv s9, s0                       # s9 = start of buffer (for backspace check)

input_loop:
	# Poll keyboard for input
	li t0, KEYBOARD_CTRL
	lw t1, 0(t0)                    # Check keyboard ready bit
	andi t1, t1, 0x1
	beqz t1, input_loop             # Wait for key press
	li t0, KEYBOARD_DATA
	lw t2, 0(t0)                    # Read character from keyboard
	
	# Check for special characters
	li t3, 8                        # ASCII backspace
	beq t2, t3, handle_backspace
	li t3, 127                      # DEL key
	beq t2, t3, handle_backspace
	li t3, 10                       # Enter key
	beq t2, t3, start_parse
	
	# Echo character to display and store in buffer
wait_display:
	li t0, DISPLAY_CTRL
	lw t3, 0(t0)
	andi t3, t3, 0x1
	beqz t3, wait_display
	li t0, DISPLAY_DATA
	sw t2, 0(t0)                    # Echo to display
	sb t2, 0(s0)                    # Store in buffer
	addi s0, s0, 1                  # Advance buffer pointer
	j input_loop

handle_backspace:
	# Handle backspace: not delete before buffer start
	beq s0, s9, input_loop          # If at start, ignore backspace
	addi s0, s0, -1                 # Move buffer pointer back
	
	# Display backspace sequence to clear character
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
	# Echo newline and start parsing
	li t2, 10
wait_display_newline:
	li t0, DISPLAY_CTRL
	lw t3, 0(t0)
	andi t3, t3, 0x1
	beqz t3, wait_display_newline
	li t0, DISPLAY_DATA
	sw t2, 0(t0)
	
	# Null-terminate buffer and begin parsing
	sb zero, 0(s0)
	la s1, buffer                   # s1 = current parse position
	
	# Extract first token (opcode)
	jal get_next_token
	la a0, token
	jal find_opcode                 # Look up opcode in table
	li t0, -1
	beq a0, t0, err_opcode          # If not found, error
	
	# Valid opcode found, store type and print confirmation
	mv s2, a0                       # s2 = instruction type
	la a0, msg_valid_op
	jal print_string
	la a0, token
	jal print_string
	la a0, msg_valid_ok
	jal print_string
	
	# Jump to appropriate type checker based on instruction type
	li t0, 1
	beq s2, t0, type_load           # Type 1: Load
	li t0, 10
	beq s2, t0, type_store          # Type 10: Store
	li t0, 2
	beq s2, t0, type_u              # Type 2: U-type
	li t0, 3
	beq s2, t0, type_i              # Type 3: I-type
	li t0, 7
	beq s2, t0, type_shift_imm      # Type 7: Shift immediate
	li t0, 4
	beq s2, t0, type_r              # Type 4: R-type
	li t0, 5
	beq s2, t0, type_b              # Type 5: Branch
	li t0, 6
	beq s2, t0, type_jal            # Type 6: J-type (jal)
	j done

# Instruction type validation routines
type_load:
	# Format: lw rd, offset(rs1)
	jal check_reg_op1               # Check rd (destination register)
	jal check_address_op2           # Check offset(rs1)
	j success

type_store:
	# Format: sw rs2, offset(rs1)
	jal check_reg_op1               # Check rs2 (source register)
	jal check_address_op2           # Check offset(rs1)
	j success

type_u:
	# Format: lui rd, imm20
	jal check_reg_op1               # Check rd
	jal check_20bit_imm_op2         # Check 20-bit immediate
	j success

type_i:
	# Format: addi rd, rs1, imm12
	jal check_reg_op1               # Check rd
	jal check_reg_op2               # Check rs1
	jal check_12bit_imm_op3         # Check 12-bit immediate
	j success

type_shift_imm:
	# Format: slli rd, rs1, shamt
	jal check_reg_op1               # Check rd
	jal check_reg_op2               # Check rs1
	jal check_5bit_imm_op3          # Check 5-bit shift amount
	j success

type_r:
	# Format: add rd, rs1, rs2
	jal check_reg_op1               # Check rd
	jal check_reg_op2               # Check rs1
	jal check_reg_op3               # Check rs2
	j success

type_b:
	# Format: beq rs1, rs2, label
	jal check_reg_op1               # Check rs1
	jal check_reg_op2               # Check rs2
	jal check_label_op3             # Check label
	j success

type_jal:
	# Format: jal rd, label
	jal check_reg_op1               # Check rd
	jal check_label_op2             # Check label
	j success

# Tokenizer: Extract next token from input buffer
get_next_token:
	la t0, token                    # t0 = token buffer pointer
	mv t1, s1                       # t1 = current parse position
	
skip_whitespace:
	# Skip spaces, tabs, and commas
	lb t2, 0(t1)
	beqz t2, token_end              # End of input
	li t3, 32                       # Space
	beq t2, t3, skip_ws_inc
	li t3, 9                        # Tab
	beq t2, t3, skip_ws_inc
	li t3, 44                       # Comma
	beq t2, t3, skip_ws_inc
	j start_extract
skip_ws_inc:
	addi t1, t1, 1
	j skip_whitespace

start_extract:
	# Extract token until whitespace or comma
	lb t2, 0(t1)
	beqz t2, token_end
	li t3, 32
	beq t2, t3, token_end
	li t3, 9
	beq t2, t3, token_end
	li t3, 44
	beq t2, t3, token_end
	li t3, 10                       # Newline
	beq t2, t3, token_end
	sb t2, 0(t0)                    # Copy character to token
	addi t0, t0, 1
	addi t1, t1, 1
	j start_extract

token_end:
	sb zero, 0(t0)                  # Null-terminate token
	mv s1, t1                       # Update parse position
	ret

# Opcode lookup: Search for token in opcode_map
find_opcode:
	addi sp, sp, -8
	sw ra, 0(sp)
	sw s0, 4(sp)
	mv s0, a0                       # s0 = token to find
	la t0, opcode_map
	
find_loop:
	lw t1, 0(t0)                    # Load opcode string address
	beqz t1, find_not_found         # End of table
	mv t2, s0                       # Reset comparison pointers
	mv t3, t1
	
compare_loop:
	# Compare token with opcode string character by character
	lb t4, 0(t2)
	lb t5, 0(t3)
	bne t4, t5, find_next           # Mismatch
	beqz t4, find_match             # Both null = match
	addi t2, t2, 1
	addi t3, t3, 1
	j compare_loop
	
find_next:
	addi t0, t0, 8                  # Move to next entry (8 bytes)
	j find_loop
	
find_match:
	lw a0, 4(t0)                    # Return instruction type
	lw s0, 4(sp)
	lw ra, 0(sp)
	addi sp, sp, 8
	ret
	
find_not_found:
	li a0, -1                       # Return -1 for not found
	lw s0, 4(sp)
	lw ra, 0(sp)
	addi sp, sp, 8
	ret

# Print string to display
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

# Check if token is a valid register name
check_is_register:
	mv t0, a0
	lb t1, 0(t0)
	li t2, 'x'
	beq t1, t2, check_x_register    # Check x0-x31 format
	
	# Check against register name table
	la t1, regs
ir_scan:
	lb t2, 0(t1)
	beqz t2, ir_fail                # End of register list
	mv t3, t0                       # Reset comparison pointers
	mv t4, t1
	
ir_cmp:
	# Compare token with register name
	lb t5, 0(t3)
	lb t6, 0(t4)
	bne t5, t6, ir_next_word
	beqz t5, ir_match               # Both null = match
	addi t3, t3, 1
	addi t4, t4, 1
	j ir_cmp
	
ir_next_word:
	# Skip to next register name
	addi t1, t1, 1
	lb t2, 0(t1)
	bnez t2, ir_next_word
	addi t1, t1, 1
	j ir_scan
	
ir_match:
	li a0, 1                        # Valid register
	ret
	
ir_fail:
	li a0, 0                        # Invalid register
	ret

# Check x-register format (x0 to x31)
check_x_register:
	addi t0, t0, 1                  # Skip 'x'
	lb t1, 0(t0)
	li t2, '0'
	blt t1, t2, ir_fail             # Not a digit
	li t2, '9'
	bgt t1, t2, ir_fail
	
	# Parse first digit
	li t2, '0'
	sub t3, t1, t2                  # t3 = register number
	addi t0, t0, 1
	lb t1, 0(t0)
	beqz t1, check_x_range_single   # Single digit
	
	# Parse second digit (for x10-x31)
	li t2, '0'
	blt t1, t2, ir_fail
	li t2, '9'
	bgt t1, t2, ir_fail
	li t4, 10
	mul t3, t3, t4                  # t3 = first_digit * 10
	li t2, '0'
	sub t4, t1, t2
	add t3, t3, t4                  # t3 = register number
	addi t0, t0, 1
	lb t1, 0(t0)
	bnez t1, ir_fail                # Should be end of token
	
	# Validate range 0-31
	bltz t3, ir_fail
	li t4, 31
	bgt t3, t4, ir_fail
	li a0, 1
	ret

check_x_range_single:
	li a0, 1
	ret

# Parse immediate value (decimal or hexadecimal)
parse_immediate:
	mv t0, a0
	lb t1, 0(t0)
	beqz t1, parse_fail
	
	# Check for negative sign
	li t6, 0                        # t6 = is_negative flag
	li t2, '-'
	bne t1, t2, check_hex
	li t6, 1
	addi t0, t0, 1
	lb t1, 0(t0)

check_hex:
	# Check for 0x prefix (hexadecimal)
	li t2, '0'
	bne t1, t2, parse_decimal
	addi t0, t0, 1
	lb t1, 0(t0)
	li t2, 'x'
	beq t1, t2, parse_hex
	li t2, 'X'
	beq t1, t2, parse_hex
	addi t0, t0, -1                 # False alarm, just '0'
	j parse_decimal

parse_hex:
	# Parse hexadecimal number
	addi t0, t0, 1
	li t3, 0                        # t3 = result
hex_loop:
	lb t1, 0(t0)
	beqz t1, parse_done
	
	# Check digit 0-9
	li t2, '0'
	blt t1, t2, parse_fail
	li t2, '9'
	ble t1, t2, hex_digit
	
	# Check A-F
	li t2, 'A'
	blt t1, t2, parse_fail
	li t2, 'F'
	ble t1, t2, hex_upper
	
	# Check a-f
	li t2, 'a'
	blt t1, t2, parse_fail
	li t2, 'f'
	bgt t1, t2, parse_fail
	li t2, 'a'
	sub t1, t1, t2
	addi t1, t1, 10                 # a-f = 10-15
	j hex_add

hex_upper:
	li t2, 'A'
	sub t1, t1, t2
	addi t1, t1, 10                 # A-F = 10-15
	j hex_add

hex_digit:
	li t2, '0'
	sub t1, t1, t2                  # 0-9 = 0-9

hex_add:
	slli t3, t3, 4                  # Shift left 4 bits
	add t3, t3, t1                  # Add new digit
	addi t0, t0, 1
	j hex_loop

parse_decimal:
	# Parse decimal number
	li t3, 0
dec_loop:
	lb t1, 0(t0)
	beqz t1, parse_done
	li t2, '0'
	blt t1, t2, parse_fail
	li t2, '9'
	bgt t1, t2, parse_fail
	li t4, 10
	mul t3, t3, t4                  # t3 *= 10
	li t2, '0'
	sub t1, t1, t2
	add t3, t3, t1                  # t3 += digit
	addi t0, t0, 1
	j dec_loop

parse_done:
	beqz t6, parse_success          # If not negative, done
	neg t3, t3                      # Negate if negative

parse_success:
	mv a0, t3                       # Return value
	li a1, 1                        # Return success flag
	ret

parse_fail:
	li a0, 0
	li a1, 0                        # Return failure flag
	ret

# Validate 5-bit immediate (0-31 for shift amount)
check_is_5bit_imm:
	addi sp, sp, -4
	sw ra, 0(sp)
	jal parse_immediate
	beqz a1, imm5_fail              # Parse failed
	bltz a0, imm5_fail              # Negative not allowed
	li t0, 31
	bgt a0, t0, imm5_fail           # Out of range
	lw ra, 0(sp)
	addi sp, sp, 4
	li a0, 1
	ret
imm5_fail:
	lw ra, 0(sp)
	addi sp, sp, 4
	li a0, 0
	ret

# Validate 12-bit signed immediate (-2048 to 2047)
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

# Validate 20-bit signed immediate (-524288 to 524287)
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

# Validate label (identifier: starts with letter/underscore, contains alphanumeric/underscore)
check_is_label:
	mv t0, a0
	lb t1, 0(t0)
	beqz t1, label_fail
	
	# First character must be letter or underscore
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
	# Remaining characters can be alphanumeric or underscore
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
	# Make sure label is not an opcode
	addi sp, sp, -4
	sw ra, 0(sp)
	jal find_opcode
	lw ra, 0(sp)
	addi sp, sp, 4
	li t0, -1
	bne a0, t0, label_fail          # If found in opcode table, not a valid label
	li a0, 1
	ret

label_fail:
	li a0, 0
	ret

# Validate address format: offset(register)
check_is_address:
	addi sp, sp, -8
	sw ra, 0(sp)
	sw s0, 4(sp)
	mv s0, a0
	mv t0, s0
	
find_paren:
	# Find opening parenthesis
	lb t1, 0(t0)
	beqz t1, addr_fail
	li t2, '('
	beq t1, t2, found_paren
	addi t0, t0, 1
	j find_paren

found_paren:
	# Extract offset part
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
	jal check_is_12bit_imm          # Validate offset as 12-bit immediate
	beqz a0, addr_fail
	
	# Extract register part
	addi t0, t0, 1                  # Skip '('
	la t2, token
extract_reg:
	lb t3, 0(t0)
	beqz t3, addr_fail
	li t4, ')'
	beq t3, t4, reg_done            # Found closing parenthesis
	sb t3, 0(t2)
	addi t0, t0, 1
	addi t2, t2, 1
	j extract_reg

reg_done:
	sb zero, 0(t2)
	addi t0, t0, 1
	lb t3, 0(t0)
	bnez t3, addr_fail              # Should be end of token
	la a0, token
	jal check_is_register           # Validate register
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

# Operand checking wrappers
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
	beqz a0, e_op2
	lw ra, 0(sp)
	addi sp, sp, 4
	ret

# Error handlers
err_opcode:
	la a0, msg_err_op
	jal print_string
	j done

e_op1:
	la a0, newline
	jal print_string
	la a0, msg_err_op1
	jal print_string
	j done

e_op2:
	la a0, newline
	jal print_string
	la a0, msg_err_op2
	jal print_string
	j done

e_op3:
	la a0, newline
	jal print_string
	la a0, msg_err_op3
	jal print_string
	j done

success:
	la a0, msg_success
	jal print_string
	j done

done:
	# Ask user if they want to continue
	la a0, msg_continue
	jal print_string
	
wait_continue_input:
	# Wait for '1' or '0' input
	li t0, KEYBOARD_CTRL
	lw t1, 0(t0)
	andi t1, t1, 0x1
	beqz t1, wait_continue_input
	li t0, KEYBOARD_DATA
	lw t2, 0(t0)
	li t3, '1'
	beq t2, t3, got_one
	li t3, '0'
	beq t2, t3, got_zero
	j wait_continue_input           # Ignore invalid input

got_one:
	# User chose to continue
wait_display_one:
	li t0, DISPLAY_CTRL
	lw t3, 0(t0)
	andi t3, t3, 0x1
	beqz t3, wait_display_one
	li t0, DISPLAY_DATA
	li t2, '1'
	sw t2, 0(t0)                    # Echo '1'
	
wait_enter_one:
	# Wait for Enter key
	li t0, KEYBOARD_CTRL
	lw t1, 0(t0)
	andi t1, t1, 0x1
	beqz t1, wait_enter_one
	li t0, KEYBOARD_DATA
	lw t2, 0(t0)
	li t3, 10
	bne t2, t3, wait_enter_one
	
	li t2, 10
wait_display_nl_one:
	li t0, DISPLAY_CTRL
	lw t3, 0(t0)
	andi t3, t3, 0x1
	beqz t3, wait_display_nl_one
	li t0, DISPLAY_DATA
	sw t2, 0(t0)                    # Echo newline
	j program_loop                  # Loop back to start

got_zero:
	# User chose to exit
wait_display_zero:
	li t0, DISPLAY_CTRL
	lw t3, 0(t0)
	andi t3, t3, 0x1
	beqz t3, wait_display_zero
	li t0, DISPLAY_DATA
	li t2, '0'
	sw t2, 0(t0)                    # Echo '0'
	
wait_enter_zero:
	# Wait for Enter key
	li t0, KEYBOARD_CTRL
	lw t1, 0(t0)
	andi t1, t1, 0x1
	beqz t1, wait_enter_zero
	li t0, KEYBOARD_DATA
	lw t2, 0(t0)
	li t3, 10
	bne t2, t3, wait_enter_zero
	
	li t2, 10
wait_display_nl_zero:
	li t0, DISPLAY_CTRL
	lw t3, 0(t0)
	andi t3, t3, 0x1
	beqz t3, wait_display_nl_zero
	li t0, DISPLAY_DATA
	sw t2, 0(t0)                    # Echo newline
	j exit_program

exit_program:
	la a0, msg_exit
	jal print_string
	li a7, 10                       
	ecall
