; Name:       Kiril Sikov
; Email:      ksiko870@mtroyal.ca
;
; Purpose: The purpose of this program is to add two
; signed magnitude numbers given by the user and to then
; print out the results.
;
; Details: The program begins by waiting for an input by
; the user. The input expected from the user is either an
; operand like +, - (this being before a number) and a digit
; input. Numbers can be up to seven digits long, as the eigth
; serves to define a positive or negative number. The program would
; then go and add the numbers together, before printing out the result
; in signed magnitude.
;
; input: Keyboard input
; output: an up to seven digit number, with a potential minus sign
; before it to signify a negative number. Alternatively, an error message
; will print if the number input is too large, an invalid operator occours or
; the sum of the two values put in result in an overflow.
;
; Program Status:
;	-Implamenation of number input sans - input
;	-Number addition with matching SM digits working, with overflow
;	detection
;	-Partial backspace implamentation
; What needs to be implamented:
;	-Implamentation of signed magnitude into input
;	-Equals operand functionality (= input working)
;	-printing of the result of the SM addition.
;	-consecutive backspaces work
; Limitations:
;	-The program assumes that the user does not place a space between
;	declaring a negative number and the start of writing digits.
;	-The program assumes that the user does not delete a - sign.
;	-The program does not use the 80 character limit, as the
;	implamentation of skp_whitespace makes it unnecissary. 
; Bugs:
;	-Occationally, the program yields a "file too large" on assembly.
; Register Purpose:
;	d0: Used to determine if the program should continue or
;	send out an error message and terminate
;	a5: Not a register, but this gets used to store a "number", 
;	such as the keyboard input number or the result from the SM addition. The
;	first input gets transfered to a4, and together they create the sum
;	in a6.
NULL		equ	0	;NULL terminator
NUM_SZ		equ	9

		xref	read_line
		xref	printf
		xref	add_num
		xref	newline
		xref	read_operand
		xref	print_SM
;----- SUBROUTINE: main -----
;
; PURPOSE: This is the main method. It calls all other
; routines in the program. 
;
main:		lea	num1,a5		
		jsr	read_line		;Gets the first number and places it in a4
		cmp.b	#-1,d0
		beq	num_err
num1_done:	lea	num1,a4
		jsr	p_search
		lea	num2,a5
		jsr	read_line
num2_done:	jsr	find_equal
		jsr	add
adding_done:	jsr	prog_done

;----- SUBROUTINE: num_error -----
;
; PURPOSE: The subroutine throws the "too many elements"
; error onto the screen.
;
; E.G. CALL:	jsr	read_line
;		jsr	num_error
num_err:	jsr	newline
		lea	inval_size,a1
		jsr	printf
		jsr	newline
		jmp	prog_done

;----- SUBROUTINE: p_search -----
;
; PURPOSE: Reads whitespace until the user puts in a plus sign.
; If they do ano ther sign, the program throws an "undefined operand"
; error to the console.
;
; CALLER INPUT: keyboard input.
; CALLER OUTPUT: plus sign ('+') or error message to console.
;	
p_search:	move.l	d0,-(sp)
seek_plus:	jsr	newline
		jsr	read_operand
		jsr	op_logic
		cmp.b	#1,d0
		beq	plus_found
		jmp	seek_plus
plus_found:	jsr	newline
		move.l	(sp)+,d0
		rts

;----- SUBROUTINE: find_equal -----
;
; PURPOSE: Reads whitespace until the user puts in an equals sign.
; If they do any other sign, an error will print to screen and end
; the program.
;
; CALLER INPUT: keyboard input.
; CALLER OUTPUT: plus sign ('=') or error message to console.
;	
find_equal:	move.l	d0,-(sp)
		move.b	#1,d2
seek_equals:	jsr	newline
		jsr	read_operand
		tst.b	d0
		beq	op_error		
		cmp.b	#1,d0
		beq	equal_found
		jmp	seek_equals
equal_found:	move.l	(sp)+,d0
		rts

;----- SUBROUTINE: add -----
;
; PURPOSE: The subroutine adds two SM numbers stored in a4 and a5
; and then stores the result in a6. Then, it prints the SM number
; stored in a6.
;
; CALLER INPUT: SM numbers in a4 and a5
; CALLER OUTPUT: SM number in a6 to screen
;	
add:		jsr	add_num			;Adds the numbers together and places them in a6.
		jsr	newline
		jsr	print_SM		;Then, prints the result
		jsr	newline
		jmp	fn
too_large:	lea	add_ovflw,a1
		jsr	printf
		jsr	newline
fn:		rts

;----- SUBROUTINE: op_logic -----
;
; PURPOSE: The subroutine runs the logic of finding plus/equals,
; to shrink their respective subroutines.
;
; CALLER INPUT: low order byte of d0
; CALLER OUTPUT: Error to screen or = sign.
;	
op_logic:	tst.b	d0 
		beq	op_error
		cmp.b	#-1,d0
		beq	return_loop
return_loop:	rts
op_error:	lea	inval_oprnd,a1
		jsr	newline
		jsr	printf
		jmp	prog_done

;----- SUBROUTINE: prog_done -----
;
; PURPOSE: Ends the program from running
;	
prog_done:	clr.w	-(sp)
		trap	#1

; ---- RUN TIME ----
num1:		ds.b	NUM_SZ
num2:		ds.b	NUM_SZ
inval_size:	dc.b	"The number input was too large.",NULL
inval_oprnd:	dc.b	"Invalid operator encountered, processing terminated.",NULL
add_ovflw	dc.b	"The sum of input numbers result in overflow.",NULL