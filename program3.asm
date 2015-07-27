TITLE Program 3 - Integer Accumulator     (program3.asm)

; Author: Risto Keravuori
; Description: This program prompts the user to enter multiple
; negative numbers in the range [LOWER_LIMIT, -1] (where
; LOWER_LIMIT is currently set to -100). After the user enters
; input that is not a negative number, the program shows the
; number of valid terms input (numbers less than -100 prompt
; re-entry), the sum of all the valid terms, and the average
; both as an integer (rounding half-up) and as a float to
; three decimal places.

INCLUDE Irvine32.inc

;constants
LOWER_LIMIT = -100
DECIMAL_PLACES = 3

.data
;strings
welcome		BYTE	"Welcome to the Integer Accumulator by Risto Keravuori", 0
underline	BYTE	"-----------------------------------------------------", 0
extra1		BYTE	"**EC1: Lines are numbered during user input", 0
extra2		BYTE	"**EC2: Average is displayed as float rounded at 3 places", 0
extra3		BYTE	"**EC3: Displays the average on a visual number line", 0
meet		BYTE	"What is your name? ", 0
greet		BYTE	"Hello, ", 0
instruct1	BYTE	"Please enter numbers in [", 0
instruct2	BYTE	", -1].", 0
instruct3	BYTE	"Enter a non-negative number when you are finished to see results.", 0
numPrompt	BYTE	") Enter number: ", 0
noNumbers	BYTE	"No negative numbers were entered. =[", 0
numError	BYTE	"Numbers cannot be smaller than -100.", 0
numCount1	BYTE	"You entered ", 0
numCount2	BYTE	" valid numbers.", 0
sum			BYTE	"The sum of your valid numbers is ", 0
intAvg		BYTE	"The rounded average is ", 0
floatAvg	BYTE	"The actual average (to three decimal places) is ", 0
numberLine1	BYTE	"On the number line, the average of your numbers would"
			BYTE	" look like this:", 0
numberLine2	BYTE	"(each mark represents 5 units)", 0
goodbye		BYTE	"Thank you for playing Integer Accumulator!"
			BYTE	" It's been a pleasure to meet you, ", 0


;variables
userName	BYTE	36 DUP(0)
accumulator	SDWORD	0
counter		DWORD	0
integerAvg	SDWORD	?


.code
main PROC
	call	DisplayIntro
	call	MeetAndGreet
	call	DisplayInstructions
	call	GatherNumbers
	call	ShowStats
	call	DisplayOutro
	exit	; exit to operating system
main ENDP


;--------------------------------------------------------------
;DisplayIntro
;Displays introduction and extra credit info
;Registers Changed: EDX
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
	mov		edx, OFFSET extra3
	call	WriteString
	call	CrLf
	call	CrLf
	ret
DisplayIntro ENDP


;--------------------------------------------------------------
;MeetAndGreet
;Gets user's name, greets them, and stores name
;Returns: Sets username at 'userName' memory location
;Registers Changed: EAX, ECX, EDX
;--------------------------------------------------------------
MeetAndGreet PROC
	mov		edx, OFFSET meet
	call	WriteString

	;capture user's name
	mov		edx, OFFSET userName
	mov		ecx, SIZEOF userName
	call	ReadString

	mov		edx, OFFSET greet
	call	Writestring
	mov		edx, OFFSET username
	call	WriteString
	mov		al, '.'
	call	WriteChar
	call	CrLf
	call	CrLf
	ret
MeetAndGreet ENDP


;--------------------------------------------------------------
;DisplayInstructions
;Displays instructions for using program
;Registers Changed: EAX, EDX
;--------------------------------------------------------------
DisplayInstructions PROC
	mov		edx, OFFSET instruct1
	call	WriteString
	mov		eax, LOWER_LIMIT
	call	WriteInt
	mov		edx, OFFSET instruct2
	call	WriteString
	call	CrLf
	mov		edx, OFFSET instruct3
	call	WriteString
	call	CrLf
	call	CrLf
	ret
DisplayInstructions ENDP


;--------------------------------------------------------------
;GatherNumbers
;Prompts user for input, validates range, and terminates on positive
;Returns: Sets total at 'accumulator' and count at 'counter' mem locations
;Preconditions: Lower limit of range set by LOWER_LIMIT constant
;Registers Changed: EAX, EDX
;--------------------------------------------------------------
GatherNumbers PROC
NumberLoop:
	;display line numbers
	mov		eax, counter
	inc		eax
	call	WriteDec

	;prompt for input and gather
	mov		edx, OFFSET numPrompt
	call	WriteString
	call	ReadInt

	;check if input out of valid range (below -100)
	cmp		eax, LOWER_LIMIT
	jge		ContinueCheck

	;display error and continue without saving
	mov		edx, OFFSET numError
	call	WriteString
	call	CrLf
	jmp		NumberLoop

ContinueCheck:
	;check if non-negative to decide whether to continue
	cmp		eax, 0
	jge		InputDone

	;update accumulator and counter
	add		accumulator, eax
	inc		counter
	jmp		NumberLoop

InputDone:
	call	CrLf
	ret
GatherNumbers ENDP


;--------------------------------------------------------------
;ShowStats
;Displays statistics about set of numbers entered by user
;Returns: Sets total at 'accumulator' and count at 'counter' mem locations
;Preconditions: Accumulator and counter set
;Registers Changed: EAX, EDX (EBX, ECX through subroutines)
;--------------------------------------------------------------
ShowStats PROC
	;check if any valid numbers entered
	cmp		counter, 0
	jz		NoValidInput

	;number of valid terms entered
	mov		edx, OFFSET numCount1
	call	WriteString
	mov		eax, counter
	call	WriteDec
	mov		edx, OFFSET numCount2
	call	WriteString
	call	CrLf

	;sum of entered valid terms
	mov		edx, OFFSET sum
	call	WriteString
	mov		eax, accumulator
	call	WriteInt
	mov		al, '.'
	call	WriteChar
	call	CrLf

	;integer average of valid terms
	mov		edx, OFFSET intAvg
	call	WriteString
	call	PrintIntAvg
	mov		al, '.'
	call	WriteChar
	call	CrLf

	;float average of valid terms
	mov		edx, OFFSET floatAvg
	call	WriteString
	call	PrintFloatAvg
	mov		al, '.'
	call	WriteChar
	call	CrLf
	call	CrLf


	;show average on number line
	mov		edx, OFFSET numberLine1
	call	WriteString
	call	CrLf
	mov		edx, OFFSET numberLine2
	call	WriteString
	call	CrLf
	call	PrintNumberLine
	jmp		Leaving

NoValidInput:
	;print special message for no valid terms
	mov		edx, OFFSET noNumbers
	call	WriteString
	call	CrLf

Leaving:
	call	CrLf
	ret
ShowStats ENDP


;--------------------------------------------------------------
;PrintIntAvg
;Prints integer average of input set, rounded half up
;Returns: Stores calculated integer average in 'integerAvg' memory location
;Preconditions: 'accumulator' and 'counter' set
;Registers Changed: EAX, EBX, EDX
;--------------------------------------------------------------
PrintIntAvg PROC
	;calculate average
	mov		eax, accumulator
	cdq
	idiv	counter

	;save quotient
	push eax

	;round remainder half-up
	mov		eax, edx
	mov		ebx, -10			;neg multiply to turn pos for comparison
	imul	ebx
	idiv	counter

	;compare remainder for rounding
	cmp		eax, 5
	jl		NoIntRound			;if less than 5, definitely round "up"
	jg		IntRound			;if greater than 5, definitely round "down"

	;if =5, then check remainder
	cmp		edx, 0
	jz		NoIntRound			;if no remainder, equals .5 exactly and round "up"

IntRound:
	;retrive quotient and round away from zero
	pop		eax
	dec		eax
	jmp	WriteOut

NoIntRound:
	;retreive quotient with no rounding
	pop		eax

WriteOut:
	mov		integerAvg, eax		;store integer average
	call	WriteInt
	ret
PrintIntAvg ENDP


;--------------------------------------------------------------
;PrintFloatAvg
;Prints float average of input set, rounded half up
;Preconditions: 'accumulator' and 'counter' set
;Registers Changed: EAX, EBX, ECX, EDX
;--------------------------------------------------------------
PrintFloatAvg PROC
	;print base average with decimal point
	mov		eax, accumulator
	cdq
	idiv	counter
	call	WriteInt
	mov		al, '.'
	call	WriteChar

	;convert remainder to positive number
	mov		eax, edx
	neg		eax

	;set up loop
	mov		ecx, DECIMAL_PLACES
FloatingPoints:
	;multiply remainder by 10 and redivide to get each digit
	mov		ebx, 10
	imul	ebx
	idiv	counter
	cmp		ecx, 1
	jne		ContinueLoop		;jump to end for all but last decimal place

	;compute rounding for last decimal place
	push	eax
	mov		eax, edx
	mov		ebx, 10
	imul	ebx
	idiv	counter
	cmp		eax, 5
	jle		NoFloatRound
	pop		eax
	inc		eax
	jmp		ContinueLoop

NoFloatRound:
	pop		eax
ContinueLoop:
	;write digit
	call	WriteDec
	mov		eax, edx
	loop	FloatingPoints
	ret
PrintFloatAvg ENDP


;--------------------------------------------------------------
;PrintNumberLine
;Prints number line (with units of five) from LOWER_LIMIT to -1
; showing visual representation of computed average
;Preconditions: 'integerAvg' set and LOWER_LIMIT defined
;	(works best with LOWER_LIMIT as multiple of 5)
;Registers Changed: EAX, EBX, ECX, EDX
;--------------------------------------------------------------
PrintNumberLine PROC

	;print left-hand side of number line
	mov		eax, LOWER_LIMIT
	call	WriteInt
	mov		al, ' '
	call	WriteChar
	mov		al, '|'
	call	WriteChar

	;set up loop
	mov		ebx, LOWER_LIMIT
	mov		ecx, integerAvg

PreMarkerTicks:
	;determine if current tick is within threshold of marker
	;loop printing '.' until threshold met
	mov		edx, ebx
	sub		edx, ecx
	cmp		edx, -2
	jge		PrintMarker
	mov		al, '.'
	call	WriteChar
	sub		ebx, -5
	jmp		PreMarkerTicks

PrintMarker:
	;print marker within +/- 2 of average
	mov		al, 'X'
	call	WriteChar
	cmp		ebx, 0
	jge		FinishLine

PostMarkerTicks:
	;print '.' to fill out rest of number line
	sub		ebx, -5
	mov		al, '.'
	call	WriteChar
	cmp		ebx, 0
	jl		PostMarkerTicks

FinishLine:
	;print end of number line
	mov		al, '|'
	call	WriteChar
	mov		al, ' '
	call	WriteChar
	mov		eax, -1
	call	WriteInt
	call	CrLf
	ret
PrintNumberLine ENDP


;--------------------------------------------------------------
;DisplayOutro
;Displays personalized goodbye message
;Registers Changed: EDX
;--------------------------------------------------------------
DisplayOutro PROC
	mov		edx, OFFSET goodbye
	call	WriteString
	mov		edx, OFFSET userName
	call	WriteString
	mov		al, '.'
	call	WriteChar
	call	CrLf
	ret
DisplayOutro ENDP

END main
