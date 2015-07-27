TITLE Program 6 - Combinatorics Quiz     (program6.asm)

; Author: Risto Keravuori
; Description: This program displays combinatorics problems for
;	the user and evaluates their responses against the correct score.
;	It displays a running score and allows user to answer multiple
;	questions until they desire to quit.

INCLUDE Irvine32.inc

MIN = 3
MAX = 12

.data
;------strings-------
intro		BYTE	"Combinatorics Quiz by Risto Keravuori", 0dh, 0ah
			BYTE	"-------------------------------------", 0dh, 0ah
			BYTE	"**EC: Program keeps and displays score", 0dh, 0ah, 0dh, 0ah
			BYTE	"I'll give you a combinatorics problem. You enter your answer,", 0dh, 0ah
			BYTE	"and I'll let you know if you're right.", 0dh, 0ah, 0
question1	BYTE	"Problem:", 0dh, 0ah
			BYTE	"Number of elements in the set: ", 0
question2	BYTE	"Number of elements to choose from the set: ", 0
prompt		BYTE	"How many ways can you choose? ", 0
resp1		BYTE	"There are ", 0
resp2		BYTE	" combinations of ", 0
resp3		BYTE	" items from a set of ", 0
resp4		BYTE	"You answered ", 0
respBad		BYTE	" You need more practice.", 0dh, 0ah, 0
respGood	BYTE	" You are correct!", 0dh, 0ah, 0
score1		BYTE	"You've gotten ", 0
score2		BYTE	" questions right out of ", 0
another		BYTE	"Another problem? (y/n): ", 0
badInput	BYTE	"Invalid response.", 0dh, 0ah, 0
outro		BYTE	"Thanks for playing. ", 0

;------variables-------
questions	DWORD	0
correct		DWORD	0


.data?
;------variables-------
total		DWORD	?
choices		DWORD	?
result		DWORD	?
input		BYTE	30 DUP(?)
answer		DWORD	?

;--------------------------------------------------------------
mWriteString MACRO string:REQ
;	Writes a string variable to the console
;	Receives: string variable name
;--------------------------------------------------------------
	push	edx
	mov		edx, OFFSET string
	call	WriteString
	pop		edx
ENDM

;--------------------------------------------------------------
mWritePeriod MACRO
;	Writes a terminal period
;--------------------------------------------------------------
	push	eax
	mov		al, '.'
	call	WriteChar
	pop		eax
ENDM


.code
main PROC

	call	DisplayIntro
	call	CrLf

	call	Randomize			;seed RNG

ProblemStart:
	push	OFFSET choices		;choices argument
	push	OFFSET total		;total argument
	call	ShowProblem

	push	SIZEOF input		;size argument
	push	OFFSET input		;buffer argument
	push	OFFSET answer		;answer argument
	call	GetAnswer
	call	CrLf

	push	OFFSET result		;result argumnet
	push	choices				;choices argument
	push	total				;total argument
	call	Combinations

	push	OFFSET correct		;correct argument
	push	OFFSET questions	;questions argument
	push	answer				;answer argument
	push	result				;result argument
	push	choices				;choices argument
	push	total				;total argument
	call	ShowResults
	call	CrLf

	push	correct				;correct argument
	push	questions			;questions argument
	push	SIZEOF input		;size argument
	push	OFFSET input		;buffer argument
	call	CheckContinue
	call	CrLf

	cmp		eax, 0
	jnz		ProblemStart		;if eax is not zero, display another question

	exit	; exit to operating system
main ENDP

;--------------------------------------------------------------
;DisplayIntro()
;	Displays introduction info and instructions
;Receives:
;	None
;Returns:
;	None
;Preconditions:
;	None
;Registers Changed:
;	None
;--------------------------------------------------------------
DisplayIntro PROC
	enter	0,0
	mWriteString intro
	leave
	ret
DisplayIntro ENDP

;--------------------------------------------------------------
;ShowProblem(DWORD* total, DWORD* choices)
;	Generates random numbers within proper range, saves n and r to targets,
;	and shows related combinatorics problem
;Receives:
;	total is the location for the n value of the combinatorics problem (size of the whole set)
;	choices is the locaiton for the r value of the combinatorics problem (size of the selection set)
;Returns:
;	n and r stored in total and choices, respectively
;Preconditions:
;	MIN and MAX global constants must be set and positive
;	(even better if they constrain problem space to 32-bit integers)
;Registers Changed:
;	None
;--------------------------------------------------------------
ShowProblem PROC
	enter	0,0
	push	eax
	push	edi

	mov		eax, MAX
	sub		eax, MIN
	inc		eax
	call	RandomRange			;get range for total (MAX - MIN + 1)
	add		eax, MIN			;move result into proper range [MIN .. MAX]
	mov		edi, [ebp+8]
	mov		[edi], eax		;move total result to memory

	mWriteString question1
	call	WriteDec
	call	CrLf

	call	RandomRange			;get range for choices
	inc		eax					;move result into proper range [1 .. total]
	mov		edi, [ebp+12]
	mov		[edi], eax		;move choices result to memory

	mWriteString question2
	call	WriteDec
	call	CrLf

	pop		edi
	pop		eax
	leave
	ret		8
ShowProblem ENDP

;--------------------------------------------------------------
;GetAnswer(DWORD* answer, BYTE[] buffer, DWORD size)
;	Gets user reponse to problem, receiving input as string,
;	validating as number, and storing in answer
;Receives:
;	answer is the memory location to which to store valid input
;	buffer is the BYTE array for caching user input as string
;	size if the size of the input buffer
;Returns:
;	valid input is stored in answer
;Preconditions:
;	valiud input will fit in a 32-bit integer
;Registers Changed:
;	None
;--------------------------------------------------------------
GetAnswer PROC
	enter	0,0
	pushad

GetInput:
	mWriteString prompt			;display prompt

	mov		edx, [ebp+12]		;buffer parameter
	mov		ecx, [ebp+16]		;size parameter
	call	ReadString

	mov		ecx, eax			;move length of input to loop counter
	mov		eax, 0				;zero out accumulator
	mov		esi, [ebp+12]		;pointer to start of buffer

ProcessBuffer:
	mov		ebx, 0
	mov		bl, [esi]			;get leading value off of input buffer
	cmp		bl, '0'
	jb		Fail				;check if ASCII value below zero, fail is so
	cmp		bl, '9'
	ja		Fail				;check if ASCII value above nine, fail is so

	mov		edx, 10
	mul		edx					;left shift previous accumulator value (base 10)
	sub		bl, '0'				;subtract base ASCII value of zero to get numeric value
	add		eax, ebx			;add current value to accumulator
	inc		esi					;move to next value in buffer
	loop	ProcessBuffer
	jmp		Save				;if loop finishes, input was valid

Fail:
	mWriteString badInput		;display error
	jmp		GetInput			;try again

Save:
	mov		edi, [ebp+8]		;answer parameter
	mov		[edi], eax			;save valid input from accumulator

	popad
	leave
	ret		12
GetAnswer ENDP


;--------------------------------------------------------------
;Combinations(DWORD total, DWORD choices, DWORD* result)
;	Solves combinatorics problem of the format nCr (n choose r)
;	and stores result in target location
;Receives:
;	total is the n value of the combinatorics problem (size of the whole set)
;	choices is the r value of the combinatorics problem (size of the selection set)
;	result is the memory location to which to store the result
;Returns:
;	calculated result is stored in result
;Preconditions:
;	final result must fit within a 32-bit integer
;Registers Changed:
;	None
;--------------------------------------------------------------
Combinations PROC
	enter	0,0
	pushad

	mov		ebx, [ebp+8]		;total parameter
	mov		ecx, [ebp+12]		;choices

	sub		ebx, ecx			;calculate (n-r)!
	push	ebx					;count argument
	call	Factorial

	mov		edx, eax			;cache (n-r)!

	push	ecx					;count argument for r!
	call	Factorial

	mul		edx					;calculate r!(n-r)!
	mov		ebx, eax			;cache r!(n-r)!

	push	[ebp+8]				;count argument for n!
	call	Factorial

	div		ebx					;calculate n!/(r!(n-r)!) where ebx = cached divisor product

	mov		edi, [ebp+16]		;result parameter
	mov		[edi], eax			;save combinations to answer location

	popad
	leave
	ret		12
Combinations ENDP


;--------------------------------------------------------------
;Factorial(DWORD count)
;	Computes factorial of the value count
;Receives:
;	count is a number for factorial targeting
;Returns:
;	EAX - value of factorial
;Preconditions:
;	count is non-negative
;Registers Changed:
;	EAX
;--------------------------------------------------------------
Factorial PROC
	enter	0,0
	push	ebx
	push	edx

	mov		eax, [ebp+8]		;count parameter
	cmp		eax, 0
	ja		Recurse				;if value is above zero, get factorial of one level done
	mov		eax, 1				;otherwise, set return to 1 (0! = 1 by definition)
	jmp		Done

Recurse:
	dec		eax					;decrement eax
	push	eax					;count argument
	call	Factorial			;recursive Factorial(count) call, value comes back in eax

	mov		ebx, [ebp+8]		;count parameter
	mul		ebx					;multiply (count-1)! by count

Done:
	pop		edx
	pop		ebx
	leave
	ret		4
Factorial ENDP


;--------------------------------------------------------------
;ShowResults(DWORD total, DWORD choices, DWORD result, DWORD answer, DWORD* questions, DWORD* correct)
;	Shows the results of a given problem and updates running score
;Receives:
;	total is the n value of the combinatorics problem (size of the whole set)
;	chocies si the r value of the combainatorics problem (size of the selection set)
;	result is the calculated correct answer
;	answer is the user's answer to the problem
;	questions is the memory location of the running question count
;	correct is the memory location of the running correct answer count
;Returns:
;	None
;Preconditions:
;	None
;Registers Changed:
;	None
;--------------------------------------------------------------
ShowResults PROC
	enter	0,0
	pushad

	mWriteString resp1			;display result line
	mov		eax, [ebp+16]		;result parameter
	call	WriteDec
	mWriteString resp2
	mov		eax, [ebp+12]		;choices parameter
	call	WriteDec
	mWriteString resp3
	mov		eax, [ebp+8]		;total parameter
	call	WriteDec
	mWritePeriod
	call	CrLf

	mWriteString resp4			;display answer line
	mov		eax, [ebp+20]		;answer parameter
	call	WriteDec
	mWritePeriod

	mov		esi, [ebp+24]		;questions parameter
	mov		ecx, [esi]			;questions value
	inc		ecx					;increment questions value for this question

	mov		edi, [ebp+28]		;correct parameter
	mov		edx, [edi]			;correct value

	mov		ebx, [ebp+16]		;result parameter
	cmp		ebx, eax
	je		GoodAnswer			;if result == answer, then response was correct

	mWriteString respBad
	jmp		Score

GoodAnswer:
	inc		edx					;increment correct for good answer
	mWriteString respGood

Score:
	push	edx					;correct argument
	push	ecx					;questions argument
	call	ShowScore
	call	CrLf

	mov		[esi], ecx			;save updated questions value
	mov		[edi], edx			;save updated correct value

	popad
	leave
	ret		24
ShowResults ENDP


;--------------------------------------------------------------
;ShowScore(DWORD questions, DWORD correct)
;	Displays a user's score
;Receives:
;	questions is total number of questions thus far
;	correct is total number of correct answers thus far
;Returns:
;	None
;Preconditions:
;	None
;Registers Changed:
;	None
;--------------------------------------------------------------
ShowScore PROC
	enter	0,0
	push	eax

	mWriteString score1
	mov		eax, [ebp+12]		;correct parameter
	call	WriteDec
	mWriteString score2
	mov		eax, [ebp+8]		;questions parameter
	call	WriteDec
	mWritePeriod

	pop		eax
	leave
	ret		8
ShowScore ENDP


;--------------------------------------------------------------
;CheckContinue(BYTE[] buffer, DWORD size, DWORD questions, DWORD correct)
;	Checks if a user wants to continue
;Receives:
;	buffer is byte array for storing string input
;	size is length of input buffer
;	questions is number of questions seen thus far
;	correct is number of correct answer thus far
;Returns:
;	EAX - 0 if continue = false, 1 if continue = true
;Preconditions:
;	None
;Registers Changed:
;	EAX
;--------------------------------------------------------------
CheckContinue PROC
	enter	0,0
	push	ecx
	push	edx

GetInput:
	mWriteString another		;display prompt

	mov		edx, [ebp+8]		;buffer parameter
	mov		ecx, [ebp+12]		;size parameter
	call	ReadString

	cmp		eax, 1
	jne		Invalid				;if response is greater than 1 character long, invalid

	mov		eax, 0				;clear register for incoming BYTE value
	mov		al, [edx]			;move response to AL

	cmp		al, 'Y'
	je		Continue			;if response is 'Y', continue
	cmp		al, 'y'
	je		Continue			;if response is 'y', continue
	cmp		al, 'N'
	je		Stop				;if response is 'N', stop
	cmp		al, 'n'
	je		Stop				;if response is 'n', stop

Invalid:						;if fall through, invalid response
	mWriteString badInput
	jmp		GetInput			;try again

Continue:
	mov		eax, 1				;set true return value
	jmp		Done

Stop:
	mov		eax, 0				;set false return value
	mWriteString outro
	push	[ebp+20]			;correct argument from correct parameter
	push	[ebp+16]			;questions argument from questions parameter
	call	ShowScore
	call	CrLf

Done:
	pop		edx
	pop		ecx
	leave
	ret		16
CheckContinue ENDP

END main
