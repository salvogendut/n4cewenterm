; N4C-NETINIT - SIMPLE COUNT TEST
; Just count how many bytes we can read from N4C.CFG

;=======================================================
; Constants
;=======================================================
N4C_CONFIG_FILENAME: db "N4C.CFG",0

; Firmware routines
CAS_IN_OPEN         equ 0xBC77
CAS_IN_CLOSE        equ 0xBC7A
CAS_IN_CHAR         equ 0xBC80
CAS_IN_DIRECT       equ 0xBC83

;=======================================================
; N4C_INIT - Count bytes in N4C.CFG
;=======================================================
N4C_INIT:
    push hl
    push de
    push bc

    ; Open file - NO messages while file is open!
    ld hl, N4C_CONFIG_FILENAME
    call CAS_IN_OPEN
    jr nc, .file_not_found

    ; Read exactly 60 bytes (file size) - simple fixed loop
    ld hl, file_buffer
    ld (buffer_ptr), hl     ; Initialize pointer
    ld a, 60
    ld (bytes_to_read), a

.read_loop:
    ; Check counter
    ld a, (bytes_to_read)
    or a
    jr z, .eof              ; Done

    ; Read one byte
    call CAS_IN_DIRECT
    jr nc, .eof             ; EOF

    ; Store it
    ld hl, (buffer_ptr)
    ld (hl), a
    inc hl
    ld (buffer_ptr), hl

    ; Decrement counter
    ld a, (bytes_to_read)
    dec a
    ld (bytes_to_read), a
    jr .read_loop

.eof:
    call CAS_IN_CLOSE

    ; File closed, now safe to print
    ld hl, msg_success
    call n4c_print

    call 0xBB18             ; Wait for key

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

n4c_print_crlf:
    push af
    ld a, 13
    call n4c_print_char
    ld a, 10
    call n4c_print_char
    pop af
    ret

;=======================================================
; Messages
;=======================================================
msg_init:           db "N4C.CFG READ TEST",13,10,0
msg_opened:         db "File opened OK",13,10,0
msg_success:        db "File read OK! Press key.",13,10,0
msg_err_no_file:    db "ERROR: N4C.CFG not found",13,10,0

; Data
bytes_read:         db 0
bytes_to_read:      db 0
buffer_ptr:         dw 0
file_buffer:        ds 128
