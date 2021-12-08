; Name:       Kiril Sikov
; Email:      ksiko870@mtroyal.ca
;
; Purpose: The purpose of this subfile is to handle all
; IO within the program. In practice, this is the keyboard input
; and the printing of either the result or an error.
;
; Details: The file reads and writes to/from the console. For the former,
; it waits for a user to input either operands (+,-,=) or digit inputs (0-9)
; and them processes them according to the subroutine.
;
; input: Keyboard input
; output: an up to seven digit number, with a potential minus sign
; before it to signify a negative number. Alternatively, an error message
; will print if the number input is too large, an invalid operator occours or
; the sum of the two values put in result in an overflow.
;
; Program Status:
;	-Full implamentation of input (+ and -)
;	-Null terminated string writing functional
;	-Partial implamentation of SM number printing
;	-Full implamentation of operand reading and operation.
; NOTE:	I chose to make - (minus) act as a number within
;	the program. As a result, it is not considered an
;	operand.
; What needs to be implamented:
;	-more error handling.
; Bugs:
;	-Not known at this time.
; Register Purpose:
;	d0: Used to read/write a character to screen
;	d1: Used to denote that a negative number has been used.
;	If the user then puts a space, the program will return an
;	error.
;	d2: Used in read operand to determine if the subroutine looks
;	for a plus sign or an equals sign.
;	d4: Used as a test bit for processing whitespace.
;	0 means non-whitespace, while 1 means whitespace detected, but
;	to keep going with reading more input. 2 means whitespace detected and
;	to end input reading.
;	d6: The input number, stored in hex
;	a5: Also not a register, but gets used to save d0 when the subfile exits use.
;	number or the result from the SM addition
SPACE		equ     32	;ASCII value for space
LINELEN		equ	80
CR		equ	13	;ASCII value for Carriage return
LF		equ	10	;ASCII value for Linefeed
PLUS		equ	43	;ASCII value for "+"
MINUS		equ	45	;ASCII value for "-"
EQUALS		equ	61	;ASCII value for "+"
ZERO:		equ	'0'	;ASCII value for "0"
NINE		equ	'9'	;ASCII value for "9"
NULL		equ	0	;Null terminator
BACKSPACE	equ	8	;ASCII value for backspace

SM_DIGIT	equ	7	;Offset holding the SM digit
SIZE		equ	8	;Offset holding the number size
NUMLEN		equ	9	;Size of the number
;----- SUBROUTINE: read_line -----
;
; PURPOSE: Reads a line from keyboard input until whitespace occours
; past digits or invalid input occours
;
; CALLER INPUT: Fills a5 with a longword result from the input
;
; E.G. CALL:	lea	longword,a5
;		jsr	read_line
read_line:	movem.l	d0-d7,-(sp)
read_lp:	cmp.b	#8,d3
		bne	cont_loop
		movem.l	(sp)+,d0-d7
		move.b	#-1,d0
		jmp	read_exit
cont_loop:	clr.b	d4
		jsr	read_char
		jsr	skp_whitespace
		
		cmp.l	#1,d4		;checks to see if the
		beq	lp_end		;whitespace should end
		cmp.l	#2,d4		;the line reading
		beq	lp_done

		jsr	check_negative
		cmp.b	#MINUS,d0
		bne	lp_inc
		jmp	lp_end

lp_inc:		sub.b	#ZERO,d0
		jsr	get_newval
		add.b	#1,d3
lp_end:		jmp	read_lp
lp_done:	move.b	d3,SIZE(a5)
		movem.l	(sp)+,d0-d7
read_exit:	rts

check_negative:	cmp.b	#MINUS,d0
		beq	turn_negative
		jmp	check_done
turn_negative:	move.b	#7,d3
		jsr	get_newval
		move.b	#0,d3
check_done:	rts


;----- SUBROUTINE: skp_whitespace -----
;
; PURPOSE: The subroutine serves to process whitespace and depending on
; previous input it will either set to continue reading or to stop reading
; alltogether. The function does not modify any values.
;
; CALLER INPUT: takes the ASCII value of the character in the low byte
;               of D0.
;
; E.G. CALL:	jsr	read_char
;		jsr	skp_whitespace
skp_whitespace:	cmp.b	#SPACE,d0
		beq	skp_or_end
		cmp.b	#BACKSPACE,d0
		beq	backspace_hdle
		cmp.b	#CR,d0
		beq	end_reading
		jmp	exit
skp_or_end:	tst.l	d6
		bne	end_reading
		move.b	#1,d4
		jmp	exit
backspace_hdle:	sub.b	#1,d3
		clr.b	(a5)
		move.b	#1,d4
		jmp	exit
end_reading:	move.b	#2,d4
exit:		rts

;----- SUBROUTINE: get_newval -----
;
; PURPOSE: Assuming a digit character, the function subracts the ASCII value
; of zero to get the actual value of the number (i.e. '0'- 0 -> 0) and then
; multiplies d6 by ten. Finally, it adds the Low order byte of d0 to d6.
;
; CALLER INPUT: takes the ASCII value of the character in the low byte
;               of D0.
;
; E.G. CALL:	jsr	read_char
;		jsr	get_newval
get_newval:	movem.l	d1-d3/a5,-(sp)
loop_to_val:	tst.b	d3
		beq	val_insert
		move.b	(a5)+,d1
		sub.b	#1,d3
		jmp	loop_to_val
val_insert:	move.b	d0,(a5)		
newval_done:	movem.l	(sp)+,d1-d3/a5
		rts

;----- SUBROUTINE: read_char -----
;
; PURPOSE: waits for and reads a single keystroke from the keyboard.
;
; NOTE: This function is taken from the A3 assignment. It is also slightly
;	modified to deal with the high order bytes, leaving just the character
;	input by the keyboard.
;
; CALLER OUTPUT: returns the ASCII value of the key in the low byte
;                of D0.
;
read_char:	movem.l	d1-d2/a0-a2,-(sp)
		move.w	#1,-(sp)
		trap	#1
		and.l	#$FF,d0
		addq.l	#2,sp
		movem.l	(sp)+,d1-d2/a0-a2
		rts

;----- SUBROUTINE: read_operand -----
;
; PURPOSE: The function looks for either a plus or equals sign. If found,
; it returns 1 in d0. If an invalid operator appears, -1 gets returned.
;
; CALLER INPUT: d2 holds wether the function searches for plus or equals
;
read_operand:	clr.l	d0
read_loop:	jsr	read_char
		cmp.b	#SPACE,d0
		beq	read_loop
		cmp.b	#CR,d0
		beq	end_line_read
		jmp	read_operator
end_line_read:	move.b	#-1,d0
		jmp	loop_done

;----- SUBROUTINE: read_operator -----
;
; PURPOSE: Finds Plus, equals or an invalid operator
;
; CALLER INPUT: d2 holds wether the function searches for plus or equals
;
;
read_operator:	tst.b	d2
		beq	plus_read
equal_read:	cmp.b	#EQUALS,d0
		beq	op_loc
		jmp	inval_op
plus_read	cmp.b	#PLUS,d0
		beq	op_loc
inval_op:	move.l	#0,d0
		jmp	loop_done
op_loc:		move.l	#1,d0
loop_done:	rts

;----- SUBROUTINE: printf -----
;
; PURPOSE: Writes a null terminated string to the console
;
; CALLER OUTPUT: The input string output to the console
;		
;		lea	some_str,a1
; E.G. CALL:	jsr	printf
printf:		movem.l	d0/a1,-(sp)
print_str:	move.b	(a1)+,d0
		jsr	scrn_write
		tst.b	d0
		bne	print_str
		movem.l	(sp)+,d0/a1
		rts

;----- SUBROUTINE: newline -----
;
; PURPOSE: Writes the enter keystroke to console
;
; CALLER OUTPUT: newline in console
;		
;		jsr	write_something
; E.G. CALL:	jsr	printf
newline:	movem.l	d0-d3/a0-a3,-(sp)	
		move.b	#CR,d0
		jsr	scrn_write
		move.b	#LF,d0
		jsr	scrn_write
		movem.l	(sp)+,d0-d3/a0-a3
		rts

;----- SUBROUTINE: print_SM -----
;
; PURPOSE: Writes a SM number on its own line in the console
;
; CALLER OUTPUT: SM number on its own line in the console
;		
;		jsr	write_something
; E.G. CALL:	jsr	printf
print_SM:	movem.l	d1/a6,-(sp)
		move.b	SIZE(a6),d1
		move.b	SM_DIGIT(a6),d0
		cmp.b	#MINUS,d0
		beq	print_sign
print_num:	tst.b	d1
		beq	done_SM
		move.b	(a6)+,d0
		add.b	#ZERO,d0
		jsr	scrn_write
		sub.b	#1,d1
		jmp	print_num
print_sign:	jsr	scrn_write
		clr.b	d0
		jmp	print_num
done_SM:	movem.l	(sp)+,d1/a6
		rts

;----- SUBROUTINE: scrn_write -----
;
; PURPOSE: writes a single character to the screen.
;
; NOTE: Like the read_char function, this was also taken from A3.
;
; CALLER INPUT: takes the ASCII value of the character in the low byte
;               of D0.
;
; E.G. CALL:	move.b	#'a',d0
;		jsr	write_char
scrn_write:	movem.l	d0-d2/a0-a2,-(sp)
		and.l	#$FF,d0
		move.w	d0,-(sp)
		move.w	#2,-(sp)
		trap	#1
		addq.l	#4,sp
		movem.l	(sp)+,d0-d2/a0-a2
		rts

; ---- RUN TIME ----
NUMBER:		ds.b	NUMLEN