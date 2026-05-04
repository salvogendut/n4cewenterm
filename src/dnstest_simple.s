; Minimal DNS test - just test error reporting
    org 0x7000

TXT_OUTPUT equ 0xBB5A

start:
    ld hl, msg_test
    call print_string

    ; Simulate error code 99 with carry set
    scf
    ld a, 99
    jr c, show_error

show_error:
    push af
    ld hl, msg_error
    call print_string
    pop af
    call print_decimal
    ret

print_string:
    ld a, (hl)
    or a
    ret z
    call print_char
    inc hl
    jr print_string

print_char:
    push hl
    push de
    push bc
    call TXT_OUTPUT
    pop bc
    pop de
    pop hl
    ret

print_decimal:
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
    call print_char

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
    ld e, a
    ld a, d
    or a
    jr z, .skip_10
    add a, '0'
    call print_char

.skip_10:
    ld a, e
    add a, '0'
    call print_char

    pop de
    pop bc
    ret

msg_test:   db "Testing error display",13,10,0
msg_error:  db "Error code: ",0

SAVE 'DNSTEST2.BIN',#7000,$-#7000,AMSDOS
