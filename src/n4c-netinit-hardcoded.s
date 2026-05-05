; N4C-NETINIT - TEMPORARY HARDCODED VERSION
; For testing when file I/O doesn't work
; Just hardcodes the network config instead of reading from file

;=======================================================
; Hardcoded Configuration - EDIT THESE VALUES
;=======================================================
HARDCODED_MAC:      db 0xDE,0xAD,0xBE,0xEF,0x00,0xFF
HARDCODED_IP:       db 192,168,68,254
HARDCODED_NETMASK:  db 255,255,255,0
HARDCODED_GATEWAY:  db 192,168,68,1
HARDCODED_DNS:      db 192,168,68,54

;=======================================================
; N4C_INIT - Initialize Net4CPC with hardcoded config
;=======================================================
N4C_INIT:
    push hl
    push de
    push bc

    ; Display initialization message
    ld hl, msg_init
    call n4c_print

    ld hl, msg_hardcoded
    call n4c_print

    ; Copy hardcoded values to buffers
    ld hl, HARDCODED_IP
    ld de, n4c_ip_addr
    ld bc, 4
    ldir

    ld hl, HARDCODED_NETMASK
    ld de, n4c_netmask
    ld bc, 4
    ldir

    ld hl, HARDCODED_GATEWAY
    ld de, n4c_gateway
    ld bc, 4
    ldir

    ld hl, HARDCODED_DNS
    ld de, n4c_dns
    ld bc, 4
    ldir

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
    jr c, .w5100_error

    ; Success!
    ld hl, msg_ready
    call n4c_print

    ; Wait for keypress so user can see the config
    ld hl, msg_press_key
    call n4c_print
    call 0xBB18             ; KM_WAIT_CHAR - wait for keypress

    pop bc
    pop de
    pop hl
    or a                        ; Clear carry
    ret

.w5100_error:
    ld hl, msg_err_w5100
    call n4c_print
    pop bc
    pop de
    pop hl
    scf
    ld a, 4                     ; N4C_ERR_W5100
    ret

;=======================================================
; n4c_init_w5100 - Initialize W5100S with configuration
;=======================================================
n4c_init_w5100:
    push hl
    push de
    push bc
    push af

    ; Check mode register (should already be 3 from NCFG.COM or previous init)
    ld bc, 0xFD20
    in a, (c)
    cp 3
    jr nz, .error

    ; Set MAC Address (SHAR at 0x0009)
    ld hl, 0x0009
    ld de, HARDCODED_MAC
    ld b, 6
    call n4c_write_w5100_bytes

    ; Set Gateway Address
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

    ; Set DNS (stored at 0x0032 - PPPoE dest hardware addr location)
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

n4c_write_w5100_bytes:
    ; Write B bytes from DE to W5100S register address in HL
    ; Uses 3-port access method like BASIC did (FD21/FD22/FD23)
.write_loop:
    push bc
    push hl

    ; Set W5100S address (FD21 = high, FD22 = low)
    ld bc, 0xFD21
    out (c), h          ; Address high byte
    ld bc, 0xFD22
    out (c), l          ; Address low byte

    ; Write data byte
    ld bc, 0xFD23
    ld a, (de)
    out (c), a

    ; Advance pointers
    pop hl
    inc hl              ; Next W5100S register
    inc de              ; Next source byte
    pop bc
    djnz .write_loop
    ret

;=======================================================
; Print routines
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

n4c_print_decimal:
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
msg_init:       db "N4C Network Initialization",13,10,0
msg_hardcoded:  db "Using HARDCODED configuration",13,10,0
msg_ip:         db "IP Address: ",0
msg_netmask:    db "Netmask:    ",0
msg_gateway:    db "Gateway:    ",0
msg_dns:        db "DNS Server: ",0
msg_ready:      db "Network Ready",13,10,0
msg_press_key:  db "Press any key to continue...",13,10,0
msg_err_w5100:  db "ERROR: W5100S not responding",13,10,0

; Configuration buffers
n4c_ip_addr:    ds 4
n4c_netmask:    ds 4
n4c_gateway:    ds 4
n4c_dns:        ds 4
