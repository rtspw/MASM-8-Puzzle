; - - - - - - - - - - - - - - - - - - - - - - - - -
; Structure Definitions
; - - - - - - - - - - - - - - - - - - - - - - - - -
Vector STRUCT
  Root DWORD ?
  VectorSize DWORD 0
  VectorCapacity DWORD 4
Vector ENDS

; - - - - - - - - - - - - - - - - - - - - - -  - - -
; Procedure Prototypes
; - - - - - - - - - - - - - - - - - - - - - - - - -
; Vector Instances
V_CreateObj PROTO
V_MakeCopy PROTO
V_DeleteObj PROTO

; Vector Methods
V_PushBack PROTO
V_At PROTO
V_Swap PROTO
V_Pop PROTO
V_Print PROTO


; - - - - - - - - - - - - - - - - - - - - - - - - -
; Private Procedures
; - - - - - - - - - - - - - - - - - - - - - - - - -
; _V_Initialize
; _V_IncreaseCapacity