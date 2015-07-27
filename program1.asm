TITLE Program 1 - Assembly Math     (program1.asm)

; Author: Risto Keravuori
; Description: This program takes 2 integers from the user and displays their sum,
;	product, and quotient with remainder. It verifies that the second number is
;	smaller than the first number, and allows the user to keep trying pairs of
;	numbers until they desire to quit.

INCLUDE Irvine32.inc

.data
;all strings
welcome		BYTE	"Assembly Math by Risto Keravuori", 0
ec1			BYTE	"**EC1: Program allows user to replay until quiting", 0
ec2			BYTE	"**EC2: Program verifies second number is smaller than first", 0
ec3			BYTE	"**EC3: Program also displays division result as floating point"
			BYTE	" result with rounding to nearest thousdanth", 0
instruct	BYTE	"Enter 2 numbers, and I'll show you the sum,"
			BYTE	" difference, product, quotient, and remainder.", 0
firstPrompt	BYTE	"First number: ", 0
secPrompt	BYTE	"Second number: ", 0
addSign		BYTE	" + ", 0
subSign		BYTE	" - ", 0
mulSign		BYTE	" x ", 0
divSign		BYTE	" / ", 0
decimalPt	BYTE	".", 0
eqSign		BYTE	" = ", 0
remSign		BYTE	" remainder ", 0
badNum2		BYTE	"The second number must be less than the first!", 0
continue	BYTE	"1: Continue", 0
quit		BYTE	"Else: Quit", 0
playAgain	BYTE	"Enter your choice: ", 0
goodbye		BYTE	"Impressed?  Bye!", 0

;all variables
firstNum	DWORD	?
secondNum	DWORD	?
addResult	DWORD	?
subResult	DWORD	?
mulResult	DWORD	?
divResult	DWORD	?
remResult	DWORD	?
digit1		DWORD	?
digit2		DWORD	?
digit3		DWORD	?

.code
main PROC

;Title
	mov		edx, OFFSET welcome
	call	WriteString
	call	CrLf

;Extra credit declarations
	mov		edx, OFFSET ec1
	call	WriteString
	call	CrLf
	mov		edx, OFFSET ec2
	call	WriteString
	call	CrLf
	mov		edx, OFFSET ec3
	call	WriteString
	call	CrLf
	call	CrLf

;Instructions/description
	mov		edx, OFFSET instruct
	call	WriteString
	call	CrLf
	call	CrLf


;Get both numbers
DataEntry:
	mov		edx, OFFSET firstPrompt
	call	WriteString
	call	ReadInt
	mov		firstNum, eax

	mov		edx, OFFSET secPrompt
	call	WriteString
	call	ReadInt
	mov		secondNum, eax
	call	CrLf

;Validate second number smaller than first
	cmp		firstNum, eax
	jb		BigNum2

;Calculate values
	;addition
	mov		eax, firstNum
	add		eax, secondNum
	mov		addResult, eax

	;subtraction
	mov		eax, firstNum
	sub		eax, secondNum
	mov		subResult, eax

	;multiplication
	mov		eax, firstNum
	mul		secondNum
	mov		mulResult, eax

	;integer division
	mov		eax, firstNum
	div		secondNum
	mov		divResult, eax
	mov		remResult, edx

	;calculate floating division digits
	;(one-by-one for appropriate zero padding)
	mov		eax, edx
	mov		ebx, 10
	mul		ebx
	div		secondNum
	mov		digit1, eax

	mov		eax, edx
	mov		ebx, 10
	mul		ebx
	div		secondNum
	mov		digit2, eax

	mov		eax, edx
	mov		ebx, 10
	mul		ebx
	div		secondNum
	mov		digit3, eax

	;round thousandths place half-up
	mov		eax, edx
	mov		ebx, 10
	mul		ebx
	div		secondNum
	cmp		eax, 5
	jb		DontRound
	inc		digit3
DontRound:

;Display results
	;addition
	mov		eax, firstNum
	call	WriteDec
	mov		edx, OFFSET addSign
	call	WriteString
	mov		eax, secondNum
	call	WriteDec
	mov		edx, OFFSET eqSign
	call	WriteString
	mov		eax, addResult
	call	WriteDec
	call	CrLf

	;subtraction
	mov		eax, firstNum
	call	WriteDec
	mov		edx, OFFSET subSign
	call	WriteString
	mov		eax, secondNum
	call	WriteDec
	mov		edx, OFFSET eqSign
	call	WriteString
	mov		eax, subResult
	call	WriteDec
	call	CrLf

	;multiplication
	mov		eax, firstNum
	call	WriteDec
	mov		edx, OFFSET mulSign
	call	WriteString
	mov		eax, secondNum
	call	WriteDec
	mov		edx, OFFSET eqSign
	call	WriteString
	mov		eax, mulResult
	call	WriteDec
	call	CrLf

	;division
	mov		eax, firstNum
	call	WriteDec
	mov		edx, OFFSET divSign
	call	WriteString
	mov		eax, secondNum
	call	WriteDec
	mov		edx, OFFSET eqSign
	call	WriteString
	mov		eax, divResult
	call	WriteDec
	mov		edx, OFFSET remSign
	call	WriteString
	mov		eax, remResult
	call	WriteDec
	call	CrLf

	;floating point division
	mov		eax, firstNum
	call	WriteDec
	mov		edx, OFFSET divSign
	call	WriteString
	mov		eax, secondNum
	call	WriteDec
	mov		edx, OFFSET eqSign
	call	WriteString
	mov		eax, divResult
	call	WriteDec
	mov		edx, OFFSET decimalPt
	call	WriteString
	mov		eax, digit1
	call	WriteDec
	mov		eax, digit2
	call	WriteDec
	mov		eax, digit3
	call	WriteDec
	call	CrLf
	call	CrLf
	jmp		NormalExit

;Error message for second number too big
BigNum2:
	mov		edx, OFFSET badNum2
	call	WriteString
	call	CrLf
	call	CrLf

;offer choice to play again
NormalExit:
	mov		edx, OFFSET continue
	call	WriteString
	call	CrLf
	mov		edx, OFFSET	quit
	call	WriteString
	call	CrLf
	mov		edx, OFFSET	playAgain
	call	WriteString
	call	ReadInt
	call	CrLf
	cmp		eax, 1
	je		DataEntry

;Say goodbye
	mov		edx, OFFSET goodbye
	call	WriteString
	call	CrLf


	exit	; exit to operating system
main ENDP

END main
