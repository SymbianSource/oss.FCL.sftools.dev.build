; test arm assembler
;
; (C) Copyright Symbian Software Limited 2008. All rights reserved.
;
        AREA |.text|, CODE, READONLY, ALIGN=6

        CODE32

        ; UPT

;
;



;EXPORT fake_assembler_function1
        EXPORT  _Z24fake_assembler_function1v

;fake_assembler_function1
_Z24fake_assembler_function1v
        mov             r0,r0           ; nop
        mov             r0,r0           ; nop
        mov             r0,r0           ; nop
        mov             r0,r0           ; nop
        mov             r0,r0           ; nop
        mov             r0,r0           ; nop
        mov             r0,r0           ; nop
        mov             r0,r0           ; nop
        mov             r0,r0           ; nop
        mov             r0,r0           ; nop
        mov             r0,r0           ; nop
        mov             r0,r0           ; nop
        mov             r0,r0           ; nop
        mov             r0,r0           ; nop
        mov             r0,r0           ; nop
        mov             r0,r0           ; nop
        mov             r0,r0           ; nop
        mov             r0,r0           ; nop
        mov             r0,r0           ; nop
        bx lr

        END

; End of file - testasm.s

