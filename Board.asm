.386
.model flat, stdcall
.stack 4096

INCLUDE Irvine32.inc
INCLUDE Macros.inc
INCLUDE ByteVector.inc

INCLUDE Board.inc
INCLUDE MinHeap.inc

.DATA

  hHeap HANDLE ?

	; 12 Bytes
  mainByteSize DWORD sizeof Board

	; Max buffer size for read file
	BUFFERSIZE = 9
	buffer BYTE BUFFERSIZE+1 DUP(?)


.CODE

; Instance Methods - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; - - - - - - - - - - - - - - - - - - - - - - - - -
B_CreateObj PROC uses ecx esi edx
; Allocates 8 Bytes and creates Board instance
; @return EAX - Address of new board instance
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ; *  *  *  *  *  *  *  *  *
	; Macros
  NewInstanceAddress EQU esi
  ; *  *  *  *  *  *  *  *  *
  INVOKE GetProcessHeap
  mov hHeap, eax

  INVOKE HeapAlloc, hHeap, HEAP_ZERO_MEMORY, mainByteSize

  mWrite "Creating new Board at: "
  call WriteHex
  call CRLF

	mov NewInstanceAddress, eax

  ; Creates byteVector for VectorPtr member
  call BV_CreateObj
	mov DWORD PTR [NewInstanceAddress], eax

	; Creates byteVector for moveVectorPtr member
	call BV_CreateObj
	add NewInstanceAddress, 8
	mov DWORD PTR [NewInstanceAddress], eax

	; Restore original address in eax as return value
	sub NewInstanceAddress, 8
	mov eax, NewInstanceAddress

	RET
B_CreateObj ENDP


; - - - - - - - - - - - - - - - - - - - - - - - - -
B_MakeCopy PROC uses ebx ecx edx ebp esi
; Makes a copy instance of the current instance
; @param this_ptr - Address of current instance
; @return EAX - Address of new instance
; - - - - - - - - - - - - - - - - - - - - - - - - -
	ENTER 4, 0 ; 1 LOCAL
	; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 28]

	; Local
	CopyBoardPtr EQU [ebp - 4]
  
	; Macros
  Instance EQU (Board PTR [ebx])
	BVPtr EQU edx
	HeapIter EQU esi
  ; *  *  *  *  *  *  *  *  *

	mov ebx, this_ptr
	
	; Allocates new space for a copy
	INVOKE HeapAlloc, hHeap, HEAP_ZERO_MEMORY, mainByteSize

  mWrite "Creating new copy Board at: "
  call WriteHex
  call CRLF
	mov HeapIter, eax
	mov CopyBoardPtr, eax

	; Creates a copy of the bytevector
	mov BVPtr, Instance.VectorPtr
	push BVPtr
	call BV_MakeCopy

	; Stores copy of bytevector in board copy
	mov DWORD PTR [heapIter], eax
	add heapIter, TYPE DWORD

	; Copies zeropos, dirlock, and distance
	mov al, Instance.ZeroPos
	mov BYTE PTR [heapIter], al
	add heapIter, TYPE BYTE

  mov al, Instance.DirLock
	mov BYTE PTR [heapIter], al
	add heapIter, TYPE BYTE

	mov al, Instance.Distance
	mov BYTE PTR [heapIter], al
	add heapIter, TYPE WORD

	; Creates a copy of the Move Vector 
	mov BVPtr, Instance.MoveVectorPtr
	push BVPtr
	call BV_MakeCopy
	mov DWORD PTR [heapIter], eax

	; Restores address of new board to return EAX
	mov eax, CopyBoardPtr

	LEAVE
	RET 4 ; ONE PARAMETER
B_MakeCopy ENDP


; - - - - - - - - - - - - - - - - - - - - - - - - -
B_DeleteObj PROC uses eax ebx ecx ebp
; Frees the heap for the corresponding handle
; @param this_ptr - Pointer to address in heap
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 0, 0

  ; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 24]

  ; Macros
  Instance EQU (Board PTR [ebx])
  ; *  *  *  *  *  *  *  *  *

  mov ebx, this_ptr

	; Deletes byte vector objects
  push Instance.VectorPtr ; LEGAL?!
	call BV_DeleteObj

	push Instance.MoveVectorPtr
	call BV_DeleteObj

	; Deletes main object
  INVOKE HeapFree, hHeap, 0, this_ptr
  .IF eax == 0
    mWriteLn "Failed to free heap for Board Object"
  .ENDIF

  QUIT:
  LEAVE
  RET 4
B_DeleteObj ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
B_SetupBoard PROC uses eax ebx ecx ebp esi
; Inserts parameters into byte vector for board
; @param this_ptr - Instance address 
; @param v8 through v0 - Values to push into vector
; Note the values will be pushed in in-order (8 - 0)
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 4, 0 ; NO LOCALS
	; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 28]
	v8 EQU [ebp + 32]
	v7 EQU [ebp + 36]
	v6 EQU [ebp + 40]
	v5 EQU [ebp + 44]
	v4 EQU [ebp + 48]
	v3 EQU [ebp + 52]
	v2 EQU [ebp + 56]
	v1 EQU [ebp + 60]
	v0 EQU [ebp + 64]

	; Locals
	ByteVectorPtr EQU [ebp - 4]

  ; Macros
  Instance EQU (Board PTR [ebx])
	ValueIter EQU esi
  ; *  *  *  *  *  *  *  *  *

	mov ebx, this_ptr
	mov eax, Instance.VectorPtr
  mov ByteVectorPtr, eax

	; Sets up iter to go through value parameters
	mov ValueIter, ebp
	add ValueIter, 64 ; Set to v0

	; Push all value parameters into vector
	mov ecx, 9
	INITLOOP:
		push [ValueIter]
		push ByteVectorPtr
		call BV_PushBack

		sub ValueIter, TYPE DWORD
	loop INITLOOP

	push ebx
	call _B_FindZeroPos

	push ebx
	call _B_CalcDistance

	LEAVE
	RET 40 ; 10 PARAMETERS

B_SetupBoard ENDP


; BOARD METHODS - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; - - - - - - - - - - - - - - - - - - - - - - - - -
B_SwapUp PROC uses ebx edx ebp
; Swaps the zero position up a row
; @param this_ptr - Address of instance
; @return EAX - 1: success, 0: failed
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 4, 0 ; 1 LOCAL

  ; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 20]

	; Local
	BVPtr EQU [ebp - 4]

  ; Macros
  Instance EQU (Board PTR [ebx])
  ; *  *  *  *  *  *  *  *  *

	mov ebx, this_ptr
	movzx edx, Instance.ZeroPos
	mov eax, Instance.VectorPtr
	mov BVPtr, eax

	; Throw if zeropos is in top row
	.IF (edx < 3)
	  mov eax, 0
		jmp QUIT
	.ENDIF

	; Swap zeropos and zeropos - 3
	; then updates zeropos location
	push edx
	sub edx, 3
	mov BYTE PTR [Instance.ZeroPos], dl
	push edx
	push BVPtr
	call BV_Swap

	; Sets Dirlock for the board to UP
	mov BYTE PTR [Instance.DirLock], DIR_UP

	; Adds direction to the move vector
	movzx eax, Instance.DirLock
	push eax
	mov eax, Instance.MoveVectorPtr
	push eax
	call BV_PushBack

	; Gets new Distance
	push ebx
	call _B_CalcDistance

	; Sets eax as success
	mov eax, 1

	QUIT:
	LEAVE
	RET 4     ; 1 Param
B_SwapUp ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
B_TestUp PROC uses ebx edx ebp
; Tests if it is possible to move up
; @param this_ptr - Address of instance
; Return EAX - 1: Able, 0: Not Able
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 0, 0  ; NO LOCALS
	; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 20]

  ; Macros
  Instance EQU (Board PTR [ebx])
  ; *  *  *  *  *  *  *  *  *

	; Get zeropos into edx
	mov ebx, this_ptr
	movzx edx, Instance.ZeroPos

	; Throw if zeropos is in top row
	.IF (edx < 3)
	  mov eax, 0
		jmp QUIT
	.ENDIF

	mov eax, 1

	QUIT:
	LEAVE
	RET 4 ; ONE PARAM
B_TestUp ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
B_SwapRight PROC uses ebx ecx edx ebp
; Swaps the zero position right
; @param this_ptr - Address of instance
; @return EAX - 1: success, 0: failed
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 8, 0 ; 2 LOCAL

  ; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 24]

	; Local
	BVPtr EQU [ebp - 4]
	Mod3 EQU [ebp - 8]

  ; Macros
  Instance EQU (Board PTR [ebx])
  ; *  *  *  *  *  *  *  *  *

	; Get zeropos into edx
	mov ebx, this_ptr
	movzx edx, Instance.ZeroPos
	mov eax, Instance.VectorPtr
	mov BVPtr, eax

	; Gets modulo of zeropos % 3
	push eax
	  push edx
	    mov eax, edx
	    mov edx, 0
	    mov ecx, 3
			div ecx
			mov Mod3, edx
	  pop edx
	pop eax

	; Throw if zeropos is in right column
	mov ecx, Mod3
	.IF (ecx == 2)
	  mov eax, 0
		jmp QUIT
	.ENDIF

	; Swap zeropos and zeropos + 1
	; then updates zeropos location
	push edx
	add edx, 1
	mov BYTE PTR [Instance.ZeroPos], dl
	push edx
	push BVPtr
	call BV_Swap

	; Sets Dirlock for the board to RIGHT
	mov BYTE PTR [Instance.DirLock], DIR_RIGHT

	; Adds direction to the move vector
	movzx eax, Instance.DirLock
	push eax
	mov eax, Instance.MoveVectorPtr
	push eax
	call BV_PushBack

	; Gets new Distance
	push ebx
	call _B_CalcDistance

	; Sets eax as success
	mov eax, 1

	QUIT:
	LEAVE
	RET 4     ; 1 Param
B_SwapRight ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
B_TestRight PROC uses ebx ecx edx ebp
; Tests if it is possible to move right
; @param this_ptr - Address of instance
; Return EAX - 1: Able, 0: Not Able
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 4, 0  ; NO LOCALS
	; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 24]

	; Locals
	Mod3 EQU [ebp - 4]

  ; Macros
  Instance EQU (Board PTR [ebx])
  ; *  *  *  *  *  *  *  *  *

	; Get zeropos into edx
	mov ebx, this_ptr
	movzx edx, Instance.ZeroPos

	; Gets modulo of zeropos % 3
	push eax
	  push edx
	    mov eax, edx
	    mov edx, 0
	    mov ecx, 3
			div ecx
			mov Mod3, edx
	  pop edx
	pop eax

	; Throw if zeropos is in right column
	mov ecx, Mod3
	.IF (ecx == 2)
	  mov eax, 0
		jmp QUIT
	.ENDIF

	mov eax, 1

	QUIT:
	LEAVE
	RET 4 ; ONE PARAM
B_TestRight ENDP


; - - - - - - - - - - - - - - - - - - - - - - - - -
B_SwapDown PROC uses ebx edx ebp
; Swaps the zero position down a row
; @param this_ptr - Address of instance
; @return EAX - 1: success, 0: failed
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 4, 0 ; 1 LOCAL

  ; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 20]

	; Local
	BVPtr EQU [ebp - 4]

  ; Macros
  Instance EQU (Board PTR [ebx])
  ; *  *  *  *  *  *  *  *  *

	; Get zeropos into edx
	mov ebx, this_ptr
	movzx edx, Instance.ZeroPos
	mov eax, Instance.VectorPtr
	mov BVPtr, eax

	; Throw if zeropos is in bottom row
	.IF (edx > 5)
	  mov eax, 0
		jmp QUIT
	.ENDIF

	; Swap zeropos and zeropos + 3
	; then updates zeropos location
	push edx
	add edx, 3
	mov BYTE PTR [Instance.ZeroPos], dl
	push edx
	push BVPtr
	call BV_Swap

	; Sets Dirlock for the board to DOWN
	mov BYTE PTR [Instance.DirLock], DIR_DOWN

	; Adds direction to the move vector
	movzx eax, Instance.DirLock
	push eax
	mov eax, Instance.MoveVectorPtr
	push eax
	call BV_PushBack

	; Gets new Distance
	push ebx
	call _B_CalcDistance

	; Sets eax as success
	mov eax, 1

	QUIT:
	LEAVE
	RET 4     ; 1 Param
B_SwapDown ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
B_TestDown PROC uses ebx edx ebp
; Tests if it is possible to move down
; @param this_ptr - Address of instance
; Return EAX - 1: Able, 0: Not Able
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 0, 0  ; NO LOCALS
	; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 20]

  ; Macros
  Instance EQU (Board PTR [ebx])
  ; *  *  *  *  *  *  *  *  *

	; Get zeropos into edx
	mov ebx, this_ptr
	movzx edx, Instance.ZeroPos

	; Throw if zeropos is in top row
	.IF (edx > 5)
	  mov eax, 0
		jmp QUIT
	.ENDIF

	mov eax, 1

	QUIT:
	LEAVE
	RET 4 ; ONE PARAM
B_TestDown ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
B_SwapLeft PROC uses ebx ecx edx ebp
; Swaps the zero position left
; @param this_ptr - Address of instance
; @return EAX - 1: success, 0: failed
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 8, 0 ; 2 LOCAL

  ; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 24]

	; Local
	BVPtr EQU [ebp - 4]
	Mod3 EQU [ebp - 8]

  ; Macros
  Instance EQU (Board PTR [ebx])
  ; *  *  *  *  *  *  *  *  *

	; Get zeropos into edx
	mov ebx, this_ptr
	movzx edx, Instance.ZeroPos
	mov eax, Instance.VectorPtr
	mov BVPtr, eax

	; Gets modulo of zeropos % 3
	push eax
	  push edx
	    mov eax, edx
	    mov edx, 0
	    mov ecx, 3
			div ecx
			mov Mod3, edx
	  pop edx
	pop eax

	; Throw if zeropos is in right column
	mov ecx, Mod3
	.IF (ecx == 0)
	  mov eax, 0
		jmp QUIT
	.ENDIF

	; Swap zeropos and zeropos - 1
	; then updates zeropos location
	push edx
	sub edx, 1
	mov BYTE PTR [Instance.ZeroPos], dl
	push edx
	push BVPtr
	call BV_Swap

	; Sets Dirlock for the board to LEFT
	mov BYTE PTR [Instance.DirLock], DIR_LEFT

	; Adds direction to the move vector
	movzx eax, Instance.DirLock
	push eax
	mov eax, Instance.MoveVectorPtr
	push eax
	call BV_PushBack

	; Gets new Distance
	push ebx
	call _B_CalcDistance

	; Sets eax as success
	mov eax, 1

	QUIT:
	LEAVE
	RET 4     ; 1 Param
B_SwapLeft ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
B_TestLeft PROC uses ebx ecx edx ebp
; Tests if it is possible to move left
; @param this_ptr - Address of instance
; Return EAX - 1: Able, 0: Not Able
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 4, 0  ; NO LOCALS
	; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 24]

	; Locals
	Mod3 EQU [ebp - 4]

  ; Macros
  Instance EQU (Board PTR [ebx])
  ; *  *  *  *  *  *  *  *  *

	; Get zeropos into edx
	mov ebx, this_ptr
	movzx edx, Instance.ZeroPos

	; Gets modulo of zeropos % 3
	push eax
	  push edx
	    mov eax, edx
	    mov edx, 0
	    mov ecx, 3
			div ecx
			mov Mod3, edx
	  pop edx
	pop eax

	; Throw if zeropos is in right column
	mov ecx, Mod3
	.IF (ecx == 0)
	  mov eax, 0
		jmp QUIT
	.ENDIF

	mov eax, 1

	QUIT:
	LEAVE
	RET 4 ; ONE PARAM
B_TestLeft ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
B_PrintBoard PROC uses eax ebx ecx edx ebp esi
; Prints the board object to console
; @param this_ptr - Pointer to instance
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 4, 0 ; 1 LOCALS

  ; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 32] ; 6 offset

	; Local
	BVPtr EQU [ebp - 4]

  ; Macros
  Instance EQU (Board PTR [ebx])
	BVIter EQU esi
  ; *  *  *  *  *  *  *  *  *

	call CRLF

	; Set up local variables
	mov ebx, this_ptr
	mov BVIter, 0
	mov eax, Instance.VectorPtr
	mov BVPtr, eax

	; Iterate through bytevector
	mov ecx, 9

	mWrite "  "

	PRINTLOOP:
	push BVIter
	push BVPtr
	call BV_At
	call WriteDec
	mWrite "  " 

	; Prints NewLine every three items
	; Notes: Modulo required edx == 0
	;   Implicitly divides eax and stores
	;   remainder in edx
	mov eax, BVIter
	mov ebx, 3
	mov edx, 0
	div ebx
	.IF (edx == 2)
	  call CRLF
		call CRLF
		mWrite "  "
	.ENDIF

	inc BVIter
	loop PRINTLOOP

	call CRLF

	LEAVE
	RET 4     ; ONE PARAMETER
B_PrintBoard ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
B_PrintMoves PROC uses eax ebx ebp
; Prints the move vector using the BV_Print method
; @param this_ptr - Address of instance
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 0, 0 ; NO LOCALS
  ; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 20] ; 3 offset

  ; Macros
  Instance EQU (Board PTR [ebx])
  ; *  *  *  *  *  *  *  *  *
	mov ebx, this_ptr
	mov eax, Instance.MoveVectorPtr

	push eax
	call BV_Print

	LEAVE
	RET 4 ; ONE PARAM
B_PrintMoves ENDP


; - - - - - - - - - - - - - - - - - - - - - - - - -
B_GetDistance PROC uses ebx ebp
; Prints the board object to console
; @param this_ptr - Pointer to instance
; @return EAX - Distance member value
; - - - - - - - - - - - - - - - - - - - - - - - - -
	ENTER 0, 0 ; NO LOCALS
	; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 16] 

  ; Macros
  Instance EQU (Board PTR [ebx])
  ; *  *  *  *  *  *  *  *  *

	mov ebx, this_ptr
	movzx eax, Instance.Distance

	LEAVE
	RET 4 ; ONE PARAM
B_GetDistance ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
B_GetDirLock PROC uses ebx ebp
; Prints the board object to console
; @param this_ptr - Pointer to instance
; @return EAX - Distance member value
; - - - - - - - - - - - - - - - - - - - - - - - - -
	ENTER 0, 0 ; NO LOCALS
	; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 16] 

  ; Macros
  Instance EQU (Board PTR [ebx])
  ; *  *  *  *  *  *  *  *  *

	mov ebx, this_ptr
	movzx eax, Instance.DirLock

	LEAVE
	RET 4 ; ONE PARAM
B_GetDirLock ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
B_IsSolvable PROC uses ebx
; Checks if the board is solvable
; @param this_ptr - Address to instance
; @return EAX - 1: solvable, 0: not solvable
; - - - - - - - - - - - - - - - - - - - - - - - - -
	ENTER 0, 0 ; NO LOCALS
	; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 12] 

  ; Macros
  Instance EQU (Board PTR [ebx])
  ; *  *  *  *  *  *  *  *  *
	push this_ptr
	call _B_CalcInversions

	; True if the inversions are even
	test eax, 1
	jnz ISODD

	ISEVEN:
	  mov eax, 1
		jmp QUIT
	ISODD:
	  mov eax, 0
	QUIT:
	LEAVE
	RET 4 ; ONE PARAMETER
B_IsSolvable ENDP


; - - - - - - - - - - - - - - - - - - - - - - - - -
B_GenerateChildren PROC uses eax ebx ecx edx ebp
; Generates all possible children (possible swaps)
; by creating copies of the boards and
; appends it to a heap object
; @param this_ptr - Address of instance
; @param mh_ptr - Address of minheap instance
; - - - - - - - - - - - - - - - - - - - - - - - - -
	ENTER 0, 0 ; NO LOCALS
	; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 28] 
	mh_ptr EQU [ebp + 32]

  ; Macros
  Instance EQU (Board PTR [ebx])
  ; *  *  *  *  *  *  *  *  *
	
	mov ebx, this_ptr

	; Skip up child if not possible or previous location
	push this_ptr
	call B_TestUp

	.IF (eax == 0)
	  jmp MAKERIGHT
	.ENDIF

	movzx eax, Instance.DirLock
	.IF (eax == DIR_DOWN)
	  jmp MAKERIGHT
	.ENDIF

	; Makes a copy of the board and swaps up
  push this_ptr
	call B_MakeCopy

	push eax
	push eax
	call B_SwapUp
	pop eax

	; Adds board copy into pointer
	push eax
	push mh_ptr
	call MH_Append



	MAKERIGHT:

	push this_ptr
	call B_TestRight

	.IF (eax == 0)
	  jmp MAKEDOWN
	.ENDIF

	movzx eax, Instance.DirLock
	.IF (eax == DIR_LEFT)
	  jmp MAKERIGHT
	.ENDIF

	; Makes a copy of the board and swaps right
  push this_ptr
	call B_MakeCopy

	push eax
	push eax
	call B_SwapRight
	pop eax

	; Adds board copy into pointer
	push eax
	push mh_ptr
	call MH_Append



	MAKEDOWN:

	push this_ptr
	call B_TestDown

	.IF (eax == 0)
	  jmp MAKELEFT
	.ENDIF

	movzx eax, Instance.DirLock
	.IF (eax == DIR_UP)
	  jmp MAKELEFT
	.ENDIF

  ; Makes a copy of the board and swaps down
  push this_ptr
	call B_MakeCopy

	push eax
	push eax
	call B_SwapDown
	pop eax

	; Adds board copy into pointer
	push eax
	push mh_ptr
	call MH_Append



	MAKELEFT:

	push this_ptr
	call B_TestLeft

	.IF (eax == 0)
	  jmp QUIT
	.ENDIF

	movzx eax, Instance.DirLock
	.IF (eax == DIR_RIGHT)
	  jmp QUIT
	.ENDIF

	; Makes a copy of the board and swaps left
  push this_ptr
	call B_MakeCopy

	push eax
	push eax
	call B_SwapLeft
	pop eax

	; Adds board copy into pointer
	push eax
	push mh_ptr
	call MH_Append


	QUIT:
	LEAVE
	RET 8 ; TWO PARAMETERS

B_GenerateChildren ENDP




; FILE METHODS - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

; - - - - - - - - - - - - - - - - - - - - - - - - -
B_ReadFile PROC uses ebx ecx edx ebp esi
; Reads a board from a file and appends it to a Board object
; Note: The board object should have an empty byte vector!
; @param this_ptr - Address of instance
; @param file_name - Name of file to open (the offset)
; @return EAX - 1: Success, 0: Failed
; - - - - - - - - - - - - - - - - - - - - - - - - -
	ENTER 8, 0 ; TWO LOCAL
	; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 28]
	file_name EQU [ebp + 32]

	; Locals
	ByteVectorPtr EQU [ebp - 4]
	FileHandle EQU [ebp - 8]

  ; Macros
  Instance EQU (Board PTR [ebx])
	BufferIter EQU esi
  ; *  *  *  *  *  *  *  *  *

	mWriteLn "  Reading a text file..."
	; Stores board and vector pointers
	mov ebx, this_ptr
	mov eax, Instance.VectorPtr
	mov ByteVectorPtr, eax

	; Gets file handle for given file name
	mov edx, file_name
	call OpenInputFile

	.IF (eax == INVALID_HANDLE_VALUE)
	  mWriteLn "Error in B_ReadFile! Failed to open file"
		mov eax, 0 ; Failed return
		jmp QUIT
	.ENDIF

	mov FileHandle, eax

	; Reads file and puts result in buffer byte array
	; Sets carry flag to true if it throws
	; (This mutates EAX, ECX and EDX!)
	mov eax, FileHandle
	mov edx, OFFSET buffer
	mov ecx, BUFFERSIZE
	call ReadFromFile
	jc SHOWERRORMSG

	; Adds null terminator at the end
	mov buffer[9], 0

	; DEBUG: Write buffer to console
	mov edx, OFFSET buffer
	call WriteString
	call CRLF


	; Sets ESI to the address of the dynamic array
	; Then pushes each byte into the stack 
	mov ecx, 9
	mov BufferIter, OFFSET buffer

	FILETOBOARDLOOP:
		movzx eax, BYTE PTR [BufferIter]
		sub eax, 48  ; ASCII Number to Int
		push eax
		call WriteInt
		call CRLF
		inc BufferIter
	loop FILETOBOARDLOOP

	mov ebx, this_ptr
	push ebx
  call B_SetupBoard

	jmp QUIT
	SHOWERRORMSG:
	  call WriteWindowsMsg

	; Set success return value
	mov eax, 1

	QUIT:
	LEAVE
	RET 8 ; TWO PARAM
B_ReadFile ENDP



; PRIVATE PROCEDURES - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

; - - - - - - - - - - - - - - - - - - - - - - - - -
_B_FindZeroPos PROC uses eax ebx ecx edx ebp esi
; Linear search through the vector for the zero pos
; Then stores that position in member zeropos
; (ASSUMES BOARD VECTOR SET UP ALREADY)
; @param this_ptr - Address of instance
; - - - - - - - - - - - - - - - - - - - - - - - - -
	ENTER 0, 0 ; NO LOCALS!
  ; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 32]

  ; Macros
  Instance EQU (Board PTR [ebx])
	BVInstance EQU (ByteVector PTR [edx])
	Counter EQU eax
	SearchIter EQU esi
  ; *  *  *  *  *  *  *  *  *

	; Stores address of dynamic array in SearchIter
	mov ebx, this_ptr
	mov edx, Instance.VectorPtr
	mov SearchIter, BVInstance.Root

	; Loops through vector until 0 is found
	; Counter keeps track of current index
	mov Counter, 0
	movzx ecx, BVInstance.VectorSize

	SEARCHLOOP:
		movzx ebx, BYTE PTR [SearchIter]
		cmp ebx, 0
		je FOUND
		inc Counter
		inc SearchIter
	loop SEARCHLOOP

	jmp NOTFOUND

	FOUND:
	  mWrite "  Zeropos Found: "
	  call WriteInt
		call CRLF

		mov ebx, this_ptr
		mov Instance.ZeroPos, al
		jmp QUIT

	NOTFOUND:
	  mWriteLn "Error in B_FindZeroPos! Zero not found"

	QUIT:
	LEAVE
	RET 4 ; ONE PARAMETER
_B_FindZeroPos ENDP




; - - - - - - - - - - - - - - - - - - - - - - - - -
_B_CalcDistance PROC uses eax ebx ecx edx ebp esi
; Calculates and sets the board distance
; using the manhattan distance equation
; (ASSUMES BOARD VECTOR SET UP ALREADY)
; @param this_ptr - Address of instance
; - - - - - - - - - - - - - - - - - - - - - - - - -
  ENTER 36, 0 ; Nine LOCALS
  ; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 32]

	; Local
	row1 EQU [ebp - 4]
	row2 EQU [ebp - 8]
	col1 EQU [ebp - 12]
	col2 EQU [ebp - 16]
	term1 EQU [ebp - 20]
	term2 EQU [ebp - 24]
	atVal EQU [ebp - 28]
	BVPtr EQU [ebp - 32]
	totalDist EQU [ebp - 36]

  ; Macros
  Instance EQU (Board PTR [ebx])
	Iter EQU esi
  ; *  *  *  *  *  *  *  *  *

	mov ebx, this_ptr
	mov eax, Instance.VectorPtr
	mov BVPtr, eax

	; Initialize totalDist to 0
	; Initialize iter to 0
	mov eax, 0
	mov totalDist, eax
	mov Iter, 0
	mov ecx, 9

	; ForEach(Atval, Iter)
	MATHLOOP:  
	  push Iter
		push BVPtr
		call BV_At

		; Intepret 0 as 9
		.IF (eax == 0)
		  mov eax, 9
		.ENDIF

		mov atVal, eax
		
		; row1 = (x - 1) / 3
		dec eax
		mov edx, 0
		mov ebx, 3
		div ebx
		mov row1, eax
		
		; row2 = (idx / 3)
		mov eax, Iter
		mov edx, 0
		mov ebx, 3
		div ebx
		mov row2, eax

		; col1 = (x - 1) % 3
		mov eax, atVal
		dec eax
		mov edx, 0
		mov ebx, 3
		div ebx
		mov col1, edx

		; col2 = idx % 3
		mov eax, Iter
		mov edx, 0
		mov ebx, 3
		div ebx
		mov col2, edx

		; term1 = abs(row1 - row2)
		mov eax, row1
		mov ebx, row2
		sub eax, ebx
		cdq
		xor eax, edx
		sub eax, edx
		mov term1, eax

		; term2 = abs(col1 - col2)
		mov eax, col1
		mov ebx, col2
		sub eax, ebx
		cdq
		xor eax, edx
		sub eax, edx
		mov term2, eax

		; dist += term1 + term2
		mov eax, term1
		mov ebx, term2
		add eax, ebx
		mov ebx, totalDist
		add ebx, eax
		mov totalDist, ebx
	inc Iter
	; Jump destination is too far
	; Manual ecx handling
	dec ecx
	jnz MATHLOOP

	mov eax, totalDist
	mWrite "  Distance calculated: "
	call WriteDec
	call CRLF
	mov ebx, this_ptr
	mov Instance.Distance, al

	LEAVE
	RET 4 ; ONE PARAMETER
_B_CalcDistance ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
_B_CalcInversions PROC uses ebx ecx edx ebp 
; Calculates and returns the number of inversions
; This is used to determine whether the board is possible
; @param this_ptr - Address of instance
; @return EAX - Number of inversions
; - - - - - - - - - - - - - - - - - - - - - - - - -
	ENTER 8, 0 ; 2 LOCALS
  ; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 24]

	; Locals
	inversions EQU [ebp - 4]
	vptr EQU [ebp - 8]

  ; Macros
  Instance EQU (Board PTR [ebx])
  ; *  *  *  *  *  *  *  *  *
	mov ebx, this_ptr
	mov eax, Instance.VectorPtr
	mov vptr, eax

	mov ecx, 0
	mov inversions, ecx
	OUTERLOOP:
	  mov edx, ecx
		inc edx
	  INNERLOOP:
			
			; if (vector[ecx] !== 0 and vector[edx] !== 0 and vector[ecx] > vector[edx])
			; EBX = vector[ecx]
			push ecx
			push vptr
			call BV_At
			cmp eax, 0
			je CONTINUEINNER
			mov ebx, eax

			; EAX = vector[edx]
			push edx
			push vptr
			call BV_At
			cmp eax, 0
			je CONTINUEINNER

			.IF (ebx > eax)
			  mov eax, inversions
				inc eax
			  mov inversions, eax
			.ENDIF

			CONTINUEINNER:
			inc edx
			cmp edx, 9
			jge EXITINNER
			jmp INNERLOOP
		EXITINNER:

		inc ecx
		cmp ecx, 8
		jge EXITLOOP
		jmp OUTERLOOP
	EXITLOOP:

	mov eax, inversions

	LEAVE
	RET 4 ; One parameter
_B_CalcInversions ENDP

end