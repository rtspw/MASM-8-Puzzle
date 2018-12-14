
; - - - - - - - - - - - - - - - - - - - - - - - - -
; Structure Definitions
; - - - - - - - - - - - - - - - - - - - - - - - - -
ByteVector STRUCT
  Root DWORD ?
  VectorSize WORD 0
  VectorCapacity WORD 4
ByteVector ENDS

; - - - - - - - - - - - - - - - - - - - - - -  - - -
; Procedure Prototypes
; - - - - - - - - - - - - - - - - - - - - - - - - -
; Vector Instances
BV_CreateObj PROTO
BV_MakeCopy PROTO
BV_DeleteObj PROTO

; Vector Methods
BV_PushBack PROTO
BV_At PROTO
BV_Swap PROTO
BV_Pop PROTO
BV_Print PROTO


; - - - - - - - - - - - - - - - - - - - - - - - - -
; Private Procedures
; - - - - - - - - - - - - - - - - - - - - - - - - -
; _BV_Initialize
; _BV_IncreaseCapacity


; - - - - - - - - - - - - - - - - - - - - - - - - -
; Dependencies
; - - - - - - - - - - - - - - - - - - - - - - - - -
; Irvine32.inc
; Macros.inc


