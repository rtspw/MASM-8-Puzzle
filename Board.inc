; - - - - - - - - - - - - - - - - - - - - - - - - -
; Structure Definitions
; - - - - - - - - - - - - - - - - - - - - - - - - -
Board STRUCT
  VectorPtr DWORD 0
	ZeroPos BYTE 0
	DirLock BYTE 0
	Distance BYTE 0
	Filler BYTE 0
	MoveVectorPtr DWORD 0
Board ENDS

; - - - - - - - - - - - - - - - - - - - - - -  - - -
; Procedure Prototypes
; - - - - - - - - - - - - - - - - - - - - - - - - -
; Board Instances
B_CreateObj PROTO
B_MakeCopy PROTO
B_DeleteObj PROTO
B_SetupBoard PROTO

; Board Methods
B_SwapUp PROTO
B_TestUp PROTO
B_SwapRight PROTO
B_TestRight PROTO
B_SwapDown PROTO
B_TestDown PROTO
B_SwapLeft PROTO
B_TestLeft PROTO
B_PrintBoard PROTO
B_PrintMoves PROTO
B_GetDistance PROTO
B_GetDirLock PROTO
B_IsSolvable PROTO

; File Methods
B_ReadFile PROTO

; - - - - - - - - - - - - - - - - - - - - - - - - -
; Private Procedures
; - - - - - - - - - - - - - - - - - - - - - - - - -
; _B_FindZeroPos
; _B_CalcDistance
; _B_CalcInversions

; - - - - - - - - - - - - - - - - - - - - - -  - - -
; DirLock Directions
; - - - - - - - - - - - - - - - - - - - - - - - - -
DIR_UP = 1
DIR_RIGHT = 2
DIR_DOWN = 3
DIR_LEFT = 4

; - - - - - - - - - - - - - - - - - - - - - - - - -
; Dependencies
; - - - - - - - - - - - - - - - - - - - - - - - - -
; Irvine32.inc
; Macros.inc
; ByteVector.inc


