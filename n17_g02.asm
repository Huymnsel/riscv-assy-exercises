.eqv IN_ADDRESS_HEXA_KEYBOARD 0xFFFF0012
.eqv OUT_ADDRESS_HEXA_KEYBOARD 0xffff0014
.data
lookup_table:
	.word 0x11, 0
	.word 0x21, song1
	.word 0x41, song2
	.word 0xffffff81, song3
	.word 0x12, song4
	.word 0, 0                      # End marker
	
	prompt_msg: .asciz "Press number for music:\n1. Super Mario Theme\n2. Littleroot Town\n3. Korobeiniki (Tetris theme)\n4. We wish you a Merry Christmas\n\n"
	new_line: .asciz "\n"
	stop_msg: .asciz "Press 0 to stop playback\n\n"
	stopped_msg: .asciz "Stopped playback\n\n"
	invalid_press: .asciz "Invalid key press\n"
	song1: .word 76,150,1,127, 76,150,1,127, 76,300,1,127 72,150,1,127, 76,300,1,127, 79,600,1,127, 67,600,1,127 72,450,1,127, 67,450,1,127, 64,450,1,127 69,300,1,127, 71,300,1,127, 70,150,1,127, 69,300,1,127, -1 # pitch dura instrument volume, pitch ...
	song2: .word 48,280,26,127, 53,280,26,127, 55,280,26,127, 57,841,26,127, 55,280,26,127, 57,280,26,127, 55,280,26,127, 57,280,26,127, 59,280,26,127, 60,841,26,127, 62,280,26,127, 57,561,26,127, 57,280,26,127, 61,280,26,127, 62,561,26,127, 64,561,26,127, 62,561,26,127, 57,280,26,127, 55,280,26,127, 53,280,26,127, 52,280,26,127, 53,280,26,127, 57,280,26,127, 62,561,26,127, 50,280,26,127, 52,280,26,127
	       .word 53,1121,26,127, 60,280,26,127, 59,280,26,127, 59,280,26,127, 57,280,26,127, 53,1122,26,127, 62,280,26,127, 57,280,26,127, 57,280,26,127, 55,280,26,127, 53,1682,26,127, 52,280,26,127, 50,280,26,127, 52,841,26,127, 53,280,26,127, 55,280,26,127, 48,280,26,127, 60,280,26,127, 59,280,26,127, 57,841,26,127, 55,280,26,127, 57,280,26,127, 55,280,26,127, 57,280,26,127, 59,280,26,127, 55,280,26,0, 60,561,26,127, 62,280,26,127, 57,280,26,127, 55,280,26,127, 57,280,26,127, 61,280,26,127
	       .word 62,561,26,127, 64,561,26,127, 65,561,26,127, 57,280,26,127, 55,280,26,127, 53,280,26,127, 52,280,26,127, 53,280,26,127, 57,280,26,127, 62,561,26,127, 50,280,26,127, 52,280,26,127, 53,1122,26,127, 60,280,26,127, 59,280,26,127, 59,280,26,127, 57,280,26,127, 53,1122,26,127, 62,280,26,127, 57,280,26,127, 57,280,26,127, 55,280,26,127, 53,1682,26,127, 52,280,26,127, 53,280,26,127, 55,841,26,127, 57,280,26,127, 59,561,26,127, 57,280,26,127, 59,280,26,127
	       .word 62,561,26,127, 60,561,26,127, 64,561,26,127, 59,561,26,127, 48,280,26,127, 47,280,26,127, 48,280,26,127, 57,280,26,127, 59,561,26,127, 57,561,26,127, -1
	song3:
		.word 76,400,1,127, 71,200,1,127, 72,200,1,127, 74,400,1,127, 72,200,1,127, 71,200,1,127
		.word 69,400,1,127, 69,200,1,127, 72,200,1,127, 76,400,1,127, 74,200,1,127, 72,200,1,127, 71,600,1,127
		.word 72,200,1,127, 74,400,1,127, 76,400,1,127, 72,400,1,127, 69,400,1,127, 69,400,1,127
		.word -1
	song4:
		.word 60,500,26,127, 65,500,26,127, 65,250,26,127, 67,250,26,127, 65,250,26,127, 64,250,26,127, 62,500,26,127, 62,500,26,127
		.word 62,500,26,127, 67,500,26,127, 67,250,26,127, 69,250,26,127, 67,250,26,127, 65,250,26,127, 64,500,26,127, 60,500,26,127
		.word 60,500,26,127, 69,500,26,127, 69,250,26,127, 70,250,26,127, 69,250,26,127, 67,250,26,127, 65,500,26,127, 62,500,26,127
		.word 60,250,26,127, 60,250,26,127, 62,500,26,127, 67,500,26,127, 64,500,26,127, 65,1000,26,127
		.word -1
	
.text
preparations: # (main) won't be re run again
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

wait_loop: # Main will just wait in wait loop until interrupt (1, 2, 3, 4)
	nop
	nop
	nop
	nop
	nop
	
	bgtz t3, prepare_play
	
	j wait_loop
prepare_play:
	li a7, 4
	la a0, stop_msg
	ecall

play_loop:
	lw a7, 0(t3)                    # Load pitch
	bltz a7, song_end               # If -1, song ended

	li a7, 33                       # Syscall 33: MIDI out synchronous
	lw a0, 0(t3)                    # pitch
	lw a1, 4(t3)                    # duration
	lw a2, 8(t3)                    # instrument
	lw a3, 12(t3)                   # volume
	ecall
	nop
	nop
	nop
	
	addi t3, t3, 16 # advance by 16 bytes (4 words)
	
	beqz s1, song_end # "playing" = 0 then end
	j play_loop

song_end:
	# Print end message and menu
	li a7, 4
	la a0, stopped_msg
	ecall
	li a7, 4
	la a0, prompt_msg
	ecall
	
	li t3, 0
	li s1, 0
	j wait_loop

handler: # Handle jumping to wait loop when press 0 (stop playback)
	 # Loading appropriate song data when others (1..4) then jump to play loop
	addi sp, sp, -24
	sw a0, 0(sp)
	sw a7, 4(sp)
	sw s0, 8(sp)
	sw t1, 12(sp)
	sw t2, 16(sp)
	
get_key_code:
	# Check row 1
	li t1, IN_ADDRESS_HEXA_KEYBOARD
	li t2, 0x81 # Check row 1 and re-enable bit 7
	sb t2, 0(t1)
	li t1, OUT_ADDRESS_HEXA_KEYBOARD
	lb a0, 0(t1)
	bnez a0, got_key_code
	
	# Check row 2
	li t1, IN_ADDRESS_HEXA_KEYBOARD
	li t2, 0x82 # Check row 2 and re-enable bit 7
	sb t2, 0(t1)
	li t1, OUT_ADDRESS_HEXA_KEYBOARD
	lb a0, 0(t1)
	bnez a0, got_key_code # (in a0)
	
got_key_code:
	# Search for key code in lookup table
search_loop:
	lw t1, 0(s0)
	beqz t1, invalid_key
	
	beq t1, a0, found # key code in a0 found in lookup table
	addi s0, s0, 8
	j search_loop

found:
	lw t2, 4(s0)
	beqz t2, key_press_0
	bnez s1, invalid_key
	
	# Load new song
	li s1, 1                        # Set playing status
	mv t3, t2                       # Load song pointer
	j end_handler
key_press_0:
	li s1, 0 # s1, playing status take 0
	j end_handler
invalid_key:
	li a7, 4
	la a0, invalid_press
	ecall

	j end_handler
end_handler:
	lw t2, 16(sp)
	lw t1, 12(sp)
	lw s0, 8(sp)
	lw a7, 4(sp)
	lw a0, 0(sp)
	addi sp, sp, 24
	uret
end:
