; Pair acts as a simple dynamically allocated
; container for a board and vector objects

; NOTE THAT THIS CLASS IS DEPRECATED !!!- - - - - - - -

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
; Instance methods
P_CreateObj PROTO
P_DeleteObj PROTO

; Object methods
P_First PROTO
P_Second PROTO

; - - - - - - - - - - - - - - - - - - - - - - - - -
; Dependencies
; - - - - - - - - - - - - - - - - - - - - - - - - -
; Irvine32.inc
; Macros.inc
