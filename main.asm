.386
.model flat,stdcall
.stack 4096
ExitProcess proto, dwExitCode:dword


INCLUDE Irvine32.inc
INCLUDE Macros.inc

INCLUDE UtilProcedures.inc
INCLUDE ByteVector.inc
INCLUDE Board.inc

.DATA

hHeap HANDLE ?
pArray DWORD ?
newHeap DWORD ?
str1 BYTE "Heap size is: ", 0


MAX_STR_LENGTH = 100
filename BYTE MAX_STR_LENGTH+1 DUP (?)

.CODE

main PROC

  call UTIL_SetColor

	; BYTE VECTOR TESTS - - - - - - - - - - - - - - - - - -
  mov ecx, 100
  
  L1:
  call BV_CreateObj
  
  push 1
  push eax
  call BV_PushBack
  
  push 2
  push eax
  call BV_PushBack
  
  push 3
  push eax
  call BV_PushBack
  
  push 4
  push eax
  call BV_PushBack
  
  push 8
  push eax
  call BV_PushBack

	push 3
	push 1
	push eax
	call BV_Swap

	push eax
	push eax
  call BV_Pop
	pop eax

	push 19
	push eax
	call BV_PushBack

  push eax
  call BV_DeleteObj
  loop L1

	; - - - - - - - - - - - - - - - - - - - - - - -


	mWrite "Name of file to open? : "
	mov edx, OFFSET filename
	push edx
	call UTIL_ReadString
	call CRLF

	; BOARD TESTS - - - - - - - - - - - - - - - - - 
	mov ecx, 1
	L2:
	call B_CreateObj

	;push 1
	;push 2
	;push 3
	;push 4
	;push 5
	;push 6
	;push 7
	;push 8
	;push 0
	;push eax
 	;call B_SetupBoard

	mov edx, OFFSET filename
	push edx
	push eax
	call B_ReadFile

	push eax
	call B_DeleteObj
	loop L2
	; - - - - - - - - - - - - - - - - - - - - - - -

  quit:
  call WaitMsg
  EXIT
main ENDP
END main