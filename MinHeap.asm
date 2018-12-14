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
	
	mov ebx, this_ptr
	inc Instance.HeapSize

	push val
	push Instance.VectorPtr
	call V_PushBack

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

	; Reset eax to popped value for return
	mov eax, popped_val

	QUIT:
	LEAVE
	RET 4 ; ONE PARAMETER
MH_Remove ENDP

end