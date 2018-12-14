.386
.model flat, stdcall
.stack 4096

INCLUDE Irvine32.inc
INCLUDE Macros.inc
INCLUDE ByteVector.inc

.DATA

  hHeap HANDLE ?
  mainByteSize DWORD sizeof ByteVector

.CODE
; - - - - - - - - - - - - - - - - - - - - - - - - -
BV_CreateObj PROC uses ecx edx
; Allocates 8 Bytes and creates bytevector instance
; @return EAX - Address of new Vector Instance
; - - - - - - - - - - - - - - - - - - - - - - - - -

  INVOKE GetProcessHeap
  mov hHeap, eax

  INVOKE HeapAlloc, hHeap, HEAP_ZERO_MEMORY, mainByteSize

  mWrite "Creating new Byte Vector at: "
  call WriteHex
  call CRLF

  ; Creates dynamic array for instance's root
  push eax
  call _BV_Initialize

  ret
BV_CreateObj ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
BV_MakeCopy PROC uses ebx ecx edx ebp esi
; Creates a new vector instance with the same data
; @param this_ptr - Pointer to original instance
; @returns EAX - Pointer to new instance
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 0, 0
  ; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 28]

  ; Macros
  Instance EQU (ByteVector PTR [ebx])
  Iterator EQU esi
  ; *  *  *  *  *  *  *  *  *

  ; Sets up instance references
  mov ebx, this_ptr

  ; Sets up counter for looping through elements
  movzx ecx, Instance.VectorSize
  mov Iterator, Instance.Root

  ; Creates new object and stores in EAX
  call BV_CreateObj
  mWrite "  Created a copied byte vector object at : "
  call WriteHex
  call CRLF

  .IF (ecx == 0)
    mWriteLn "Error in ByteVector.MakeCopy()! Array is empty."
	jmp QUIT
  .ENDIF

  COPYLOOP:
    movzx edx, BYTE PTR [Iterator]
    push edx
	push eax
	call BV_PushBack
	inc Iterator
	loop COPYLOOP

  QUIT:
  LEAVE
  RET 4

BV_MakeCopy ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
BV_DeleteObj PROC uses eax ebx ecx ebp
; Frees the heap for the corresponding handle
; @param this_ptr - Pointer to address in heap
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 0, 0

  ; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 24]

  ; Macros
  Instance EQU (ByteVector PTR [ebx])
  ; *  *  *  *  *  *  *  *  *

  mov ebx, this_ptr

  ; Frees the handle for the vector root
  INVOKE HeapFree, hHeap, 0, Instance.Root
  .IF eax == 0
    mWriteLn "Failed to free heap for bVector root"
	jmp QUIT
  .ENDIF

  INVOKE HeapFree, hHeap, 0, this_ptr
  .IF eax == 0
    mWriteLn "Failed to free heap for bVector"
  .ENDIF

  QUIT:
  LEAVE
  RET 4
BV_DeleteObj ENDP



; MEMBER PROCEDURES - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

; - - - - - - - - - - - - - - - - - - - - - - - - -
BV_PushBack PROC uses ebp eax ebx ecx esi
; Adds a byte to the ByteVector
; @param this_ptr - Address of byteVector Instance
; @param val - DWORD to add to bytevector
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 4, 0
  ; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 28]
  val EQU [ebp + 32]
  
  ; Local
  InsertionOffset EQU [ebp - 4]

  ; Macros
  Instance EQU (ByteVector PTR [ebx])
  Iterator EQU esi
  ; *  *  *  *  *  *  *  *  *

  ; Move 'this' to ebx to use as instance reference
  mov ebx, this_ptr

  ; Calculate insertion offset (Root + Size)
  movzx eax, Instance.VectorSize
  mov InsertionOffset, eax

  ; Insert into instance root array with offset
  mov Iterator, Instance.Root
  add Iterator, InsertionOffset

  mov al, val
  mov BYTE PTR [Iterator], al

  ; Update Instance member variables
  inc Instance.VectorSize

  ; Compares Vector Size to Capacity
  ; If they equal, create new dynamic array with expanded capacity
  ; and copy the original contents into it
  movzx eax, Instance.VectorSize
  movzx ecx, Instance.VectorCapacity

  .IF (eax == ecx)
    push ebx
	call _BV_ExpandCapacity
  .ENDIF

  LEAVE
  RET 8
BV_PushBack ENDP


; - - - - - - - - - - - - - - - - - - - - - - - - -
BV_At PROC uses ebx edx ebp esi
; Returns the value of the element at the index
; @param this_ptr - Address of instance
; @param index - Index of value to return
; @returns EAX - Value at index
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 0, 0
  ; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 24]
  index EQU [ebp + 28]

  ; Macros
  Instance EQU (ByteVector PTR [ebx])
  IndexAddress EQU esi
  ; *  *  *  *  *  *  *  *  *

  ; Set up instance for the bytevector ptr
  mov ebx, this_ptr

  ; Adds offset to IndexAddress 
  mov IndexAddress, Instance.Root
  add IndexAddress, index

  ; Sets EAX equal to value at index
  movzx eax, BYTE PTR [IndexAddress]

  LEAVE
  RET 8
BV_At ENDP


; - - - - - - - - - - - - - - - - - - - - - - - - -
BV_Swap PROC uses eax ebx ecx edx ebp esi
; Swap the elements at the two given indicies
; @param this_ptr - Address of instance
; @param idx1 - Index of first element
; @param idx2 - Index of second element
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 8, 0
	; *  *  *  *  *  *  *  *  *
  ; Parameters
	this_ptr EQU [ebp + 32]
  idx1 EQU [ebp + 36]
  idx2 EQU [ebp + 40]

	; Locals
	val1 EQU [ebp - 4]
	val2 EQU [ebp - 8]

  ; Macros
  Instance EQU (ByteVector PTR [ebx])
  RootAddress EQU esi
  ; *  *  *  *  *  *  *  *  *

	mov ebx, this_ptr
  mov RootAddress, Instance.Root

	; Get value at first address
	push idx1
	push ebx
	call BV_At
	mov val1, eax

	; Get value at second Address 
	push idx2
	push ebx
	call BV_At
	mov val2, eax

	; Set value at idx1 to val2
	mov eax, RootAddress
	mov edx, idx1
	add eax, edx
	mov dl, val2
	mov BYTE PTR [eax], dl

	; Set value at idx2 to val1
	mov eax, RootAddress
	mov edx, idx2
	add eax, edx
	mov dl, val1
	mov BYTE PTR [eax], dl

	LEAVE
	RET 12
BV_Swap ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
BV_Pop PROC uses ebx ecx
; Removes and returns last element in byte vector
; @param this_ptr - Address of instance
; @return EAX - Value of popped element, 0 if error
; - - - - - - - - - - - - - - - - - - - - - - - - -
	ENTER 0, 0 ; NO LOCALS
	; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 16]

  ; Macros
  Instance EQU (ByteVector PTR [ebx])
  RootAddress EQU esi
  ; *  *  *  *  *  *  *  *  *

	mov ebx, this_ptr
	movzx ecx, Instance.VectorSize

	; Throws if vector is empty
  .IF (ecx == 0)
	  mWriteLn "Error in BV_Pop! Empty Vector"
		mov eax, 0
	  jmp QUIT
	.ENDIF

	; Get last element in vector
	dec ecx
	push ecx
	push this_ptr
	call BV_At

	; Pop last element
	mov Instance.VectorSize, cx

	QUIT:
	LEAVE
	RET 4 ;ONE PARAMETER
BV_Pop ENDP


; - - - - - - - - - - - - - - - - - - - - - - - - -
BV_Print PROC uses eax ebx ecx ebp esi
; Prints the vector as is
; @param this_ptr - Address of instance
; - - - - - - - - - - - - - - - - - - - - - - - - -
	ENTER 0, 0 ; NO LOCALS
	; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 28]

  ; Macros
  Instance EQU (ByteVector PTR [ebx])
  RootIter EQU esi
  ; *  *  *  *  *  *  *  *  *

	mov ebx, this_ptr
	mov RootIter, Instance.Root

	movzx ecx, Instance.VectorSize

	.IF (ecx == 0)
	  mWriteLn "Array is empty"
	  jmp QUIT
	.ENDIF

	mWrite "| "
	PRINTLOOP:

	movzx eax, BYTE PTR [RootIter]
	call WriteDec
	mWrite " | "
	inc RootIter
	loop PRINTLOOP

	QUIT:
	LEAVE
	RET 4 ; One Parameter
BV_Print ENDP


; PRIVATE PROCEDURES - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

; - - - - - - - - - - - - - - - - - - - - - - - - -
_BV_Initialize PROC uses eax ebp esi
; Puts default values into allocated heap space
; Creates a new dynamic array
; @param handle_address - Pointer to heap handle
; @return EAX - Address of new Vector Instance
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 0, 0

  ; *  *  *  *  *  *  *  *  *
  ; Parameters
  handle_address EQU [ebp + 20]

  ; Macros
  HeapAddress EQU esi
  
  ; Constants
  StartingCapacity EQU 4
  ; *  *  *  *  *  *  *  *  *

  ; Initialize iterator esi with the allocated address
  mov esi, handle_address

  ; Request space for dynamic array of size "capacity"
  ; If successful, store in ByteVector Object
  INVOKE HeapAlloc, hHeap, HEAP_ZERO_MEMORY, StartingCapacity
  .IF eax == NULL
	 ;mWriteLn "Failed to allocate vector root heap!"
	 ;jmp QUIT
  .ELSE

    mWrite "  Creating root dynamic array at (4 bytes): "
	  call WriteHex
	  call CRLF

    mov DWORD PTR [esi], eax
	  add esi, TYPE DWORD
  .ENDIF

  ; Adds Starting Capacity to Object
  ; Note Starting Size is skipped because the 
  ; allocated space is already zeroed
  add esi, TYPE WORD
  mov WORD PTR [esi], StartingCapacity

  QUIT:
  LEAVE
  RET 4
_BV_Initialize ENDP



; - - - - - - - - - - - - - - - - - - - - - - - - -
_BV_ExpandCapacity PROC uses eax ebx ecx ebp esi edi
; Creates a new dynamic array with double the capacity
; and replace the original root
; @param this_pointer - Pointer to byte vector instance
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 4, 0
  ; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_pointer EQU [ebp + 32]

  ; Locals
  new_array EQU [ebp - 4]

  ; Macros
  Instance EQU (ByteVector PTR [ebx])
  IterOld EQU esi
  IterNew EQU edi
  ; *  *  *  *  *  *  *  *  *

  mov ebx, this_pointer

  ; Initialize iterator esi with the allocated address
  mov IterOld, Instance.Root

  ; Double the capacity 
  mov ax, Instance.VectorCapacity
  shl ax, 1
  mov WORD PTR [Instance.VectorCapacity], ax

  ; Request space for dynamic array of new capacity
  ; If successful, store as new iterator and local
  movzx eax, Instance.VectorCapacity
  INVOKE HeapAlloc, hHeap, HEAP_ZERO_MEMORY, eax
  .IF eax == NULL
	mWriteLn "Failed to allocate expanded vector root heap!"
  	jmp QUIT
  .ELSE

    mWrite "  Creating expanded root vector at: "
	call WriteHex
	call CRLF

    mov new_array, eax
    mov IterNew, eax
  .ENDIF

  ; Use both iterators to copy old array into new array
  movzx ecx, Instance.VectorSize 
  COPYLOOP:
  mov al, BYTE PTR [IterOld]
  mov BYTE PTR [IterNew], al
  inc IterOld
  inc IterNew
  loop COPYLOOP
  
  ; Free the old array
  INVOKE HeapFree, hHeap, 0, Instance.Root
  .IF eax == 0
    mWriteLn "Failed to free heap for old bVector root during expansion"
	jmp QUIT
  .ENDIF
  
  ; Set instance root to new allocated array
  mov eax, new_array
  mov Instance.Root, eax

  QUIT:
  LEAVE
  RET 4
_BV_ExpandCapacity ENDP

end