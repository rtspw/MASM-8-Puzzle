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
; Pair Instances
P_CreateObj PROTO
P_DeleteObj PROTO

; Pair Methods
P_First PROTO
P_Second PROTO

; - - - - - - - - - - - - - - - - - - - - - - - - -
; Dependencies
; - - - - - - - - - - - - - - - - - - - - - - - - -
; Irvine32.inc
; Macros.inc
