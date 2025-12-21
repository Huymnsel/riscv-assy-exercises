# Syntax checker for assembly instructions
.eqv KEY_CODE 0xffff0004 # ASCII code received from keyboard (stored in this 4 bytes)
.eqv KEY_READY 0xffff0000 # if has new keycode -> == 1
                          # auto unset after KEY_CODE got lw
                          
.eqv DISPLAY_CODE 0xffff000c # ASCII code to display
.eqv DISPLAY_READY 0xffff0008 # if == 0 -> gotta wait before sw into above DISPLAY_CODE
                              # auto unset when something is sw into ^^^

# for only RV321, Integer instructions (no mul, div, rem), syntacticly there are:
# basic formatting: ins followed by 2 or 3 fields separated by commas ,
# only lowercase, uppercase, number, round brackets, commas and _ for jump labels
# ^^^ constantly check with every keycode, along saving to a string

# <ins> register, 12bit-imm(register)
# load, store -> <ins> l.., s.
# imm in decimal (0 at start is OK) or hexadecimal
# crazy ins like: lw t1, 000000000000000010(t0)
#                 lw t1, -010(t0) -> all allowed, nice

# <ins> register, 20bit-imm
# specifically: lui and auipc
# example: lui t2, -010

# <ins> register, register, 12bit-imm
# addi, slti, sltiu, xori, ori, andi, jalr

# <ins> register, register, 5bit-imm
# slli, srli, srai

# <ins> register, register, register
# ALL and ONLY R-Types

# <ins> register, register, label
# ALL and ONLY B-Types

# jal register, label

.text
	li t0, KEY_CODE
	lw t1, -010(t0)
	lui t2, -010