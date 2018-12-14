.386
.model flat, stdcall
.stack 4096

INCLUDE Irvine32.inc
INCLUDE Macros.inc
INCLUDE Pair.inc

.DATA

  hHeap HANDLE ?
  mainByteSize DWORD sizeof Pair

.CODE

; Instance Methods - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


; - - - - - - - - - - - - - - - - - - - - - - - - -
P_CreateObj PROC uses ebx ecx edx ebp
; Allocates 8 Bytes and creates pair
; @return EAX - Address of new Pair Instance
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 0, 0
  ; *  *  *  *  *  *  *  *  *
  ; Parameters
  board_ptr EQU [ebp + 24]
	vector_ptr EQU [ebp + 28]

  ; Macros
  Instance EQU (Pair PTR [ebx])
  ; *  *  *  *  *  *  *  *  *

  INVOKE GetProcessHeap
  mov hHeap, eax

  INVOKE HeapAlloc, hHeap, HEAP_ZERO_MEMORY, mainByteSize

  mWrite "Creating new Pair Object at: "
  call WriteHex
  call CRLF

	; Inserts pointers into pair object
	mov ebx, eax
	mov eax, board_ptr
	mov Instance.BoardPtr, eax
	mov eax, vector_ptr
	mov Instance.VectorPtr, eax
  mov eax, ebx

	LEAVE
  RET 8
P_CreateObj ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
P_DeleteObj PROC uses eax ebx ecx ebp
; Frees the heap for the corresponding handle
; THIS DOES NOT FREE THE POINTERS CONTAINED INSIDE
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
    mWriteLn "Failed to free heap for pair object"
  .ENDIF

  QUIT:
  LEAVE
  RET 4
P_DeleteObj ENDP



; MEMBER PROCEDURES - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

; - - - - - - - - - - - - - - - - - - - - - - - - -
P_First PROC uses ebx ecx edx ebp
; Returns the dword at the first location (boardptr)
; @return EAX - Board Pointer
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 0, 0
  ; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 24]

  ; Macros
  Instance EQU (Pair PTR [ebx])
  ; *  *  *  *  *  *  *  *  *

	mov ebx, this_ptr
	mov eax, Instance.BoardPtr

	LEAVE
	RET 4
P_First ENDP


; - - - - - - - - - - - - - - - - - - - - - - - - -
P_Second PROC uses ebx ecx edx ebp
; Returns the dword at the second location (vectorptr)
; @return EAX - Vector Pointer
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 0, 0
  ; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 24]

  ; Macros
  Instance EQU (Pair PTR [ebx])
  ; *  *  *  *  *  *  *  *  *

	mov ebx, this_ptr
	mov eax, Instance.VectorPtr

	LEAVE
	RET 4
P_Second ENDP

end