; N4C-NETINIT - DEBUG VERSION
; Adds extra diagnostic output to find the issue

;=======================================================
; Constants
;=======================================================
N4C_CONFIG_FILE:    db "N4C.CFG",0

; Error codes
N4C_ERR_NO_FILE     equ 1
N4C_ERR_READ        equ 2
N4C_ERR_PARSE       equ 3
N4C_ERR_W5100       equ 4

; Firmware routines
CAS_IN_OPEN         equ 0xBC77
CAS_IN_CLOSE        equ 0xBC7A
CAS_IN_CHAR         equ 0xBC80

;=======================================================
; N4C_INIT - Initialize Net4CPC with configuration file
;=======================================================
N4C_INIT:
    push hl
    push de
    push bc

    ; Display initialization message
    ld hl, msg_init
    call n4c_print

    ; DEBUG: Show filename address
    ld hl, msg_debug_fname
    call n4c_print
    ld hl, N4C_CONFIG_FILE
    call n4c_print_hex16
    call n4c_print_crlf

    ; DEBUG: Show filename contents
    ld hl, msg_debug_fname2
    call n4c_print
    ld hl, N4C_CONFIG_FILE
    call n4c_print
    call n4c_print_crlf

    ; DEBUG: Try opening file
    ld hl, msg_debug_opening
    call n4c_print

    ; Open configuration file
    ld hl, N4C_CONFIG_FILE
    call CAS_IN_OPEN

    ; DEBUG: Check result
    jr nc, .open_failed

    ; Success!
    ld hl, msg_debug_opened
    call n4c_print
    call CAS_IN_CLOSE

    pop bc
    pop de
    pop hl
    or a
    ret

.open_failed:
    ; DEBUG: Show error code
    ld hl, msg_debug_open_fail
    call n4c_print
    push af
    call n4c_print_hex8
    call n4c_print_crlf
    pop af

    pop bc
    pop de
    pop hl
    scf
    ld a, N4C_ERR_NO_FILE
    ret

;=======================================================
; Print routines
;=======================================================
n4c_print:
    push af
    push hl
.loop:
    ld a, (hl)
    or a
    jr z, .done
    call n4c_print_char
    inc hl
    jr .loop
.done:
    pop hl
    pop af
    ret

n4c_print_char:
    push hl
    push de
    push bc
    push af
    call 0xBB5A                 ; TXT_OUTPUT
    pop af
    pop bc
    pop de
    pop hl
    ret

n4c_print_crlf:
    push af
    ld a, 13
    call n4c_print_char
    ld a, 10
    call n4c_print_char
    pop af
    ret

n4c_print_hex16:
    push af
    ld a, h
    call n4c_print_hex8
    ld a, l
    call n4c_print_hex8
    pop af
    ret

n4c_print_hex8:
    push af
    rrca
    rrca
    rrca
    rrca
    call n4c_print_hex4
    pop af
    call n4c_print_hex4
    ret

n4c_print_hex4:
    and 0x0F
    cp 10
    jr c, .digit
    add a, 'A' - 10
    jr .print
.digit:
    add a, '0'
.print:
    call n4c_print_char
    ret

;=======================================================
; Messages
;=======================================================
msg_init:           db "N4C Network Initialization (DEBUG)",13,10,0
msg_debug_fname:    db "Filename addr: ",0
msg_debug_fname2:   db "Filename: ",0
msg_debug_opening:  db "Calling CAS_IN_OPEN...",13,10,0
msg_debug_opened:   db "SUCCESS! File opened.",13,10,0
msg_debug_open_fail: db "FAILED! Error code: ",0
