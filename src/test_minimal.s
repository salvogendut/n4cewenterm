; Absolute minimal test
    org 0x7000

TXT_OUTPUT equ 0xBB5A

start:
    ; Print "Error: "
    ld a, 'E'
    call 0xBB5A
    ld a, 'r'
    call 0xBB5A
    ld a, 'r'
    call 0xBB5A
    ld a, 'o'
    call 0xBB5A
    ld a, 'r'
    call 0xBB5A
    ld a, ':'
    call 0xBB5A
    ld a, ' '
    call 0xBB5A

    ; Print "99"
    ld a, '9'
    call 0xBB5A
    ld a, '9'
    call 0xBB5A

    ret

SAVE 'TEST.BIN',#7000,$-#7000,AMSDOS
