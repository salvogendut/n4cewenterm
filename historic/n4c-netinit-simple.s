; N4C-NETINIT - SIMPLE VERSION
; Based on the example pattern provided

;=======================================================
; Constants
;=======================================================
N4C_CONFIG_FILENAME: db "N4C.CFG",0

; Firmware routines
CAS_IN_OPEN         equ 0xBC77
CAS_IN_CLOSE        equ 0xBC7A
CAS_IN_CHAR         equ 0xBC80

;=======================================================
; N4C_INIT - Read N4C.CFG using simple pattern
;=======================================================
N4C_INIT:
    push hl
    push de
    push bc

    ; Open file
    ld hl, N4C_CONFIG_FILENAME
    ld b, 7                 ; Filename length
    call CAS_IN_OPEN
    jp nc, .file_not_found

    ; Setup buffer
    ld de, file_buffer

.read_loop:
    call CAS_IN_CHAR        ; 0xBC80
    jr nc, .close_file      ; EOF

    ld (de), a              ; Store byte
    inc de
    jr .read_loop

.close_file:
    call CAS_IN_CLOSE

    ; Initialize parse position
    ld hl, file_buffer
    ld (current_parse_pos), hl

    ; Parse buffer into IP addresses
    ld de, n4c_ip_addr
    call parse_ip_from_buffer

    ld de, n4c_netmask
    call parse_ip_from_buffer

    ld de, n4c_gateway
    call parse_ip_from_buffer

    ld de, n4c_dns
    call parse_ip_from_buffer

    ; Display configuration
    ld hl, msg_ip
    call n4c_print
    ld hl, n4c_ip_addr
    call n4c_print_ip

    ld hl, msg_netmask
    call n4c_print
    ld hl, n4c_netmask
    call n4c_print_ip

    ld hl, msg_gateway
    call n4c_print
    ld hl, n4c_gateway
    call n4c_print_ip

    ld hl, msg_dns
    call n4c_print
    ld hl, n4c_dns
    call n4c_print_ip

    ; Initialize W5100S
    call n4c_init_w5100
    jp c, .w5100_error

    ld hl, msg_ready
    call n4c_print

    ld hl, msg_press_key
    call n4c_print
    call 0xBB18             ; Wait

    pop bc
    pop de
    pop hl
    or a
    ret

.w5100_error:
    ld hl, msg_err_w5100
    call n4c_print
    pop bc
    pop de
    pop hl
    scf
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
; parse_ip_from_buffer - Parse one IP line from buffer
; Entry: DE = output (4 bytes)
; Uses global: current_parse_pos
;=======================================================
parse_ip_from_buffer:
    push bc
    push hl

    ; Get current position in buffer
    ld hl, (current_parse_pos)

    ; Parse 4 octets
    ld b, 4
.parse_octet:
    push bc
    push de
    call parse_decimal_from_buffer  ; Returns value in A, HL advanced
    pop de
    ld (de), a
    inc de
    pop bc

    ; Skip dot (if not last octet)
    dec b
    jr z, .done_octets
    inc hl              ; Skip '.'
    jr .parse_octet

.done_octets:
    ; Skip to next line (skip CR, LF)
.skip_eol:
    ld a, (hl)
    cp 13
    jr z, .skip_this
    cp 10
    jr z, .skip_this
    jr .eol_done
.skip_this:
    inc hl
    jr .skip_eol

.eol_done:
    ; Save new position
    ld (current_parse_pos), hl

    pop hl
    pop bc
    ret

;=======================================================
; parse_decimal_from_buffer - Parse decimal number
; Entry: HL = buffer position
; Exit:  A = number, HL = position after number
;=======================================================
parse_decimal_from_buffer:
    push bc
    ld b, 0             ; Accumulator

.loop:
    ld a, (hl)
    cp '0'
    jr c, .done
    cp '9'+1
    jr nc, .done

    ; Valid digit
    sub '0'
    ld c, a

    ; B = B * 10 + C
    ld a, b
    add a, a            ; *2
    add a, a            ; *4
    add a, b            ; *5
    add a, a            ; *10
    add a, c
    ld b, a

    inc hl
    jr .loop

.done:
    ld a, b
    pop bc
    ret

;=======================================================
; n4c_init_w5100 - Initialize W5100S
;=======================================================
n4c_init_w5100:
    push hl
    push de
    push bc
    push af

    ; Check mode register
    ld bc, 0xFD20
    in a, (c)
    cp 3
    jr nz, .error

    ; Set MAC Address
    ld hl, 0x0009
    ld de, n4c_mac_addr
    ld b, 6
    call n4c_write_w5100_bytes

    ; Set Gateway
    ld hl, 0x0001
    ld de, n4c_gateway
    ld b, 4
    call n4c_write_w5100_bytes

    ; Set Subnet Mask
    ld hl, 0x0005
    ld de, n4c_netmask
    ld b, 4
    call n4c_write_w5100_bytes

    ; Set Source IP
    ld hl, 0x000F
    ld de, n4c_ip_addr
    ld b, 4
    call n4c_write_w5100_bytes

    ; Set DNS
    ld hl, 0x0032
    ld de, n4c_dns
    ld b, 4
    call n4c_write_w5100_bytes

    pop af
    pop bc
    pop de
    pop hl
    or a
    ret

.error:
    pop af
    pop bc
    pop de
    pop hl
    scf
    ret

;=======================================================
; n4c_write_w5100_bytes - Write bytes to W5100S
; Entry: HL = register address, DE = source, B = count
;=======================================================
n4c_write_w5100_bytes:
.write_loop:
    push bc
    push hl

    ; Set address
    ld bc, 0xFD21
    out (c), h
    ld bc, 0xFD22
    out (c), l

    ; Write data
    ld bc, 0xFD23
    ld a, (de)
    out (c), a

    pop hl
    inc hl
    inc de
    pop bc
    djnz .write_loop
    ret

;=======================================================
; n4c_print_ip - Print IP address
;=======================================================
n4c_print_ip:
    push hl
    push bc
    push af

    ld b, 4
.loop:
    ld a, (hl)
    call n4c_print_decimal
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
; n4c_print_decimal - Print 0-255 decimal
;=======================================================
n4c_print_decimal:
    push af
    push bc
    push de

    ld e, a
    ld d, 0

    ; Hundreds
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
    ; Tens
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

    ; Ones
    add a, '0'
    call n4c_print_char

    pop de
    pop bc
    pop af
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

;=======================================================
; Messages
;=======================================================
msg_ip:             db "IP Address: ",0
msg_netmask:        db "Netmask:    ",0
msg_gateway:        db "Gateway:    ",0
msg_dns:            db "DNS Server: ",0
msg_ready:          db "Network Ready",13,10,0
msg_press_key:      db "Press any key to continue...",13,10,0
msg_err_no_file:    db "ERROR: N4C.CFG not found",13,10,0
msg_err_w5100:      db "ERROR: W5100S not responding",13,10,0

; Data buffers
current_parse_pos:  dw file_buffer
n4c_mac_addr:       db 0xDE,0xAD,0xBE,0xEF,0x00,0xFF
n4c_ip_addr:        ds 4
n4c_netmask:        ds 4
n4c_gateway:        ds 4
n4c_dns:            ds 4
file_buffer:        ds 256
