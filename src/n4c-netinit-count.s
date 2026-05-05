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

    ; Read the actual file
    ld hl, file_buffer
    ld c, 60

.read_loop:
    ; Check counter
    ld a, c
    or a
    jr z, .eof

    ; Read one byte
    push bc
    call CAS_IN_CHAR
    pop bc
    jr nc, .eof

    ; Store it
    ld (hl), a
    inc hl
    dec c
    jr .read_loop

.eof:
    call CAS_IN_CLOSE

    ; DEBUG: Show first 16 bytes
    ld hl, msg_buffer
    call n4c_print
    ld hl, file_buffer
    ld b, 16
.show_loop:
    ld a, (hl)
    call print_hex8
    ld a, ' '
    call n4c_print_char
    inc hl
    djnz .show_loop
    call n4c_print_crlf

    ; File closed - now parse
    ld hl, file_buffer
    ld (parse_pos), hl

    ; Parse IP
    ld de, n4c_ip_addr
    call parse_ip_line

    ; Show IP
    ld hl, msg_ip
    call n4c_print
    ld hl, n4c_ip_addr
    call print_ip

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
; parse_ip_line - Parse one IP address line
; Entry: DE = output buffer (4 bytes)
; Uses: parse_pos (global)
;=======================================================
parse_ip_line:
    push bc
    push hl

    ld hl, (parse_pos)

    ; Parse 4 octets
    ld b, 4
.next_octet:
    push bc
    push de
    call parse_decimal      ; A = number, HL advanced
    pop de
    ld (de), a
    inc de
    pop bc
    dec b
    jr z, .done
    inc hl                  ; Skip '.'
    jr .next_octet

.done:
    pop hl
    pop bc
    ret

;=======================================================
; parse_decimal - Parse decimal number
; Entry: HL = buffer position
; Exit: A = number, HL = after number
;=======================================================
parse_decimal:
    push bc
    ld b, 0

.loop:
    ld a, (hl)
    cp '0'
    jr c, .done
    cp '9'+1
    jr nc, .done

    sub '0'
    ld c, a
    ld a, b
    add a, a
    add a, a
    add a, b
    add a, a
    add a, c
    ld b, a
    inc hl
    jr .loop

.done:
    ld a, b
    pop bc
    ret

;=======================================================
; print_ip - Print IP address
; Entry: HL = pointer to 4 bytes
;=======================================================
print_ip:
    push hl
    push bc
    push af

    ld b, 4
.loop:
    ld a, (hl)
    call print_decimal
    inc hl
    dec b
    jr z, .done
    ld a, '.'
    call n4c_print_char
    jr .loop

.done:
    call n4c_print_crlf
    pop af
    pop bc
    pop hl
    ret

;=======================================================
; print_decimal - Print 0-255
;=======================================================
print_decimal:
    push af
    push bc
    push de

    ld e, a
    ld d, 0

    ld bc, 100
    ld a, e
.div_100:
    cp c
    jr c, .done_100
    sub c
    inc d
    jr .div_100

.done_100:
    ld e, a
    ld a, d
    or a
    jr z, .skip_100
    add a, '0'
    call n4c_print_char

.skip_100:
    ld a, e
    ld d, 0
.div_10:
    cp 10
    jr c, .done_10
    sub 10
    inc d
    jr .div_10

.done_10:
    push af
    ld a, d
    add a, '0'
    call n4c_print_char
    pop af
    add a, '0'
    call n4c_print_char

    pop de
    pop bc
    pop af
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

print_hex8:
    push af
    rrca
    rrca
    rrca
    rrca
    call print_hex4
    pop af
    call print_hex4
    ret

print_hex4:
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
msg_init:           db "N4C.CFG READ TEST",13,10,0
msg_opened:         db "File opened OK",13,10,0
msg_buffer:         db "Buffer: ",0
msg_ip:             db "IP Address: ",0
msg_success:        db "Parse OK! Press key.",13,10,0
msg_err_no_file:    db "ERROR: N4C.CFG not found",13,10,0

; Data
bytes_read:         db 0
bytes_to_read:      db 0
buffer_ptr:         dw 0
parse_pos:          dw 0
n4c_ip_addr:        ds 4
dummy_buffer:       ds 1            ; Single byte right before file_buffer
file_buffer:        ds 128
