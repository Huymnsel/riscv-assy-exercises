.eqv IN_ADDRESS_HEXA_KEYBOARD 0xFFFF0012
.eqv OUT_ADDRESS_HEXA_KEYBOARD 0xFFFF0014

.data
# Lookup table: [key_code, song_address]
lookup_table:
	.word 0x11, 0
	.word 0x21, song1
	.word 0x41, song2
	.word 0xffffff81, song3
	.word 0x12, song4
	.word 0, 0                      # End marker
	
# UI Messages
prompt_msg: .asciz "Press number for music:\n1. Super Mario Bros Theme\n2. Tetris Theme\n3. We Wish You A Merry Christmas\n4. Megalovania (Undertale)\n0. Stop\n"
play_msg: .asciz "Playing song number "
new_line: .asciz "\n"
stop_msg: .asciz "Press 0 to stop playback\n"
stopped_msg: .asciz "Stopped playback\n\n"
invalid_press: .asciz "Invalid key press\n"

# ============================================================================
# SONG DATA - Format: pitch, duration, instrument, volume
# ============================================================================

# Song 1: Super Mario Bros Theme
song1:
	.word 76,150,1,127, 76,150,1,127, 76,300,1,127
	.word 72,150,1,127, 76,300,1,127, 79,600,1,127, 67,600,1,127
	.word 72,450,1,127, 67,450,1,127, 64,450,1,127
	.word 69,300,1,127, 71,300,1,127, 70,150,1,127, 69,300,1,127
	.word -1

# Song 2: Tetris Theme
song2:
	.word 76,400,1,127, 71,200,1,127, 72,200,1,127, 74,400,1,127, 72,200,1,127, 71,200,1,127
	.word 69,400,1,127, 69,200,1,127, 72,200,1,127, 76,400,1,127, 74,200,1,127, 72,200,1,127, 71,600,1,127
	.word 72,200,1,127, 74,400,1,127, 76,400,1,127, 72,400,1,127, 69,400,1,127, 69,400,1,127
	.word -1

# Song 3: We Wish You A Merry Christmas
song3:
	.word 60,500,26,127, 65,500,26,127, 65,250,26,127, 67,250,26,127, 65,250,26,127, 64,250,26,127, 62,500,26,127, 62,500,26,127
	.word 62,500,26,127, 67,500,26,127, 67,250,26,127, 69,250,26,127, 67,250,26,127, 65,250,26,127, 64,500,26,127, 60,500,26,127
	.word 60,500,26,127, 69,500,26,127, 69,250,26,127, 70,250,26,127, 69,250,26,127, 67,250,26,127, 65,500,26,127, 62,500,26,127
	.word 60,250,26,127, 60,250,26,127, 62,500,26,127, 67,500,26,127, 64,500,26,127, 65,1000,26,127
	.word -1

# Song 4: Megalovania (Undertale)
song4:
	.word 50,140,30,127, 50,140,30,127, 62,280,30,127, 57,280,30,127, 56,280,30,127, 55,280,30,127, 53,280,30,127, 50,140,30,127, 53,140,30,127, 55,140,30,127
	.word 48,140,30,127, 48,140,30,127, 62,280,30,127, 57,280,30,127, 56,280,30,127, 55,280,30,127, 53,280,30,127, 50,140,30,127, 53,140,30,127, 55,140,30,127
	.word 47,140,30,127, 47,140,30,127, 62,280,30,127, 57,280,30,127, 56,280,30,127, 55,280,30,127, 53,280,30,127, 50,140,30,127, 53,140,30,127, 55,140,30,127
	.word 46,140,30,127, 46,140,30,127, 62,280,30,127, 57,280,30,127, 56,280,30,127, 55,280,30,127, 53,280,30,127, 50,140,30,127, 53,140,30,127, 55,140,30,127
	.word -1

# ============================================================================
# MAIN PROGRAM
# ============================================================================

.text
main:
	# Initialize registers
	la s0, lookup_table
	li s1, 0                        # s1 = playing status (0=stopped, 1=playing)
	li t3, 0                        # t3 = current song pointer

	# Setup interrupt handler
	la t0, handler
	csrrs zero, utvec, t0
	
	li t1, 0x100
	csrrs zero, uie, t1
	csrrsi zero, ustatus, 1
	
	# Enable keyboard interrupt
	li t1, IN_ADDRESS_HEXA_KEYBOARD
	li t2, 0x80
	sb t2, 0(t1)
	
	# Print menu
	li a7, 4
	la a0, prompt_msg
	ecall

# ============================================================================
# MAIN LOOP
# ============================================================================

wait_loop:
	nop
	nop
	nop
	nop
	nop
	bgtz t3, play_loop              # If song loaded, start playing
	j wait_loop

play_loop:
	lw a7, 0(t3)                    # Load pitch
	bltz a7, song_end               # If -1, song ended

	# Play MIDI note
	li a7, 33                       # Syscall 33: MIDI out synchronous
	lw a0, 0(t3)                    # pitch
	lw a1, 4(t3)                    # duration
	lw a2, 8(t3)                    # instrument
	lw a3, 12(t3)                   # volume
	ecall
	
	addi t3, t3, 16                 # Advance to next note (4 words = 16 bytes)
	beqz s1, song_end               # If stopped by interrupt, end song
	j play_loop

song_end:
	# Print end message and menu
	li a7, 4
	la a0, stopped_msg
	ecall
	la a0, prompt_msg
	ecall
	
	# Reset state
	li t3, 0
	li s1, 0
	j wait_loop

# ============================================================================
# INTERRUPT HANDLER
# ============================================================================

handler:
	# Save registers
	addi sp, sp, -24
	sw a0, 0(sp)
	sw a7, 4(sp)
	sw s0, 8(sp)
	sw t1, 12(sp)
	sw t2, 16(sp)
	
	la s0, lookup_table             # Reset lookup table pointer
	
get_key_code:
	# Check row 1
	li t1, IN_ADDRESS_HEXA_KEYBOARD
	li t2, 0x81
	sb t2, 0(t1)
	li t1, OUT_ADDRESS_HEXA_KEYBOARD
	lb a0, 0(t1)
	bnez a0, got_key_code
	
	# Check row 2
	li t1, IN_ADDRESS_HEXA_KEYBOARD
	li t2, 0x82
	sb t2, 0(t1)
	li t1, OUT_ADDRESS_HEXA_KEYBOARD
	lb a0, 0(t1)
	bnez a0, got_key_code
	
	# Re-enable interrupt if no key found
	li t1, IN_ADDRESS_HEXA_KEYBOARD
	li t2, 0x80
	sb t2, 0(t1)
	j end_handler

got_key_code:
	# Search for key code in lookup table
search_loop:
	lw t1, 0(s0)
	beqz t1, invalid_key            # End of table, key not found
	beq t1, a0, found               # Key found
	addi s0, s0, 8                  # Move to next entry
	j search_loop

found:
	lw t2, 4(s0)                    # Get song address
	beqz t2, key_press_0            # If 0, it's the stop key
	
	# Load new song
	li s1, 1                        # Set playing status
	mv t3, t2                       # Load song pointer
	j end_handler

key_press_0:
	# Stop playback
	li s1, 0                        # Clear playing status
	li t3, 0                        # Clear song pointer
	j end_handler

invalid_key:
	# Do nothing for invalid keys
	j end_handler

end_handler:
	# Restore registers
	lw t2, 16(sp)
	lw t1, 12(sp)
	lw s0, 8(sp)
	lw a7, 4(sp)
	lw a0, 0(sp)
	addi sp, sp, 24
	uret
