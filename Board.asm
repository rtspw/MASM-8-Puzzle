.386
.model flat, stdcall
.stack 4096

INCLUDE Irvine32.inc
INCLUDE Macros.inc
INCLUDE ByteVector.inc

INCLUDE Board.inc

.DATA

  hHeap HANDLE ?

	; 8 Bytes (size is 7 bytes)
  mainByteSize DWORD sizeof Board + 1

	; Max buffer size for read file
	BUFFERSIZE = 9
	buffer BYTE BUFFERSIZE+1 DUP(?)


.CODE
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

	; Restore original address in eax as return value
	mov eax, NewInstanceAddress

	RET
B_CreateObj ENDP


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

	; Deletes byte vector object
  push Instance.VectorPtr ; LEGAL?!
	call BV_DeleteObj

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

	LEAVE
	RET 40 ; 10 PARAMETERS

B_SetupBoard ENDP






; FILE METHODS - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

; - - - - - - - - - - - - - - - - - - - - - - - - -
B_ReadFile PROC uses eax ebx ecx edx ebp esi
; Reads a board from a file and appends it to a Board object
; Note: The board object should have an empty byte vector!
; @param this_ptr - Address of instance
; @param file_name - Name of file to open (the offset)
; - - - - - - - - - - - - - - - - - - - - - - - - -
	ENTER 8, 0 ; TWO LOCAL
	; *  *  *  *  *  *  *  *  *
  ; Parameters
  this_ptr EQU [ebp + 32]
	file_name EQU [ebp + 36]

	; Locals
	ByteVectorPtr EQU [ebp - 4]
	FileHandle EQU [ebp - 8]

  ; Macros
  Instance EQU (Board PTR [ebx])
	BufferIter EQU esi
  ; *  *  *  *  *  *  *  *  *

	; Stores board and vector pointers
	mov ebx, this_ptr
	mov eax, Instance.VectorPtr
	mov ByteVectorPtr, eax

	; Gets file handle for given file name
	mov edx, file_name
	call OpenInputFile

	.IF (eax == INVALID_HANDLE_VALUE)
	  mWriteLn "Error in B_ReadFile! Failed to open file"
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

	QUIT:
	LEAVE
	RET 8 ; TWO PARAM
B_ReadFile ENDP
end