INCLUDE Irvine32.inc

.DATA
  LightBlueOnWhite DWORD lightBlue + (white * 16)

.CODE

UTIL_SetColor PROC
  mov EAX, LightBlueOnWhite
  call SetTextColor
  call CLRSCR
  RET
UTIL_SetColor ENDP

END