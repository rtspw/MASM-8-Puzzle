; - - - - - - - - - - - - - - - - - - - - - - - - -
; Structure Definitions
; - - - - - - - - - - - - - - - - - - - - - - - - -
MinHeap STRUCT
  VectorPtr DWORD ?
	HeapSize DWORD 0
MinHeap ENDS

; - - - - - - - - - - - - - - - - - - - - - -  - - -
; Procedure Prototypes
; - - - - - - - - - - - - - - - - - - - - - - - - -
; MinHeap Instances
MH_CreateObj PROTO
MH_DeleteObj PROTO

; MinHeap Methods
MH_Append PROTO
MH_Remove PROTO

; - - - - - - - - - - - - - - - - - - - - - -  - - -
; Private Methods
; - - - - - - - - - - - - - - - - - - - - - - - - -
; _MH_PercolateUp
; _MH_PercolateDown

; - - - - - - - - - - - - - - - - - - - - - - - - -
; Dependencies
; - - - - - - - - - - - - - - - - - - - - - - - - -
; Irvine32.inc
; Macros.inc
; Vector.inc
