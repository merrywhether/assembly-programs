TITLE Program 4 - Composite Number Generator     (program4.asm)

; Author: Risto Keravuori
; Description: This program displays a list of composite numbers.
;	It asks a user for the number of composite numbers to display,
;	then displas across the necessary number of pages. It increases
;	efficiency by building a list of prime numbers as it checks each
;	number and testing new numbers for divisibility against only
;	this primes list. At the end, it displays how many primes
;	were found in the process.


INCLUDE Irvine32.inc
;------constants-------
UPPER_LIMIT = 100000
MAX_PRIMES = 10500
PER_LINE = 9
PER_PAGE = 198

.data
;------strings-------
intro		BYTE	"Composite Number Generator by Risto Keravuori", 0
underline	BYTE	"---------------------------------------------", 0
extra1		BYTE	"**EC1: Columns are left-aligned to one's place of the printed terms.", 0
extra2		BYTE	"**EC2: Total number of terms has been increased from 400 to 100000"
			BYTE	" & paging has been added. (This meant I had to reduce terms per line from 10 to 9.)", 0
extra3		BYTE	"**EC3: Composite check is done by checking for divisibility by primes only,"
			BYTE	" with the requisite implementation of an array to store all found primes.", 0
instruct1	BYTE	"Enter the number of composite numbers you would like to see.", 0
instruct2	BYTE	"I'll accept orders for up to ", 0
instruct3	BYTE	" composites.", 0
numPrompt1	BYTE	"Enter the number of composites to display [1 .. ", 0
numPrompt2	BYTE	"]: ", 0
badNumber	BYTE	"Out of range. Try again.", 0
pageBreak1	BYTE	"Page ", 0
pageBreak2	BYTE	" of ", 0
summary1	BYTE	"Printed ", 0
summary2	BYTE	" composites across ", 0
summary3	BYTE	" pages & found ", 0
summary4	BYTE	" primes!", 0

;------variables-------
userNumber	DWORD	0
primes		DWORD	MAX_PRIMES DUP(0)

.code
main PROC
	push	UPPER_LIMIT						;limit arg for DisplayIntro
	call	DisplayIntro
	call	CrLf

	push	OFFSET userNumber				;resultStore arg for GetCount
	push	UPPER_LIMIT						;limit arg for GetCount
	call	GetCount
	call	CrLf

	push	PER_PAGE						;perPage arg for PrintComposites
	push	PER_LINE						;perLine arg for PrintComposites
	push	OFFSET primes					;primes arg for PrintComposites
	push	userNumber						;count arg for PrintComposites
	call	PrintComposites

	push	OFFSET primes					;primes arg for DisplayOutro
	push	PER_PAGE						;perPage arg for DisplayOutro
	push	userNumber						;total arg for DisplayOutro
	call	DisplayOutro

	exit	; exit to operating system
main ENDP


;--------------------------------------------------------------
;DisplayIntro(DWORD limit)
;	Displays introduction info and instructions
;Receives:
;	limit is upper limit on valid input range
;Returns:
;	None
;Preconditions:
;	None
;Registers Changed:
;	None
;--------------------------------------------------------------
DisplayIntro PROC
	enter	0,0
	push	eax							;save affected registers
	push	edx

	mov		eax, [ebp+8]				;limit parameter

	mov		edx, OFFSET intro			;display title and extra credit
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

	mov		edx, OFFSET instruct1		;display instructions
	call	WriteString
	call	CrLf
	mov		edx, OFFSET instruct2
	call	WriteString
	call	WriteDec					;using limit in EAX
	mov		edx, OFFSET instruct3
	call	WriteString
	call	CrLf

	pop		edx							;restore saved registers
	pop		eax
	leave
	ret		4							;clean up 1 parameter on return
DisplayIntro ENDP


;--------------------------------------------------------------
;GetCount(DWORD limit, DWORD[] resultStore)
;	Prompts user for input of how many numbers they'd like,
;	limited to passed-in upper limit parameter
;Receives:
;	limit is upper limit on valid input range
;	resultStore is pointer to variable for storing result
;Returns:
;	Saves result in passed-in resultStore reference
;Preconditions:
;	limit > 0
;Registers Changed:
;	None
;--------------------------------------------------------------
GetCount PROC
	enter	0, 0
	push	ecx							;save affected registers
	push	esi
	push	edx

	mov		ecx, [ebp+8]				;limit parameter
	mov		esi, [ebp+12]				;resultStore parameter

GetNumber:
	mov		edx, OFFSET numPrompt1		;prompt for input
	call	WriteString
	mov		eax, ecx
	call	WriteDec					;include limit in prompt
	mov		edx, OFFSET numPrompt2
	call	WriteString
	call	ReadDec						;read input

	push	ecx							;limit arg for ValidateNumber
	push	eax							;testNumber arg for ValidateNumber
	call	ValidateNumber

	cmp		eax, 0						;function returned result in EAX
	jnz		GoodNumber					;if eax != 0, input is valid
	mov		edx, OFFSET badNumber		;print invlalid message
	call	WriteString
	call	CrLf
	jmp		GetNumber					;retry input prompt
GoodNumber:
	mov		[esi], eax					;store number in parameter reference
	pop		edx							;restore saved registers
	pop		esi
	pop		ecx
	leave
	ret		8							;clean up 2 parameters on return
GetCount ENDP


;--------------------------------------------------------------
;ValidateNumber(DWORD testNumber, DWORD limit)
;	Tests number against limit
;Receives:
;	testNumber is value to be validated
;	limit is upper limit for possible values
;Returns:
;	EAX - testNumber if valid, 0 if invalid
;Preconditions:
;	limit > 0
;Registers Changed:
;	EAX
;--------------------------------------------------------------
ValidateNumber PROC
	enter	0, 0
	push	ebx						;save affected registers (except for return register)

	mov		eax, [ebp+8]			;testNumber parameter
	mov		ebx, [ebp+12]			;limit parameter

	cmp		eax, ebx				;compare against limit
	jbe		Done					;if number not above limit, return
	mov		eax, 0					;set eax to 0 for invalid (also covers invalid testNumber = 0 case)

Done:
	pop		ebx						;restore saved registers
	leave
	ret		4						;clean up 2 parameters on return
ValidateNumber ENDP


;--------------------------------------------------------------
;PrintComposites(DWORD count, DWORD[] primes, DWORD perLine, DWORD perPage)
;	Prints composite numbers, up to count parameter, formatted
;	by perLine parameter to govern values printed in each line
;	and by perPage parameter to govern value printed per page
;	(pausing for user input between pages)
;Receives:
;	count is the number of terms to be displayed
;	primes is an array for prime numbers
;	perLine is the number of terms to be displayed per line
;	perPage is the number of terms to be displayed per page
;Returns:
;	primes array will be populated with some number of prime numbers
;Preconditions:
;	count > 0
;	count < ~850000 (assumes max digits of found terms to be less than 7, otherwise breaks formatting)
;	perLine > 0
;	perPage > 0
;Registers Changed:
;	None
;--------------------------------------------------------------
PrintComposites PROC
	enter	0, 0
	pushad								;save all registers

	mov		ecx, [ebp+8]				;count parameter
	;		[ebp+12]					;primes parameter
	;		[ebp+16]					;perLine parameter
	;		[ebp+20]					;perPage parameter

	mov		ebx, 2						;start testing numbers at 2
	mov		edx, 1						;set initial position in line (1-based index)
	mov		esi, 1						;set initial page to 1
	mov		edi, 1						;set initial position in page (1-based index)

	call	Clrscr						;start term printing with fresh console

PagePrinter:
	push	[ebp+12]					;primes arg for CheckComposite
	push	ebx							;testNumber arg for CheckComposite
	call	CheckComposite

	cmp		eax, 0						;test return value
	jz		NotComposite				;if 0, number was not composite

	push	[ebp+16]					;perLine arg for PrintFormattedComposite
	push	edx							;linePosition arg for PrintFormattedComposite
	push	eax							;number arg for PrintFormattedComposite
	call	PrintFormattedComposite

	inc		edx							;increment line position modulo (1-based) perLine
	cmp		edx, [ebp+16]				;[ebp+16] is perLine parameter
	jbe		CheckPaging
	mov		edx, 1						;if above perLine, reset to 1

CheckPaging:
	inc		edi							;increment page position modulo (1-based) perPage
	cmp		edi, [ebp+20]				;[ebp+20] is perPage parameter
	jbe		NextNumber
	mov		edi, 1						;if above perPage, reset to 1
	cmp		ecx, 1						;check if just printed last term
	je		NextNumber					;if printed last term, let loop terminate

	push	[ebp+20]					;perPage arg for PrintPageBreak
	push	[ebp+8]						;total arg for PrintPageBreak
	push	esi							;currentPage arg for PrintPageBreak
	call	PrintPageBreak

	call	WaitMsg						;display continue message and wait until user input
	call	Clrscr						;reset terminal
	inc		esi							;increment current page
	jmp		NextNumber

NotComposite:
	inc		ecx							;unsuccessful loop, increment counter
NextNumber:
	inc		ebx							;move to next potential number
	loop	PagePrinter					;go to next number

	cmp		edx, 1
	je		Done						;print extra return if PrintFormattedComposite didn't
	call	CrLf
Done:
	popad								;restore all registers
	leave
	ret		16							;clean up 4 parameters on return
PrintComposites ENDP


;--------------------------------------------------------------
;CheckComposite(DWORD testNumber, DWORD[] primes)
;	Checks if a number is composite using division by known-primes
;	with side effect of updating known-primes if new one found
;Receives:
;	testNumber is the value to be checked if composite
;	primes is an array for prime numbers
;Returns:
;	EAX - testNumber if composite, 0 is not
;	primes will be updated with new prime
;Preconditions:
;	testNumber > 1
;Registers Changed:
;	EAX
;--------------------------------------------------------------
CheckComposite PROC
	enter	0, 0
	push	ebx				;save affected registers (except for return register)
	push	ecx
	push	edx
	push	esi

	mov		ecx, [ebp+8]	;testNumber parameter
	mov		esi, [ebp+12]	;primes parameter

	jmp		Check			;start first loop without incrementing pointer
NextCheck:
	add		esi, 4			;move array pointer to next entry
Check:
	mov		ebx, [esi]		;get prime from array
	cmp		ebx, 0
	jz		NewPrime		;if 0, then no more known primes

	mov		eax, ecx		;found prime, move testNumber to dividend spot
	mov		edx, 0			;clear upper half of dividend
	div		ebx				;divide by current prime
	cmp		edx, 0			;test for remainder
	jnz		NextCheck		;if remainder, prime is not divisor and check next prime
	mov		eax, ecx		;no remainder, number is composite
	jmp		Done

NewPrime:
	mov		[esi], ecx		;add new prime to first zero in array
	mov		eax, 0			;set EAX to 0 for non-composite return

Done:
	pop		esi				;restore saved registers
	pop		edx
	pop		ecx
	pop		ebx
	leave
	ret		8
CheckComposite ENDP


;--------------------------------------------------------------
;PrintFormattedComposite(DWORD number, DWORD linePosition, DWORD perLine)
;	Formats a term for printing depending on size and position in line,
;	with 3 spaces between terms in a line inner-padding for terms to fill
;	6 characters per term (limiting term to a max of 6 digits)
;Receives:
;	number is the term to be printed
;	linePosition is the current printing location within a line
;	perLine is the max number of terms printer per line
;Returns:
;	None
;Preconditions:
;	number < 1000000 (10^6), otherwise will break column alignment
;	linePosition > 0 (1-based index)
;	perLine > 0
;Registers Changed:
;	None
;--------------------------------------------------------------
PrintFormattedComposite PROC
	enter 0,0
	pushad						;save all registers

	mov		edx, [ebp+8]		;number parameter
	mov		ebx, [ebp+12]		;linePosition parameter
	mov		esi, [ebp+16]		;perLine parameter

	mov		ecx, 0				;seed padding number
	cmp		ebx, 1
	je		InnerPadding			;no outer padding (between number padding) if first term
	add		ecx, 3				;3 spaces of outer padding between terms
InnerPadding:
	cmp		edx, 100000
	jae		PrePadding			;no extra padding if 6-digit number
	inc		ecx					;1 space extra pdding if 5-digit number or less, etc
	cmp		edx, 10000
	jae		PrePadding
	inc		ecx
	cmp		edx, 1000
	jae		PrePadding
	inc		ecx
	cmp		edx, 100
	jae		PrePadding
	inc		ecx
	cmp		edx, 10
	jae		PrePadding
	inc		ecx

PrePadding:
	cmp		ecx, 0
	jz		PrintTerm			;don't enter loop if no padding necessary
PrintPadding:
	mov		al, ' '
	call	WriteChar
	loop	PrintPadding

PrintTerm:
	mov		eax, edx			;print actual term
	call	WriteDec

	cmp		ebx, esi
	jne		Done
	call	CrLf				;print newline if last entry in a line

Done:
	popad						;restore all registers
	leave
	ret		12
PrintFormattedComposite ENDP


;--------------------------------------------------------------
;PrintPageBreak(DWORD currentPage, DWORD total, DWORD perPage)
;	Prints progress through pages in form "Page X of Y.", calculating
;	total pages from total and perPage parameters
;Receives:
;	currentPage is the page that just finished printing
;	total is total number of terms to be printed
;	perPage is the number of terms printed per page
;Returns:
;	None
;Preconditions:
;	total > 0
;	perPage > 0
;Registers Changed:
;	None
;--------------------------------------------------------------
PrintPageBreak PROC
	enter 0,0
	push	eax							;save affected registers
	push	edx

	;		[ebp+8]						;currentPage parameter
	;		[ebp+12]					;total parameter
	;		[ebp+16]					;perPage parameter

	call	CrLf						;print current page info
	mov		edx, OFFSET pageBreak1
	call	WriteString
	mov		eax, [ebp+8]
	call	WriteDec
	mov		edx, OFFSET	pageBreak2
	call	WriteString

	push	[ebp+16]					;perPage arg for GetTotalPages
	push	[ebp+12]					;total arg for GetTotalPages
	call	GetTotalPages
	call	WriteDec					;print total pages
	mov		al, '.'
	call	WriteChar
	call	CrLf

	pop		edx							;restore saved registers
	pop		eax
	leave
	ret		12							;clean up 4 parameters on return
PrintPageBreak ENDP


;--------------------------------------------------------------
;DisplayOutro(DWORD total, DWORD perPage, DWORD[] primes)
;	Displays total number of terms and pages and total number of
;	primes found
;Receives:
;	total is the total number of terms requested by user
;	perPage is the number of terms printed perPage
;	primes is an array of prime numbers
;Returns:
;	None
;Preconditions:
;	total > 0
;	perPage > 0
;Registers Changed:
;	None
;--------------------------------------------------------------
DisplayOutro PROC
	enter	0,0
	pushad							;save all registers

	mov		eax, [ebp+8]			;total parameter
	;		[ebp+12]				;perPage parameter
	mov		esi, [ebp+16]

	mov		dh, 23					;set cursor to start of second-to-last row
	mov		dl, 0
	call	Gotoxy

	mov		edx, OFFSET summary1
	call	WriteString
	call	WriteDec				;print total terms
	mov		edx, OFFSET summary2
	call	WriteString

	push	[ebp+12]				;perPage arg for GetTotalPages
	push	eax						;total arg for GetTotalPages
	call	GetTotalPages
	call	WriteDec				;print total pages

	mov		edx, OFFSET summary3
	call	WriteString

	mov		eax, 0					;set up prime counter
CheckNext:
	mov		ebx, [esi]
	cmp		ebx, 0
	jz		Done					;keep looking through array find a zero
	add		esi, 4
	inc		eax						;increment prime counter
	jmp		CheckNext

Done:
	call	WriteDec

	mov		edx, OFFSET summary4
	call	WriteString
	call	CrLf

	popad							;restore all registers
	leave
	ret		12						;clean up 3 parameters on return
DisplayOutro ENDP


;--------------------------------------------------------------
;GetTotalPages(DWORD total, DWORD perPage)
;	Displays number of pages needed to total number of terms
;Receives:
;	total is the total number of terms requested by user
;	perPage is the number of terms printed perPage
;Returns:
;	EAX - number of pages
;Preconditions:
;	total > 0
;	perPage > 0
;Registers Changed:
;	EAX
;--------------------------------------------------------------
GetTotalPages PROC
	enter 0,0
	push	ebx					;save affected registers
	push	edx

	mov		eax, [ebp+8]		;total parameter
	mov		ebx, [ebp+12]		;perPage parameter

	mov		edx, 0				;clear upper dividend register
	div		ebx					;divide total by perPage
	cmp		edx, 0				;check remainder
	jz		Done				;if no remainder, EAX has correct total pages
	inc		eax					;if remainder, EAX is one short

Done:
	pop		edx					;restore saved registers
	pop		ebx
	leave
	ret		8					;clean up 2 parameters on return
GetTotalPages ENDP

END main
