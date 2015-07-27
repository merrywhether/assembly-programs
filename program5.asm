TITLE Program 5 - Sorting Random Numbers    (program5.asm)

; Author: Risto Keravuori
; Description: This program prompts the user for a number between 10 and 200 (inclusive)
;	and then generates a list that length of random numbers between 100 and 999
;	(inclusive). It then sorts in descending order the array using a recursive QuickSort
;	algorithm. Once the list is sorted, it displays the median and then prints the ordered
;	list, with the numbers descending down columns and then spilling over, up to maximum
;	of 10 columns (in the minimum number of rows necessary).
;

INCLUDE Irvine32.inc
;------constants-------
MIN = 10
MAX = 200
LO = 100
HI = 999

.data
;------strings-------
intro		BYTE	"Sorting Random Numbers by Risto Keravuori", 0dh, 0ah
			BYTE	"-----------------------------------------", 0dh, 0ah
			BYTE	"**EC: Numbers are displayed ordered by column instead of row", 0dh, 0ah
			BYTE	"**EC: Numbers are sorted using recursive QuickSort algorithm", 0dh, 0ah, 0dh, 0ah
			BYTE	"This program generates random numbers in the range [100 .. 999],", 0dh, 0ah
			BYTE	"displays the original list, sorts the list, and calculates the", 0dh, 0ah
			BYTE	"median value. Finally, it displays the list sorted in descending order.", 0dh, 0ah, 0
prompt		BYTE	"How many numbers should be generated? [10 .. 200]: ", 0
badInput	BYTE	"Invalid input", 0dh, 0ah, 0
unsorted	BYTE	"The unsorted random numbers:", 0dh, 0ah, 0
median		BYTE	"The median is ", 0
sorted		BYTE	"The sorted list:", 0dh, 0ah, 0

;------variables-------
request		DWORD	?
array		DWORD	MAX+1 DUP(0)


.code
main PROC

	call	DisplayIntro

	push	OFFSET request			;request pointer argument
	call	GetData

	push	OFFSET array			;array pointer argument
	push	request					;count value argument
	call	FillArray

	push	OFFSET unsorted			;title pointer argument
	push	request					;count value argument
	push	OFFSET array			;array pointer argument
	call	DisplayList

	push	request					;count value argument
	push	OFFSET array			;array pointer argument
	call	SortList

	push	request					;count value argument
	push	OFFSET array			;array pointer argument
	call	DisplayMedian

	push	OFFSET sorted			;title pointer argument
	push	request					;count value argument
	push	OFFSET array			;array pointer argument
	call	DisplayList

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
	push	edx							;save affected register

	mov		edx, OFFSET intro			;display title and extra credit
	call	WriteString
	call	CrLf

	pop		edx							;restore saved register
	leave
	ret
DisplayIntro ENDP


;--------------------------------------------------------------
;GetData(DWORD* request)
;	Prompts the user for input, validates input, and saves
;	valid input in request reference
;Receives:
;	request is address of memory location
;Returns:
;	user input is stored in request memory location
;Preconditions:
;	MIN and MAX global constants must be defined
;Registers Changed:
;	None
;--------------------------------------------------------------
GetData PROC
	enter	0,0
	push	eax
	push	edx
	push	edi

	mov		edi, [ebp+8]				;request parameter

TryPrompt:
	mov		edx, OFFSET prompt			;display prompt
	call	WriteString
	call	ReadInt						;read input

	cmp		eax, MIN
	jb		BadData						;if input is below MIN, fail validation
	cmp		eax, MAX
	ja		BadData						;if input is above MAX, fail validation
	jmp		GoodData

BadData:
	mov		edx, OFFSET badInput		;display invalid input message
	call	WriteString
	jmp		TryPrompt					;retry input

GoodData:
	mov		[edi], eax					;save request variable to parameter
	call	CrLf

	pop		edi
	pop		edx
	pop		eax
	leave
	ret		4							;clean up 1 parameter on stack
GetData ENDP


;--------------------------------------------------------------
;FillArray(DWORD count, DWORD[] array)
;	Fills array with random numbers, up to the limit defined
;	by count
;Receives:
;	count is the total number of random numbers to generate
;	array is the array to which to save the generated numbers
;Returns:
;	array is populated with requested number of random numbers
;Preconditions:
;	HI and LO global constants must be defined
;Registers Changed:
;	None
;--------------------------------------------------------------
FillArray PROC
	enter	0,0
	push	eax
	push	ecx
	push	edi

	mov		ecx, [ebp+8]			;count parameter, loaded as loop counter
	mov		edi, [ebp+12]			;array parameter

	call	Randomize				;seed random
Fill:
	mov		eax, HI-LO+1			;load range
	call	RandomRange
	add		eax, LO					;bring result into range
	mov		[edi], eax				;store result
	add		edi, 4					;increment array pointer
	loop	Fill

	pop		edi
	pop		ecx
	pop		eax
	leave
	ret		8						;clean up 2 parameters on stack
FillArray ENDP


;--------------------------------------------------------------
;DisplayList(DWORD[] array, DWORD count, BYTE* title)
;	Displays introduction info and instructions
;Receives:
;	array of values to display
;	count is size of array
;	title is the name of the array
;Returns:
;	None
;Preconditions:
;	None
;Registers Changed:
;	None
;--------------------------------------------------------------
DisplayList PROC
	enter	0,0
	pushad

	mov		esi, [ebp+8]			;array parameter
	mov		edx, [ebp+16]			;title parameter
	call	WriteString				;display list title

	;determine number of lines
	mov		eax, [ebp+12]			;count parameter, as dividend
	cdq
	mov		ebx, 10					;10 as divisor
	div		ebx
	cmp		edx, 0					;check remainder
	jz		SetRows					;if remainder == 0, eax is number of rows needed
	inc		eax						;if remainder > 0, will need extra (non-full) row
SetRows:
	mov		edi, eax				;edi is number of rows we'll need

	;determine number of rows
	mov		eax, [ebp+12]			;count parameter, as dividend
	cdq
	div		edi						;number of rows, as divisor
	cmp		edx, 0					;check remainder
	jz		SetCols					;if remainder == 0, eax is number of cols needed
	inc		eax						;if remaidner > 0, will need extra (non-full) col
SetCols:
	mov		edx, eax				;edx is the number of cols we'll need


	mov		ebx, 0					;index counter
	mov		ecx, edi				;set outer loop to number of rows
PrintRow:
	push	ecx						;preserve current row count within row loop
	mov		ecx, edx				;set inner loop to number of cols

PrintCol:
	cmp		ebx, [ebp+12]			;compare index counter to total size of array
	jae		EarlyFinish				;if current index >= total size, we're done printing values
	mov		eax, [esi+ebx*4]		;move current index (*4 for DWORD) to printing register
	call	WriteDec
	mov		al, ' '					;write four spaces
	call	WriteChar
	call	WriteChar
	call	WriteChar
	call	WriteChar
	add		ebx, edi				;increment index by number of rows (for printing down cols)
	loop	PrintCol
	pop		ecx						;restore outer loop counter after inner loop down

	call	CrLf
	mov		ebx, edi				;move number of rows to index counter register
	sub		ebx, ecx				;subtract current counter value
	inc		ebx						;add one to get current row value/starting index value for row
	loop	PrintRow
	jmp		Done

EarlyFinish:
	pop		ecx						;pop outer loop counter (pop skipped by jmp)
	call	CrLf

Done:
	call	CrLf
	popad
	leave
	ret		12						;clean up 3 parameters on stack
DisplayList ENDP


;--------------------------------------------------------------
;SortList(DWORD[] array, DWORD count)
;	Sorts a list of values in descending order
;	(calls to QuickSort)
;Receives:
;	array of values
;	count is length of array
;Returns:
;	array values are sorted in descending order
;Preconditions:
;	None
;Registers Changed:
;	None
;--------------------------------------------------------------
SortList PROC
	enter	0,0
	push	ecx

	mov		ecx, [ebp+12]			;count parameter
	dec		ecx						;decrement to get final index of array
	shl		ecx, 2					;multiple by 4 to get size of array
	add		ecx, [ebp+8]			;add starting address to get final address of array

	mov		esi, [ebp+8]			;array parameter

	push	ecx						;end pointer
	push	[ebp+8]					;start pointer
	call	QuickSort

	pop		ecx
	leave
	ret		8						;clean up 2 parameters on stack
SortList ENDP


;--------------------------------------------------------------
;QuickSort(DWORD* start, DWORD* end)
;	Implementation of the QuickSort algorithm (descending order)
;Receives:
;	start address of first element in list to sort
;	end address of last element in list to sort
;Returns:
;	values between start and end (inclusive) are sorted in descending order
;Preconditions:
;	None
;Registers Changed:
;	None
;--------------------------------------------------------------
QuickSort PROC
	enter 0, 0
	pushad

	mov		eax, [ebp+8]			;start parameter
	mov		ebx, [ebp+12]			;end parameter

	cmp		eax, ebx				;if start >= end, 1 or fewer items, Done
	jae		Done

	mov		edx, [eax]				;pivot value (using first value as pivot)
	add		eax, 4					;set eax to left checker (first value after pivot)

CheckLeft:
	cmp		[eax], edx
	jb		CheckRight				;if left checker value is bigger than pivot, check right checker
	add		eax, 4					;otherwise, move left checker right one
	cmp		eax, ebx
	ja		FinalSwap				;if left checker has moved past right right checker, found location for pivot
	jmp		CheckLeft				;otherwise, continue with left checker

CheckRight:
	cmp		[ebx], edx
	ja		Swap					;if right checker value is less than pivot, swap right checker and let checker values
	sub		ebx, 4					;otherwise, move right checker left one
	cmp		ebx, [ebp+8]
	je		FinalSwap				;if left checker is pointing at pivot, found location for pivot
	jmp		CheckRight				;otheriwse, continue with right checker

Swap:
	cmp		eax, ebx
	ja		FinalSwap				;if left checker has moved past right right checker, found location for pivot
	push	ebx						;b argument
	push	eax						;a argument
	call	Exchange
	jmp		CheckLeft				;continue looking for swaps

FinalSwap:							;wall position is in ebx, swap with pivot
	push	ebx						;b argument, pivot target location
	push	[ebp+8]					;a argument, pivot current location
	call	Exchange

	sub		ebx, 4					;get right edge of remaining items left of placed pivot
	push	ebx						;end argument
	push	[ebp+8]					;start argument is beginning of current list
	call	QuickSort				;recursive call to sort remaining left-side items

	push	[ebp+12]				;end argument is end of current list
	add		ebx, 8					;get left edge of remaining items right of placed pivot
	push	ebx						;start argument
	call	QuickSort				;recursive call to sort remaining right-side items

Done:
	popad
	leave
	ret		8						;clean up 2 parameters on stack
QuickSort ENDP


;--------------------------------------------------------------
;Exchange(DWORD* a, DWORD* b)
;	Exchanges the values of 2 memory locations
;Receives:
;	a and b are pointers to 2 memory locations
;Returns:
;	values of items at pointers a and b are exchanged
;Preconditions:
;	None
;Registers Changed:
;	None
;--------------------------------------------------------------
Exchange PROC
	enter 0, 0
	push	eax
	push	ecx
	push	edx

	mov		ecx, [ebp+8]			;a value dereferenced
	mov		edx, [ebp+12]			;b value dereferenced

	mov		eax, [ecx]				;move a to register
	xchg	eax, [edx]				;exchange a value in eax with b value
	mov		[ecx], eax				;move b value to a register

	pop		edx
	pop		ecx
	pop		eax
	leave
	ret		8						;clean up 2 parameters on stack
Exchange ENDP


;--------------------------------------------------------------
;DisplayMedian(DWORD[] array, DWORD count)
;	Finds and displays the median of an array of sorted values
;Receives:
;	array is sorted array
;	count is size of array
;Returns:
;	None
;Preconditions:
;	None
;Registers Changed:
;	None
;--------------------------------------------------------------
DisplayMedian PROC
	enter 0, 0
	pushad

	mov		edx, OFFSET median			;display median text
	call	WriteString

	mov		esi, [ebp+8]				;array parameter
	mov		eax, [ebp+12]				;count parameter, as dividend
	cdq
	mov		ebx, 2						;2 is divisor
	div		ebx							;divide to to middle of list

	mov		ebx, [esi+eax*4]			;set ebx to either middle of odd-length list or one past middle of even-length list

	cmp		edx, 0
	jz		IsEven						;if remainder == 0, list is even-length

	mov		eax, ebx					;otherwise is odd, and ebx is median
	jmp		PrintMedian

IsEven:
	dec		eax							;decrement eax to index of one before middle of even-length list
	mov		ecx, [esi+eax*4]			;load value of one before middle
	mov		eax, ecx
	add		eax, ebx					;add one before middle to one after middle, as divisor
	cdq
	mov		ebx, 2
	div		ebx							;divide by 2 to get average value

	cmp		edx, 0
	jz		PrintMedian					;if remainder == 0, no rounding needed
	inc		eax							;otherwise, round median up

PrintMedian:
	call	WriteDec					;display median

Done:
	mov		al, '.'						;terminal period on sentence
	call	WriteChar
	call	CrLf
	call	CrLf
	popad
	leave
	ret		8							;clean up 2 parameters on stack
DisplayMedian ENDP

END main
