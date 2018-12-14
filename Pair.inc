; Pair acts as a simple dynamically allocated
; container for a board and vector objects

; - - - - - - - - - - - - - - - - - - - - - - - - -
; Structure Definitions
; - - - - - - - - - - - - - - - - - - - - - - - - -
Pair STRUCT
  BoardPtr DWORD ?
  VectorPtr DWORD ?
Pair ENDS

; - - - - - - - - - - - - - - - - - - - - - -  - - -
; Procedure Prototypes
; - - - - - - - - - - - - - - - - - - - - - - - - -
; MinHeap Instances
BV_CreateObj PROTO
BV_MakeCopy PROTO
BV_DeleteObj PROTO

; MinHeap Methods
BV_PushBack PROTO
BV_At PROTO
BV_Swap PROTO
BV_Pop PROTO
BV_Print PROTO

; - - - - - - - - - - - - - - - - - - - - - - - - -
; Dependencies
; - - - - - - - - - - - - - - - - - - - - - - - - -
; Irvine32.inc
; Macros.inc
