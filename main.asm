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

MAX_STR_LENGTH = 100
filename BYTE MAX_STR_LENGTH+1 DUP (?)

USER_INPUT_LENGTH = 1
userInput BYTE USER_INPUT_LENGTH+1 DUP (?)

GameBoardPtr DWORD ?

.CODE

main PROC

  call UTIL_SetColor

	call PrintTitleLogo

	call PrintStartMenu
	call ProcessStartUserInput
	.IF (eax == 1)
	  STARTNEWGAME:
	  call ProcessFilenameInput
		jmp BOARDCREATED
	.ELSEIF (eax == 2)
	  jmp quit
	.ENDIF

	BOARDCREATED:
	mov GameBoardPtr, eax

	GAMELOOP:
	  call CLRSCR
	  push GameBoardPtr
		call B_PrintBoard

	  call PrintGameMenu
		call ProcessGameUserInput
		.IF (eax == 1)
			jmp STARTNEWGAME
		.ELSEIF (eax == 2)
			jmp GAMELOOP
		.ELSEIF (eax == 3)
		  push GameBoardPtr
			call B_SwapUp
			jmp GAMELOOP
		.ELSEIF (eax == 4)
		  push GameBoardPtr
			call B_SwapDown
			jmp GAMELOOP
		.ELSEIF (eax == 5)
		  push GameBoardPtr
			call B_SwapLeft
			jmp GAMELOOP
		.ELSEIF (eax == 6)
		  push GameBoardPtr
			call B_SwapRight
			jmp GAMELOOP
		.ELSEIF (eax == 7)
			jmp quit
		.ENDIF
		
	ENDGAMELOOP:

	jmp quit
	WIN:

  quit:
  EXIT
main ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
PrintTitleLogo PROC
; - - - - - - - - - - - - - - - - - - - - - - - - -
  mWriteLn "WELCOME TO THE MASM SLIDING PUZZLE"
	mWriteLn "----------------------------------"
	RET
PrintTitleLogo ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
PrintStartMenu PROC
; - - - - - - - - - - - - - - - - - - - - - - - - -
  mWriteLn "a) Start new game (S)"
	mWriteLn "b) End Game (E)"
	RET 
PrintStartMenu ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
ProcessStartUserInput PROC uses edx
; @returns EAX - 1: S, 2: E
; - - - - - - - - - - - - - - - - - - - - - - - - -

  INPUTSTART:
	mov edx, OFFSET userInput
	push USER_INPUT_LENGTH
	push edx
	call UTIL_ReadString

	; Moves user input to eax
	; Moves to uppercase if lowercase input
	movzx eax, BYTE PTR [edx]
	.IF (eax >= 91)
	  sub eax, 32
	.ENDIF

	.IF (eax == 83) ; S
	  mov eax, 1
		jmp QUIT
	.ELSEIF (eax == 69) ; E
	  mov eax, 2
	  jmp QUIT
	.ELSE
	  mWriteLn "Invalid Input! Try again: "
		jmp INPUTSTART
	.ENDIF

	QUIT:
	RET
ProcessStartUserInput ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
ProcessFilenameInput PROC uses edx
; Asks for filename, and creates an board object if exists
; @return eax - Pointer to board instance
; - - - - - - - - - - - - - - - - - - - - - - - - -
  INPUTSTART:
	mWrite "Name of file to open? : "
	mov edx, OFFSET filename

	push MAX_STR_LENGTH
	push edx
	call UTIL_ReadString
	call CRLF

	; Create board object and save in stack
	call B_CreateObj
	push eax 

	mov edx, OFFSET filename
	push edx
	push eax
	call B_ReadFile
	
	; If failed the read file, delete the created object
	.IF (eax == 0) 
		call B_DeleteObj
		jmp INPUTSTART
	.ENDIF
	
	pop eax

	QUIT:
	RET
ProcessFilenameInput ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
PrintGameMenu PROC 
; - - - - - - - - - - - - - - - - - - - - - - - - -
  mWriteLn "a) Start new game (S)"
	mWriteLn "b) Print Map (P)"
	mWriteLn "c) Move Up (U)"
	mWriteLn "d) Move Down (D)"
	mWriteLn "e) Move Left (L)"
	mWriteLn "f) Move Right (R)"
	mWriteLn "g) End Game (E)"
	RET 
PrintGameMenu ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
ProcessGameUserInput PROC uses edx
; @returns EAX -
;  1: S	 | 3: U	 | 5: L	 | 7: E
;  2: P	 | 4: D	 | 6: R  |
; - - - - - - - - - - - - - - - - - - - - - - - - -
  INPUTSTART:
	mov edx, OFFSET userInput
	push USER_INPUT_LENGTH
	push edx
	call UTIL_ReadString

	; Moves user input to eax
	; Moves to uppercase if lowercase input
	movzx eax, BYTE PTR [edx]
	.IF (eax >= 91)
	  sub eax, 32
	.ENDIF

	; Sets eax to a different value for each input
	.IF (eax == 83) ; S
	  mov eax, 1
		jmp QUIT
	.ELSEIF (eax == 80) ; P
	  mov eax, 2
	  jmp QUIT
	.ELSEIF (eax == 85) ; U
	  mov eax, 3
	  jmp QUIT
	.ELSEIF (eax == 68) ; D
	  mov eax, 4
	  jmp QUIT
	.ELSEIF (eax == 76) ; L
	  mov eax, 5
	  jmp QUIT
	.ELSEIF (eax == 82) ; R
	  mov eax, 6
	  jmp QUIT
	.ELSEIF (eax == 69) ; E
	  mov eax, 7
	  jmp QUIT
	.ELSE
	  mWriteLn "Invalid Input! Try again: "
		jmp INPUTSTART
	.ENDIF

	QUIT:
	RET
ProcessGameUserInput ENDP


END main