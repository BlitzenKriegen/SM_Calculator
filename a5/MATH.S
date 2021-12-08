; Name:       Kiril Sikov
; Email:      ksiko870@mtroyal.ca
;
; Purpose: The purpose of this subfile is to handle the SM
; addition within the total program. 
;
; Details: The file reads in two SM numbers and then evaluates them
; based off their sign. After that, it goes to add them together.
;
; input: Two SM numbers.
; output: A SM number that results from the sum of the input. Alternatively, an error message
; will print if the sum of the two values put in result in an overflow.
;
; Program Status:
;	-Two positive numbers working, with overflow
;	-Sum is returned to main program.
; What needs to be implamented:
;	-SIZE implamentation for the sum number in a6
;	-more error handling.
; Bugs:
;	-Overflow handling sometimes goes wrong.
;	-Printing numbers when the input have opposite signs is almost
;	certainly having an additional zero. This is because I cannot think
;	of a way to implament size functionally to the result stored in a6.
; Register Purpose:
;	d0: SM number, resulting from the addition of d1 and d2.
;	d1: First SM input number
;	d2: Second SM input number
;	d3: SM digit of first input number
;	d4: SM digit of second input number
;	d5: Used as an incrament for adding the two
;	SM numbers.
;	a5: Also not a register, but gets used to save d0 when the subfile exits use.
;	number or the result from the SM addition
NULL		equ	0	;Null terminator
LASTDIGIT	equ	6	
SM_DIGIT	equ	7	;MS Digit
SIZE		equ	8
NUMLEN		equ	9
MINUS		equ	'-'	;ASCII value of -
;----- SUBROUTINE: add_num -----
;
; PURPOSE: acts as the main function of the subfile. processes the numbers,
; and then obtains the result to send back to the main program.
;
; CALLER INPUT: Takes to numbers that were placed in a4-a5
; CALLER OUTPUT:Placed in a6
;
;		jsr	add_num

add_num:	movem.l	d0-d7/a0-a2,-(sp)			
		jsr 	check_sign
		lea	number,a6
		
		add.b	d4,d3		;sees if the SM digits
		tst.b	d3		;are the same. If so, do
		beq	same_sign	;regular adding. If not,
		cmp.b	#2,d3		;do SM with different signs
		beq	same_sign

		jsr	find_bigger
		tst.b	d0
		beq	cancel
		cmp.b	#-1,d0
		beq	direct
		
		move.l	a5,d0
		move.l	a4,d1
		movea.l	d0,a4
		movea.l	d1,a5
		jsr	add_different
		jmp	cancel
direct:		jsr	add_different
cancel:		movem.l (sp)+,d0-d7/a0-a2
		jmp	done_math
		;SM subtraction

same_sign:	jsr	pure_add
		movem.l	(sp)+,d0-d7/a0-a2
done_math:	rts

;----- SUBROUTINE: add_different -----
;
; PURPOSE: "Adds" two numbers together with opposing SM signs.
; Note that the number in a4 is always the larger number in absolute
; value, so a4's sign is the one that gets applied to the result in a6.
;
; CALLER INPUT: Takes to numbers that were placed in a4-a5
; CALLER OUTPUT:Placed in a6
;
;		jsr	add_num
add_different:	movem.l	d0-d2/a0-a6,-(sp)
		move.b	#LASTDIGIT-1,d3
sub_loop:	tst.b	d3
		beq	diff_add_done
		move.b	(a4)+,d1
		move.b	(a5)+,d2
		cmp.b	d1,d2
		bhi	carry_sub
sub:		sub.b	d2,d1
		move.b	d1,(a6)+
		sub.b	#1,d3
		jmp	sub_loop

carry_sub:	add.b	#10,d1
		sub.b	#1,1(a4)
		jmp	sub
diff_add_done:	movem.l	(sp)+,d0-d2/a0-a6		
		move.b	SIZE(a4),d0		;temp, fix later
		move.b	d0,SIZE(a6)

		move.b	SM_DIGIT(a4),d0
		move.b	d0,SM_DIGIT(a6)
		rts

;----- SUBROUTINE: find_bigger -----
;
; PURPOSE: In the event that the signs do not match, this
; function determines which SM number is is "greater". In this
; context, greater means a larger value if the number was absolute
; value.
;
; CALLER INPUT: Takes two numbers from a4-a5.
; CALLER OUTPUT: -1 if the second number is greater, 0 if the
; numbers are the same. 1 if the first number is greater. This
; gets stored in d0.
;
; E.G. CALL:	move.l	#dn,-(a6)
;		move.l	#dn2,-(a6)
;		jsr	add_num
find_bigger:	movem.l	d1-d3/a4-a5,-(sp)
		lea	LASTDIGIT(a4),a4
		move.b	(a4),d1
		lea	LASTDIGIT(a5),a5
		move.b	(a5),d2
		move.b	#7,d3
big_loop:	tst.b	d3
		beq	num_same	;evaluates if d1 or d2 is higher.
		cmp.b	d1,d2		;if they reach the end of the number without
		beq	big_next	;finding it, the numbers are the same.
		cmp.b	d2,d1
		bhi	first_higher

second_higher:	move.b	#1,d0
		jmp	bigger_exit
first_higher:	move.b	#-1,d0
		jmp	bigger_exit

num_same:	clr.b	d0
		jmp	bigger_exit
big_next:	move.b	-(a4),d1
		move.b	-(a5),d2
		sub.b	#1,d3
		jmp	big_loop

bigger_exit:	movem.l	(sp)+,d1-d3/a4-a5
		rts

;----- SUBROUTINE: pure_add -----
;
; Purpose: Adds two same sign numbers together and checks if they result
; in an overflow.
;
; Input: Two SM numbers.
; Output: Sum of the input.
pure_add:	clr.l	d0
		clr.l	d7
		move.b	#7,d5
		movem.l	a4-a6,-(sp)
		clr.l	d7
add_lp:		cmp.b	#0,d5
		beq	add_done
		move.b	(a5)+,d0
		add.b	(a4)+,d0
		jsr	overflow
		
		tst.b	d0
		bne	inc_size
sm_add		add.b	d0,(a6)+
		add.b	d1,(a6)
		sub.b	#1,d5
		jmp	add_lp
inc_size:	add.b	#1,d7
		jmp	sm_add
add_done:	movem.l	(sp)+,a4-a6
		tst.b	d1
		beq	no_overflow
		jmp	ovflw_fnd
no_overflow:	move.b	SM_DIGIT(a5),d0
		move.b	d0,SM_DIGIT(a6)
		move.b	d7,SIZE(a6)
		jmp	add_exit
ovflw_add:	move.b	#-1,d0
add_exit:	rts

;----- SUBROUTINE: overflow -----
;
; Purpose: Handles if and when a overflow (byte is greater
; than 9) occours in the sumed SM number stored in a6
;
; Input: SM digit in a6
; Output: nominal value in d0, carry (if it occours) in d1
overflow:	cmp.b	#9,d0
		bhi	ovflw_fnd
		jmp	done_overflow
ovflw_fnd:	move.b	#1,d1
		sub.b	#10,d0
done_overflow:	rts
;----- SUBROUTINE: check_sign -----
;
; PURPOSE: checks the sign of an input to see if it is positive or negative
; by looking at the MS bit.
;
; CALLER INPUT: Takes a number that was placed in a6
;
; E.G. CALL:
;		jsr	check_sum
check_sign:	cmp.b	#MINUS,SM_DIGIT(a4)
		beq	first_negative
		clr.l	d3
		jmp	check_second
first_negative:	move.l	#1,d3
check_second:	cmp.b	#MINUS,SM_DIGIT(a5)
		beq	second_neg
		clr.l	d4
		jmp	done_check
second_neg:	move.l	#1,d4
done_check:	rts

; ---- RUN TIME ----
number:		ds.b	NUMLEN
ovflw:	dc.b	"The input numbers result in an overflow.",NULL			