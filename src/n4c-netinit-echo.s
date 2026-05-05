; N4C-NETINIT - ECHO DEBUG VERSION
; Just echoes what it reads from N4C.CFG to debug file reading

;=======================================================
; Constants
;=======================================================
N4C_CONFIG_FILENAME: db "N4C.CFG",0

; Firmware routines
CAS_IN_OPEN         equ 0xBC77
CAS_IN_CLOSE        equ 0xBC7A
CAS_IN_CHAR         equ 0xBC80

;=======================================================
; N4C_INIT - Read and echo N4C.CFG
;=======================================================
N4C_INIT:
    push hl
    push de
    push bc

    ; Display message
    ld hl, msg_init
    call n4c_print

    ; Open file
    ld hl, N4C_CONFIG_FILENAME
    ld b, 7
    call CAS_IN_OPEN
    jr nc, .file_not_found

    ; File opened, echo everything
    ld hl, msg_echo_start
    call n4c_print

    xor a
    ld (char_count), a      ; Character counter

.echo_loop:
    ; Safety check - max 100 characters
    ld a, (char_count)
    cp 100
    jr z, .max_reached

    inc a
    ld (char_count), a      ; Increment counter

    ; Read character - CAS_IN_CHAR destroys ALL registers
    push hl
    push de
    push bc
    call CAS_IN_CHAR
    pop bc
    pop de
    pop hl
    jr nc, .eof             ; No more data

    ; Save the character in memory (C register is destroyed by print routines)
    ld (current_char), a

    ; Echo the hex value
    call n4c_print_hex8     ; Show hex value
    ld a, ' '
    call n4c_print_char

    ; Also show printable version
    ld a, (current_char)    ; Restore character
    cp 32
    jr c, .not_printable
    cp 127
    jr nc, .not_printable
    call n4c_print_char
    jr .next

.not_printable:
    ld a, '.'
    call n4c_print_char

.next:

    ; Add newline every 10 characters for readability
    ld a, (char_count)
    and 0x0F
    cp 10
    jr nz, .no_newline
    ld a, 13
    call n4c_print_char
    ld a, 10
    call n4c_print_char
.no_newline:

    ld a, ' '
    call n4c_print_char
    jr .echo_loop

.max_reached:
    ld hl, msg_max_reached
    call n4c_print

.eof:
    call CAS_IN_CLOSE

    ld hl, msg_echo_done
    call n4c_print

    ld hl, msg_press_key
    call n4c_print
    call 0xBB18             ; Wait for keypress

    pop bc
    pop de
    pop hl
    or a
    ret

.file_not_found:
    ld hl, msg_err_no_file
    call n4c_print
    pop bc
    pop de
    pop hl
    scf
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
    call 0xBB5A
    pop af
    pop bc
    pop de
    pop hl
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
msg_init:           db "N4C.CFG ECHO TEST",13,10,0
msg_echo_start:     db "File contents (HEX CHAR):",13,10,0
msg_echo_done:      db 13,10,"End of file.",13,10,0
msg_max_reached:    db 13,10,"Max 100 chars reached.",13,10,0
msg_press_key:      db "Press any key...",13,10,0
msg_err_no_file:    db "ERROR: N4C.CFG not found",13,10,0

; Variables
char_count:         db 0
current_char:       db 0
