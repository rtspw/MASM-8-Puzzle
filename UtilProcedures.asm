INCLUDE Irvine32.inc

.DATA
  LightBlueOnWhite DWORD lightBlue + (white * 16)
	MAX_STR_LENGTH = 100

.CODE
; - - - - - - - - - - - - - - - - - - - - - - - - -
UTIL_SetColor PROC
; - - - - - - - - - - - - - - - - - - - - - - - - -
  mov EAX, LightBlueOnWhite
  call SetTextColor
  call CLRSCR
  RET
UTIL_SetColor ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
UTIL_ReadString PROC uses eax ecx edx ebp
; @param StrOffset - Offset of byte array string
; - - - - - - - - - - - - - - - - - - - - - - - - -
	ENTER 0, 0 
	; * * * * * * * * *
  StrOffset EQU [ebp + 24]
	; * * * * * * * * * 

	mov edx, StrOffset
	mov ecx, MAX_STR_LENGTH
	call ReadString

	LEAVE
	RET 4
UTIL_ReadString ENDP

END