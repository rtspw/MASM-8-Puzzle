.386
.model flat,stdcall
.stack 4096
ExitProcess proto, dwExitCode:dword


INCLUDE Irvine32.inc
INCLUDE Macros.inc

INCLUDE UtilProcedures.inc
INCLUDE ByteVector.inc
INCLUDE Vector.inc
INCLUDE Board.inc
INCLUDE MinHeap.inc

.DATA

MAX_STR_LENGTH = 100
filename BYTE MAX_STR_LENGTH+1 DUP (?)

USER_INPUT_LENGTH = 1
userInput BYTE USER_INPUT_LENGTH+1 DUP (?)

GameBoardPtr DWORD ?
numOfMoves DWORD 0

; Base board for pathfinding
currentBoard DWORD ?
priorityQueue DWORD ?

.CODE

main PROC

  call UTIL_SetColor

	STARTPROGRAM:
	call CLRSCR
	call PrintTitleLogo
	call PrintMetaMenu
	call ProcessMetaUserInput

	; Either run shortest path or manual gameplay
	.IF (eax == 1)
	  jmp ALGSTART
	.ELSEIF (eax == 2)
	  jmp GAMESTART
	.ENDIF
	jmp GAMESTART

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
; PATHFINDING
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
	ALGSTART:

	; Creates board from file
	call ProcessFilenameInput
	mov currentBoard, eax

	push currentBoard
	call B_PrintBoard
  
	push currentBoard
	call B_GetDistance
	.IF (eax == 0)
	  jmp TRIVIALSOLUTION
	.ENDIF

	call MH_CreateObj
	mov priorityQueue, eax

	STARTPATH:

	; Generate all possible children into minheap
	push priorityQueue
	push currentBoard
	call B_GenerateChildren

	; Delete current board
	push currentBoard
	call B_DeleteObj

	; Set new current board
	push priorityQueue
	call MH_Remove
	mov currentBoard, eax

	; Checks for the success condition
	push currentBoard
	call B_GetDistance
	.IF (eax == 0)
	  jmp SOLUTIONFOUND
	.ENDIF

	jmp STARTPATH
	SOLUTIONFOUND:
	  mWriteLn "SOLUTION FOUND"
		mWriteLn "-------------------"
		mWriteLn "1: Up | 2: Right | 3: Down | 4: Left"
		mWriteLn "-------------------"
		push currentBoard
		call B_PrintMoves
		call CRLF
	jmp FINISHED
	TRIVIALSOLUTION:
	  mWriteLn "Your board is already solved!"

	FINISHED:
	call WaitMsg
	jmp STARTPROGRAM
	jmp quit

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
 ;ALL GAME LINES BELOW
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

	GAMESTART:
	call PrintStartMenu
	call ProcessStartUserInput
	.IF (eax == 1)
	  STARTNEWGAME:

		mov numOfMoves, 0
	  call ProcessFilenameInput
		jmp BOARDCREATED

	.ELSEIF (eax == 2)
	  jmp quit

	.ENDIF

	BOARDCREATED:
	mov GameBoardPtr, eax

	GAMELOOP:
	  call CLRSCR

		inc numOfMoves

		; Check for win condition
		push GameBoardPtr
		call B_GetDistance
		.IF (eax == 0)
		  jmp WIN
		.ENDIF

		jmp ENDNONMOVEENTRY
		NONMOVEENTRY:
		  call CLRSCR
		ENDNONMOVEENTRY:

		; Print board representation
	  push GameBoardPtr
		call B_PrintBoard

		; Print and process selection
	  call PrintGameMenu
		call ProcessGameUserInput
		.IF (eax == 1)
			jmp STARTNEWGAME

		.ELSEIF (eax == 2)
		  call CLRSCR
			mWriteLn "Your move history: "
			mWriteLn "-------------------"
			mWriteLn "1: Up | 2: Right | 3: Down | 4: Left"
			call CRLF

			push GameBoardPtr
			call B_PrintMoves

			call CRLF
			call WaitMsg
			jmp NONMOVEENTRY

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
		mWriteLn "CONGRATULATIONS! YOU WIN!"
		mWrite "Number of moves: "

		; Prints number of moves taken
		dec numOfMoves
		mov eax, numOfMoves
		call WriteDec
		call CRLF

		; Print Move vector
		call CRLF
		mWriteLn "Up: 1, Right: 2, Down: 3, Left: 4"

		push GameBoardPtr
		call B_PrintMoves
		call CRLF
		call CRLF

		; Deletes board object
		push GameBoardPtr
		call B_DeleteObj

		; Restarts to start menu
		jmp GAMESTART

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
PrintMetaMenu PROC
; - - - - - - - - - - - - - - - - - - - - - - - - -
  mWriteLn "a) Solve a puzzle with the computer (C)"
	mWriteLn "b) Solve a puzzle yourself (Y)"
	RET
PrintMetaMenu ENDP

; - - - - - - - - - - - - - - - - - - - - - - - - -
ProcessMetaUserInput PROC uses edx
; @returns EAX - 1: C, 2: Y
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

	.IF (eax == 67) ; C
	  mov eax, 1
		jmp QUIT
	.ELSEIF (eax == 89) ; Y
	  mov eax, 2
	  jmp QUIT
	.ELSE
	  mWriteLn "Invalid Input! Try again: "
		jmp INPUTSTART
	.ENDIF

	QUIT:
	RET
ProcessMetaUserInput ENDP

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
	push eax

	; If the board is not solvable, delete and retry
	push eax
	call B_IsSolvable

	.IF (eax == 0)
	  mWrite "This puzzle is not solvable! Try another file."
		call CRLF
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