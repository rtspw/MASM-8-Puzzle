; - - - - - - - - - - - - - - - - - - - - - - - - -
; Structure Definitions
; - - - - - - - - - - - - - - - - - - - - - - - - -
Board STRUCT
  VectorPtr DWORD 0
	ZeroPos BYTE 0
	DirLock BYTE 0
	Distance BYTE 0
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
B_SwapRight PROTO
B_SwapDown PROTO
B_SwapLeft PROTO
B_PrintBoard PROTO

; File Methods
B_ReadFile PROTO

; - - - - - - - - - - - - - - - - - - - - - - - - -
; Private Procedures
; - - - - - - - - - - - - - - - - - - - - - - - - -
; _B_FindZeroPos
; _B_CalcDistance


; - - - - - - - - - - - - - - - - - - - - - - - - -
; Dependencies
; - - - - - - - - - - - - - - - - - - - - - - - - -
; Irvine32.inc
; Macros.inc
; ByteVector.inc


