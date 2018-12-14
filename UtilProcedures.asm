INCLUDE Irvine32.inc

.DATA
  LightBlueOnWhite DWORD lightBlue + (white * 16)

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
	MaxLength EQU [ebp + 28]
	; * * * * * * * * * 

	mov edx, StrOffset
	mov ecx, MaxLength
	inc ecx
	call ReadString

	LEAVE
	RET 8
UTIL_ReadString ENDP

END