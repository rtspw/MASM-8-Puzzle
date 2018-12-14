.386
.model flat, stdcall
.stack 4096

INCLUDE Irvine32.inc
INCLUDE Macros.inc
INCLUDE Vector.inc

INCLUDE Board.inc

INCLUDE MinHeap.inc

.DATA

  hHeap HANDLE ?
  mainByteSize DWORD sizeof MinHeap

.CODE

; Instance Methods - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

; - - - - - - - - - - - - - - - - - - - - - - - - -
MH_CreateObj PROC uses ebx ecx edx ebp
; Allocates 8 Bytes and creates a minheap instance
; @return EAX - Address of new Pair Instance
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 0, 0
  ; *  *  *  *  *  *  *  *  *
  ; Macros
  Instance EQU (MinHeap PTR [ebx])
  ; *  *  *  *  *  *  *  *  *

  INVOKE GetProcessHeap
  mov hHeap, eax

  INVOKE HeapAlloc, hHeap, HEAP_ZERO_MEMORY, mainByteSize

  mWrite "Creating new MinHeap Object at: "
  call WriteHex
  call CRLF

	mov ebx, eax

	; Creates DWORD vector object as VectorPtr value
	call V_CreateObj
	mov Instance.VectorPtr, eax

	; Adds an alignment zero to the vector
	; and resets length to zero
	push 0
	push eax
	call V_PushBack

	mov Instance.HeapSize, 0

	mov eax, ebx

	LEAVE
  RET
MH_CreateObj ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
MH_DeleteObj PROC uses eax ebx ecx ebp
; Frees the heap for the corresponding handle
; Does not free any contained objects
; @param this_ptr - Pointer to address in heap
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 0, 0

  ; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 24]
  ; *  *  *  *  *  *  *  *  *

  ; Frees the handle for the pair
  INVOKE HeapFree, hHeap, 0, this_ptr
  .IF eax == 0
    mWriteLn "Failed to free heap for minheap object"
  .ENDIF

  QUIT:
  LEAVE
  RET 4
MH_DeleteObj ENDP



; MEMBER PROCEDURES - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

; - - - - - - - - - - - - - - - - - - - - - - - - -
MH_Append PROC uses eax ebx ecx ebp
; Adds a new element to the minheap and heapifies up
; @param this_ptr - Pointer to address in heap
; @param val - DWORD to push into minheap
; - - - - - - - - - - - - - - - - - - - - - - - - -
	ENTER 0, 0 ; NO LOCALS
	; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 24]
	val EQU [ebp + 28]

	; Macros
  Instance EQU (MinHeap PTR [ebx])
  ; *  *  *  *  *  *  *  *  *
	
	; Increments heapsize (always vectorsize - 1)
	mov ebx, this_ptr
	inc Instance.HeapSize

	; Adds value to vector
	push val
	push Instance.VectorPtr
	call V_PushBack

	; Heapify new element up
	push this_ptr
	call _MH_PercolateUp

	LEAVE
	RET 8 ; TWO PARAMS
MH_Append ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
MH_Remove PROC uses ebx ecx ebp 
; Removes the smallest element (first) and heapifies down
; @param this_ptr - Pointer to address in heap
; @return EAX - Smallest value popped from minheap
;               0: heap already empty
; - - - - - - - - - - - - - - - - - - - - - - - - -
	ENTER 8, 0 ; NO LOCALS
	; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 20]

	; Locals
	heap_vector EQU [ebp - 4]
	popped_val EQU [ebp - 8]

	; Macros
  Instance EQU (MinHeap PTR [ebx])
  ; *  *  *  *  *  *  *  *  *

	mov ebx, this_ptr
	mov eax, Instance.VectorPtr
	mov ecx, Instance.HeapSize
	mov heap_vector, eax

	; Throw if the array is already empty
	.IF (ecx == 0)
	  mov eax, 0
	  mWriteLn "Error in MH_Remove(). Heap Empty."
		jmp QUIT
	.ENDIF

	; Swaps first and last element
	push heap_vector
	call V_GetSize

	dec eax
	push eax
	push 1
	push heap_vector
	call V_Swap

	; Pops last element and stores in popped_val
	push heap_vector
	call V_Pop
	mov popped_val, eax

	dec Instance.HeapSize

	; Heapify down
	push this_ptr
	call _MH_PercolateDown

	; Reset eax to popped value for return
	mov eax, popped_val

	QUIT:
	LEAVE
	RET 4 ; ONE PARAMETER
MH_Remove ENDP


; PRIVATE PROCEDURES - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; - - - - - - - - - - - - - - - - - - - - - - - - -
_MH_PercolateUp PROC uses eax ebx ecx edx ebp 
; Moves the newly appended element up the tree
; according to minimum heap rules
; Uses the distance as the value weight
; @param this_ptr - Address to this
; - - - - - - - - - - - - - - - - - - - - - - - - -
	ENTER 8, 0 ; TWO LOCALS
	; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 28]

	; Locals
	index EQU [ebp - 4]
	parent EQU [ebp - 8]

	; Macros
  Instance EQU (MinHeap PTR [ebx])
  ; *  *  *  *  *  *  *  *  *

	mov ebx, this_ptr

	; Set index to heapsize (vectorSize - 1)
	mov eax, Instance.HeapSize
	mov index, eax

	; Set parent to index / 2 (logical shift right)
	shr eax, 1
	mov parent, eax

	; While Conditions: (JS Style)
	; while(parent !== 0 && (this.vector[index] < this.vector[parent])

	WHILESTART:
	  ; parent != 0
	  mov eax, parent
	  cmp eax, 0
	  je WHILEEND
	  
		; edx = vector[index]
	  mov ecx, index
		push ecx
		mov ecx, Instance.VectorPtr
		push ecx
		call V_At
		mov edx, eax

		; eax = vector[parent]
		mov ecx, parent
		push ecx
		mov ecx, Instance.VectorPtr
		push ecx
		call V_At

		; (edx < eax)?
		cmp edx, eax
		jge WHILEEND


		; V_Swap(this, parent, index);
		mov ecx, index
		push ecx
		mov ecx, parent
		push ecx
		mov ecx, Instance.VectorPtr
		push ecx
		call V_Swap

		; Set new index values before looping
		mov ecx, parent
		mov index, ecx

		shr ecx, 1
		mov parent, ecx

		jmp WHILESTART
	WHILEEND:

	LEAVE
	RET 4 ; ONE PARAMETER

_MH_PercolateUp ENDP


; - - - - - - - - - - - - - - - - - - - - - - - - -
_MH_PercolateDown PROC uses eax ebx ecx ebp
; Moves down the first element according to minheap rules
; @param this_ptr - Address to this
; - - - - - - - - - - - - - - - - - - - - - - - - -
	ENTER 16, 0 ; FOUR LOCALS
	; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 24]

	; Locals
	index EQU [ebp - 4]
	child EQU [ebp - 8]
	compareVal EQU [ebp - 12]
	vectoraddress EQU [ebp - 16]

	; Macros
  Instance EQU (MinHeap PTR [ebx])
  ; *  *  *  *  *  *  *  *  *

	mov ebx, this_ptr
	mov eax, Instance.VectorPtr
	mov vectoraddress, eax

	; index = 1
	mov ecx, 1
	mov index, ecx

	STARTLOOP:

	; child = 0
	; compareVal = 0
	mov ecx, 0
	mov child, ecx
	mov compareVal, ecx

	; eax = heapSize
  mov eax, Instance.HeapSize

	; (index * 2 <= heapSize) ?
	mov ecx, index
	shl ecx, 1
	.IF (ecx <= eax)
	  mov child, ecx
		push child
		push vectoraddress
		call V_At
		mov compareVal, eax
	.ENDIF

	inc ecx
	mov eax, Instance.HeapSize
	; (index * 2 + 1 <= heapSize && vector[index * 2 + 1] < compareVal)
	.IF (ecx <= eax)

	  ; eax = vector[index * 2 + 1]
	  push ecx
		push vectoraddress
		call V_At

		; ecx = compareVal
		mov ecx, compareVal

		.IF (eax < ecx)
		  mov eax, child
			inc eax
		  mov child, eax 
		.ENDIF
	.ENDIF

	; Break if childIndex !== 0
	mov eax, child
	cmp eax, 0
	je QUIT

	; Else, swap and reset loop
	push index
	push child
	push vectoraddress
	call V_Swap

	mov eax, child
	mov index, eax

	jmp STARTLOOP

	QUIT:
	LEAVE
	RET 4 ; ONE PARAMETER
_MH_PercolateDown ENDP

end