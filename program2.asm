TITLE Program 2 - Fibonacci Sequence     (program2.asm)

; Author: Risto Keravuori
; Description: This program asks a user for their name and a number,
; and then displays that many terms in the Fibonacci sequence. It
; generates random colors for the display, validates that user input
; is in an appropriate range, and prints aligned columns of output.
; The program is also friendly to the user, greeting them by name
; and saying goodbye.

INCLUDE Irvine32.inc

;constants
MAX_RANGE = 46
NUM_PER_LINE = 5

.data

;strings
welcome		BYTE	"Fibonacci Sequence Generator by Risto Keravuori", 0
underline	BYTE	"-----------------------------------------------", 0
extra1		BYTE	"**EC1: Numbers are printed in aligned columns.", 0
extra2		BYTE	"**EC2: Program runs with a random foreground and background"
			BYTE	" color each time, is completely modularized into sub-routines,"
			BYTE	" and has different text if you only ask for a single term.", 0
namePrompt	BYTE	"What's your name? ", 0
greet1		BYTE	"Hi ", 0
greet2		BYTE	"!", 0
instruction	BYTE	"In order to generate a fibonacci sequence, I need to know how many"
			BYTE	" terms you want to see.", 0
badInput	BYTE	"I'm sorry, that was not valid input.", 0
badNumber	BYTE	"I'm sorry, that number was out of the acceptable range.", 0
numPrompt1	BYTE	"Please enter a number from 1 to ", 0
numPrompt2	BYTE	": ", 0
fibSingle	BYTE	"Just one, huh? Okay, well here is the first Fibonacci term:", 0
fibMulti1	BYTE	"Okay, here are the first ", 0
fibMulti2	BYTE	" Fibonacci terms:", 0
fibSpacer	BYTE	" ", 0
goodbye1	BYTE	"Well, ", 0
goodbye2	BYTE	", that was fun. Enjoy the rest of your day!", 0

;variables
userName	BYTE	36 DUP(0)
userNumber	BYTE	?

.code
main PROC

	call	RandomColors		;changes the foreground and background colors
	call	DisplayIntro		;display title and name
	call	MeetUser			;get user's name and greet them
	call	GetValidRange		;get validated number for range of terms
	call	DisplayFibSequence	;display fibonacci sequence
	call	DisplayGoodbye		;display goodbye message

	exit	; exit to operating system

main ENDP



;--------------------------------------------------------------
;RandomColors
;Sets the foreground and background to random colors!
;Foreground color is chosen from "light colors: 9-15
;Background color is chose from "dark" colors: 0-8
;--------------------------------------------------------------
RandomColors PROC

	call	Randomize		;seed random number generator

	;generate random foreground color from "light" colors
	mov		eax, 7
	call	RandomRange
	add		eax, 9		;add 9 to get in proper range
	mov		ebx, eax

	;generate random background color  from "dark" colors
	mov		eax, 9
	call	RandomRange
	shl		eax, 4		;shift left to put color in background "range"

	;combine background and foreground into single register
	add		eax, ebx
	call	SetTextColor
	ret

RandomColors ENDP



;--------------------------------------------------------------
;DisplayIntro
;Prints the requisite introductory lines to the screen
;--------------------------------------------------------------
DisplayIntro PROC

	mov		edx, OFFSET welcome
	call	WriteString
	call	CrLf
	mov		edx, OFFSET underline
	call	WriteString
	call	CrLf
	mov		edx, OFFSET extra1
	call	WriteString
	call	CrLf
	mov		edx, OFFSET extra2
	call	WriteString
	call	CrLf
	call	CrLf
	ret

DisplayIntro ENDP



;--------------------------------------------------------------
;MeetUser
;Gets the users name and greets them
;Returns:
;userName = user's name as a string
;--------------------------------------------------------------
MeetUser PROC

	;get user's name
	mov		edx, OFFSET namePrompt
	call	WriteString
	mov		edx, OFFSET userName
	mov		ecx, SIZEOF userName
	call	ReadString

	;greet user
	mov		edx, OFFSET greet1
	call	WriteString
	mov		edx, OFFSET userName
	call	WriteString
	mov		edx, OFFSET greet2
	call	WriteString
	call	CrLf
	call	CrLf
	ret

MeetUser ENDP



;--------------------------------------------------------------
;GetValidRange
;Gets a valid number for the range of fib terms to be displayed
;Upper range is set by MAX_RANGE constant
;Returns:
;EAX = user's range choice in register
;userNumber = user's range choice in memory
;--------------------------------------------------------------
GetValidRange PROC

	;display instructions
	mov		edx, OFFSET instruction
	call	WriteString
	call	CrLf
	jmp		LGetNumber

LBadInput:		;non-numeric input message
	mov		edx, OFFSET badInput
	call	WriteString
	call	CrLf
	jmp		LGetNumber

LBadNumber:		;number too big message
	mov		edx, OFFSET badNumber
	call	WriteString
	call	CrLf
	jmp		LGetNumber

LGetNumber:
	mov		edx, OFFSET numPrompt1
	call	WriteString
	mov		eax, MAX_RANGE
	call	WriteDec
	mov		edx, OFFSET numPrompt2
	call	WriteString
	call	ReadDec

	;validate input and loop until valid
	cmp		eax, 0			;eax set to 0 for bad input
							;also when 0 entered, but still works
							;CF (as per Irvine docs) was not getting set for me on bad input
	jz		LBadInput
	cmp		eax, MAX_RANGE	;ensure within range
	ja		LBadNumber
	mov		userNumber, al	;store for later reference
	call	CrLf
	ret

GetValidRange ENDP



;--------------------------------------------------------------
;DisplayFibSequence
;Displays the Fibonacci sequence up to the desired number of terms
;Includes different message for singular and multiple terms
;--------------------------------------------------------------
DisplayFibSequence PROC

	;determine if more than a single term desired
	cmp		eax, 1
	je		LFibSingle
	jne		LFibMulti

	;display single term intro
LFibSingle:
	mov		edx, OFFSET FibSingle
	call	WriteString
	call	CrLf
	jmp		LFibStart

	;display multiple-term intro
LFibMulti:
	mov		edx, OFFSET FibMulti1
	call	WriteString
	call	WriteDec	;eax still stores user's choice
	mov		edx, OFFSET FibMulti2
	call	WriteString
	call	CrLf
	jmp		LFibStart

	;set up generator loop
LFibStart:
	mov		ecx, eax				;eax still stores user's choice
	mov		eax, 1					;first term
	mov		ebx, 0
	mov		edx, OFFSET fibSpacer	;store whitespace character

	;calculate and display terms
LFibGen:
	cmp		ecx, NUM_PER_LINE
	jna		LFIbLastLine
	push	ecx
	mov		ecx, NUM_PER_LINE
	call	FibLinePrint
	pop		ecx
	sub		ecx, (NUM_PER_LINE-1)	;loop will decrement also
	loop	LFibGen

LFibLastLine:
	call	FibLinePrint
	call	CrLf
	ret

DisplayFibSequence ENDP



;--------------------------------------------------------------
;FibLinePrint
;Print out lines of fib terms with up to NUM_PER_LINE terms
;Receives:
;EAX = Highest calculated fib term thus far
;EBX = 2nd highest fib term thus far
;Returns:
;EAX = Highest calculated fib term in subrountine
;EBX = 2nd highest fib term in subrountine
;--------------------------------------------------------------
FibLinePrint PROC

	mov		esi, 9				;max padding needed for single-digit numbers

LTermPrinter:
	call	FibPaddingPrinter	;print padding and fib term
	call	WriteDec
	add		ebx, eax			;calculate next fib term
	xchg	ebx, eax
	mov		esi, 14				;max padding plus 5 space boundary between columns
	loop	LTermPrinter
	call	CrLf
	ret

FibLinePrint ENDP



;--------------------------------------------------------------
;FibPaddingPrinter
;Left-padds fib terms with leading whitespace
;Receives:
;ESI = max number of whitespace characters to print
;EAX = number in need of padding
;--------------------------------------------------------------
FibPaddingPrinter PROC USES ecx

	;determine amount of padding needed
	;decrement ecx for each power of ten
	mov		ecx, esi
	cmp		eax, 10
	jb		LSpacePrinter
	dec		ecx
	cmp		eax, 100
	jb		LSpacePrinter
	dec		ecx
	cmp		eax, 1000
	jb		LSpacePrinter
	dec		ecx
	cmp		eax, 10000
	jb		LSpacePrinter
	dec		ecx
	cmp		eax, 100000
	jb		LSpacePrinter
	dec		ecx
	cmp		eax, 1000000
	jb		LSpacePrinter
	dec		ecx
	cmp		eax, 10000000
	jb		LSpacePrinter
	dec		ecx
	cmp		eax, 100000000
	jb		LSpacePrinter
	dec		ecx
	cmp		eax, 1000000000
	jb		LSpacePrinter
	dec		ecx
	cmp		ecx, 0
	jz		LEnd	;no zero padding needed, exit

	;print padding
LSpacePrinter:
	call	WriteString
	loop	LSpacePrinter

LEnd:
	ret

FibPaddingPrinter ENDP



;--------------------------------------------------------------
;DisplayGoodbye
;Print goodbye message to the screen
;--------------------------------------------------------------
DisplayGoodbye PROC

	;parting message with user name
	mov		edx, OFFSET goodbye1
	call	WriteString
	mov		edx, OFFSET userName
	call	WriteString
	mov		edx, OFFSET goodbye2
	call	WriteString
	call	CrLf
	ret

DisplayGoodbye ENDP

END main
