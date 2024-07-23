.global _start  

///////////////////////////////////
up_line: .ascii "\x1b[1A"
.equ len_ul, . - up_line

del_line: .ascii "\x1b[2K"
.equ len_dl, . - del_line

end_ln: .ascii "\n"
.equ len_endln, . - end_ln

backspace: .ascii "\b"
.equ len_bs, . - backspace

clear: .ascii "\x1b[2J"
.equ len_clear, . - clear

helloworld: .ascii "hello world"
.equ len_hw, . - helloworld

num: .word 0x05
.equ len_num, 1

///////////////////////////////////

.align 2

_start: 
    mov x19, #4         ; number of frames

_loop: 
    cbz x19, _terminate

    ; mov x0, len_num
    ; adr x1, backspace
    ; mov x2, len_bs
    ; bl _loop_print

    ; mov x0, #0x10
    ; adr x1, end_ln
    ; mov x2, len_endln
    ; bl _loop_print

    ; mov x0, #0x10
    ; adr x1, up_line
    ; mov x2, len_ul
    ; bl _loop_print

    adr x0, end_ln
    mov x1, len_endln
    bl _print

    adr x0, up_line
    mov x1, len_ul
    bl _print

    ; adr x0, num 
    ; ldr x0, [x0]
    ; add x0, x0, #48
    ; str x0, [sp, #-16]!
    ; mov x0, sp
    ; mov x1, len_num
    ; bl _print
    ; add sp, sp, #16

    mov x0, #1002
    mov x1, #3
    bl _print_nary

    movz x0, #0xA120
    movk x0, #0x7, lsl #16          ; wait 0.5 seconds (0x7A120 uS)
    bl _wait

    ; adr x0, end_ln
    ; mov x1, len_endln
    ; bl _print

    sub x19, x19, 1
    b _loop
; end loop

_terminate: 
    mov x0, #0		; return 0
    mov x16, #1		; terminate
	svc #0x80       ; syscall

///////////////////////////////////

_loop_print: 
    ; Function epilogue
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    stp x1, x2, [sp, #-16]!
    sub sp, sp, 16      ; alloc for counter

_delete_loop: 
    cbz x0, _end_delete_loop     ; save counter
    str x0, [sp]

    ; print backspace
	mov x0, #1			; stdout
    ldp x1, x2, [sp, #16] 
	; adr x1,	del_line	; address of hello world string		 
	; mov x2, len_bs 		; length of hello world string
	mov x16, #4 		; write
	svc #0x80           ; syscall
    
    ; decrease counter
    ldr x0, [sp]
    sub x0, x0, 1
    b _delete_loop

_end_delete_loop: 
    add sp, sp, 16      ; dealloc counter
    ldp x1, x2, [sp], 16

    ; Function prologue
    ldp x29, x30, [sp], 16
    ret

///////////////////////////////////

_print:  
    ; Function epilogue
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    stp x0, x1, [sp, #-16]!

	mov x0, #1			; stdout
	ldp x1, x2,	[sp]	; address of hello world string		 
	; ldr x2, [sp, #8] 	; length of hello world string
	mov x16, #4 		; write
	svc #0x80           ; syscall

    ; Function prologue
    ldp x0, x1, [sp], #16
    ldp x29, x30, [sp], #16
    ret

///////////////////////////////////
    
_wait:                      ; x0 = time_to_wait
    ; Function epilogue
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    
    stp x0, x1, [sp, #-16]!
    stp x2, x3, [sp, #-16]!

    mov x1, x0              ; x1 = time_to_wait
    bl _get_time            ; x2 = start_time
    mov x2, x0

_loop_wait:
    bl _get_time 

    sub x0, x0, x2          ; x0 = delta time
    cmp x0, x1
    ; b.ge _stop_wait
    b.hs _stop_wait
    mov x0, x0              ; do nothing for one cycle
    b _loop_wait

_stop_wait:
    ; Function prologue
    ldp x2, x3, [sp], 16
    ldp x0, x1, [sp], 16
    ldp x29, x30, [sp], #16
    ret
    
///////////////////////////////////

_get_time:  ; time of day in x0 
    ; Function epilogue
    stp x29, x30, [sp, #-16]!
    mov x29, sp

    str x1, [sp, #-16]!
    sub sp, sp, #16

    ; 116	AUE_GETTIMEOFDAY	ALL	{ int gettimeofday(struct timeval *tp, struct timezone *tzp); }
    mov x0, sp
    mov x1, #0
    mov x16, #116
    svc #0x80

    ; place time in ret reg
    ldr x0, [sp, #8]
    add sp, sp, #16

    ; Function prologue
    ldr x1, [sp], 16
    ldp x29, x30, [sp], #16
    ret

///////////////////////////////////

; x0: "q" number to print
; x1; "n" base, when decimal n=10, when binary n=2, etc.
_print_nary: 
    ; Function epilogue
    stp x29, x30, [sp, #-16]!
    mov x29, sp
    stp x0, x1, [sp, #-16]!
    stp x3, x5, [sp, #-16]!
    stp x6, x7, [sp, #-16]!
    stp x8, x9, [sp, #-16]!

; -------------------- 
    sub sp, sp, #64 

    mov x5, sp

_store_remainder: 
    udiv x2, x0, x1     ; unsigned div: q/n 
    msub x3, x2, x1, x0 ; x3 = q - (q/n * n)
    cmp x3, #10
    b.ge _big
    add x3, x3, #48
    b _after_big
_big: 
    add x3, x3, #55
_after_big:
    str x3, [x5]
    add x5, x5, #2

    mov x0, x2 
    cmp x0, #0
    b.ne _store_remainder

_print_stored_digits: 
    sub x5, x5, #2
    mov x0, x5
    mov x1, #1
    bl _print

    mov x0, sp
    cmp x5, x0
    b.le _finish_nary_print 
    b _print_stored_digits

_finish_nary_print:

    add sp, sp, #64 
; -------------------- 

    ; Function prologue
    stp x8, x9, [sp], #16
    stp x6, x7, [sp], #16
    ldp x3, x5, [sp], #16
    ldp x0, x1, [sp], #16
    ldp x29, x30, [sp], #16
    ret
