.eqv IN_ADDRESS_HEXA_KEYBOARD 0xFFFF0012
.eqv OUT_ADDRESS_HEXA_KEYBOARD 0xffff0014
.data
lookup_table:
	.word 0x11, 0
	.word 0x21, song1
	.word 0x41, song2
	.word 0xffffff81, song3
	.word 0x12, song4
	# .word 0x22, 0
	# .word 0x42, 0
	# .word 0x82, 0
	.word 0, 0 # end marker
	
	prompt_msg: .asciz "Press number for music:\n1. Littleroot Town\n"
	play_msg: .asciz "Playing song number "
	new_line: .asciz "\n"
	stop_msg: .asciz "Press 0 to stop playback\n"
	stopped_msg: .asciz "Stopped playback\n\n"
	invalid_press: .asciz "Invalid key press\n"
	song1: .word # pitch dura instrument volume, pitch ...
	song2: .word 48,280,26,127, 53,280,26,127, 55,280,26,127, 57,841,26,127, 55,280,26,127, 57,280,26,127, 55,280,26,127, 57,280,26,127, 59,280,26,127, 60,841,26,127, 62,280,26,127, 57,561,26,127, 57,280,26,127, 61,280,26,127, 62,561,26,127, 64,561,26,127, 62,561,26,127, 57,280,26,127, 55,280,26,127, 53,280,26,127, 52,280,26,127, 53,280,26,127, 57,280,26,127, 62,561,26,127, 50,280,26,127, 52,280,26,127, -1
	song3: .word 53,1121,26,127, 60,280,26,127, 59,280,26,127, 59,280,26,127, 57,280,26,127, 53,1122,26,127, 62,280,26,127, 57,280,26,127, 57,280,26,127, 55,280,26,127, 53,1682,26,127, 52,280,26,127, 50,280,26,127, 52,841,26,127, 53,280,26,127, 55,280,26,127, 48,280,26,127, 60,280,26,127, 59,280,26,127, 57,841,26,127, 55,280,26,127, 57,280,26,127, 55,280,26,127, 57,280,26,127, 59,280,26,127, 55,280,26,0, 60,561,26,127, 62,280,26,127, 57,280,26,127, 55,280,26,127, 57,280,26,127, 61,280,26,127, -1
	song4: .word 62,561,26,127, 60,561,26,127, 64,561,26,127, 59,561,26,127, 48,280,26,127, 47,280,26,127, 48,280,26,127, 57,280,26,127, 59,561,26,127, 57,561,26,127, -1
	
.text
preparations: # (main) won't be re run again
	la s0, lookup_table
	li s1, 0 # "playing" status

	la t0, handler
	csrrs zero, utvec, t0
	
	li t1, 0x100
	csrrs zero, uie, t1
	csrrsi zero, ustatus, 1
	
	li t1, IN_ADDRESS_HEXA_KEYBOARD
	li t3, 0x80
	sb t3, 0(t1) # Just setting up interrupt
	
	li a7, 4
	la a0, prompt_msg
	ecall
	li t3, 0
	
wait_loop: # Main will just wait in wait loop until interrupt (1, 2, 3, 4)
	nop
	nop
	nop
	nop
	nop
	#li a7, 32
	#li a0, 1000
	#ecall # syscall 32 sleep, 1000ms
	
	bgtz t3, play_loop
	
	j wait_loop
	#beqz x0, wait_loop

play_loop: # While playing wait for keypress
	lw a7, 0(t3)
	bltz a7, song_end

	li a7, 33 # 33 is MIDI wait, 31 not wait
	lw a0, 0(t3) # pitch
	lw a1, 4(t3) # dura
	lw a2, 8(t3) # instrument
	lw a3, 12(t3) # volume
	ecall
	
	nop
	nop
	nop
	
	addi t3, t3, 16 # advance by 16 bytes (4 words)
	
	beqz s1, song_end # "playing" = 0 then end
	beqz x0, play_loop

song_end:
	li a7, 4
	la a0, stopped_msg
	ecall
	li a7, 4
	la a0, prompt_msg
	ecall
	
	li t3, 0
	li s1, 0
	beqz x0, wait_loop

handler: # Handle jumping to wait loop when press 0 (stop playback)
	 # Loading appropriate song data when others (1..4) then jump to play loop
	addi sp, sp, -20
	sw a0, 0(sp)
	sw a7, 4(sp)
	sw s0, 8(sp)
	sw t1, 16(sp)
	sw t2, 20(sp)
	
get_key_code:
	li t1, IN_ADDRESS_HEXA_KEYBOARD
	li t2, 0x81 # Check row 1 and re-enable bit 7
	sb t2, 0(t1)
	li t1, OUT_ADDRESS_HEXA_KEYBOARD
	lb a0, 0(t1)
	bnez a0, got_key_code
	
	li t1, IN_ADDRESS_HEXA_KEYBOARD
	li t2, 0x82 # Check row 2 and re-enable bit 7
	sb t2, 0(t1)
	li t1, OUT_ADDRESS_HEXA_KEYBOARD
	lb a0, 0(t1)
	bnez a0, got_key_code # (in a0)
	
got_key_code:
search_loop: # first, search in table
	lw t1, 0(s0)
	beqz t1, invalid_key
	
	beq t1, a0, found # key code in a0 found in lookup table
	addi s0, s0, 8
	j search_loop
	#beq x0, x0, search_loop
found:
	lw t2, 4(s0)
	beqz t2, key_press_0
	bnez s1, invalid_key # TODO make logic for pressing 1, 2, 3, 4 while playing
	
	li s1, 1 # "playing" status to 1
	mv t3, t2 # t3 will be used in playback loop
	
	j end_handler
key_press_0:
	mv s1, t2 # s1 take 0
	j end_handler
invalid_key: # TODO notify invalid key press
	li a7, 4
	la a0, invalid_press
	ecall
end_handler:
	lw t2, 20(sp)
	lw t1, 16(sp)
	lw s0, 8(sp)
	lw a7, 4(sp)
	lw a0, 0(sp)
	addi sp, sp, 20
	
	uret
end:
