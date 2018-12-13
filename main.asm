.386
.model flat,stdcall
.stack 4096
ExitProcess proto,dwExitCode:dword


INCLUDE Irvine32.inc
INCLUDE Macros.inc

INCLUDE UtilProcedures.inc
INCLUDE ByteVector.inc

.DATA

hHeap HANDLE ?
pArray DWORD ?
newHeap DWORD ?
str1 BYTE "Heap size is: ", 0

.CODE

main PROC

  call UTIL_SetColor

  mov ecx, 1000
  
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

quit:
  call WaitMsg
  EXIT
main ENDP
END main