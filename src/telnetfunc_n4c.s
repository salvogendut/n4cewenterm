; Telnet functionality for Net4CPC
; Adapted from M4EWENTERM telnetfunc2.s
; Uses W5100S socket interface instead of M4 commands

start_telnet:
    ld hl, msgtest
    call disptextz
    call drawline
    call Check_n4c
    call loop_ip

telnet_session:
    ; Create TCP socket
    ld hl, msgdebug_socket
    call disptextz

    ld a, 0             ; Socket 0
    ld b, 1             ; TCP protocol
    call NET_SOCKET
    jp c, socket_error

    ld hl, msgdebug_socket_ok
    call disptextz

    ; Connect to server
    ld hl, msgdebug_connect
    call disptextz

    ld hl, ip_addr      ; Pointer to IP address
    ld bc, (port)       ; Port number
    call NET_CONNECT

    ; Debug: read back what W5100S has for destination
    push af
    ld hl, msgdebug_dest_ip
    call disptextz
    ld hl, S0_DIPR0
    call W5100_READ_REG
    call disp_dec
    ld a, '.'
    call printchar
    ld hl, S0_DIPR1
    call W5100_READ_REG
    call disp_dec
    ld a, '.'
    call printchar
    ld hl, S0_DIPR2
    call W5100_READ_REG
    call disp_dec
    ld a, '.'
    call printchar
    ld hl, S0_DIPR3
    call W5100_READ_REG
    call disp_dec
    call crlf

    ld hl, msgdebug_dest_port
    call disptextz
    ld hl, S0_DPORT0
    call W5100_READ_REG
    ld h, a             ; H = high byte
    ld hl, S0_DPORT1
    call W5100_READ_REG
    ld l, a             ; L = low byte
    ; Now HL has the port number (but HL register was used as temp)
    ; Need to rebuild HL properly
    push af
    ld hl, S0_DPORT0
    call W5100_READ_REG
    ld d, a             ; D = high byte
    ld hl, S0_DPORT1
    call W5100_READ_REG
    ld e, a             ; E = low byte
    ; DE now has port
    ex de, hl           ; Move to HL for display
    call disp_dec16
    pop af
    call crlf
    pop af

    jp c, connect_error

connect_ok:
    ld hl, msgconnect
    call disptextz

    ; Clear any debug messages
    ld hl, msgready
    call disptextz

mainloop:
    ; Check for received data
    ld bc, 1
    call recv_noblock2

    ; Check keyboard
    call km_read_char
    jr nc, mainloop

    cp 27               ; ESC? (now returns ASCII 27 after translation)
    jp z, exit_close
    cp 0x9              ; TAB?
    jr nz, no_pause

wait_no_tab:
    call km_read_char
    cp 0x9
    jr z, wait_no_tab

pause_loop:
    call km_read_char
    cp 27               ; ESC?
    jp z, exit_close
    cp 0x9              ; TAB again to leave
    jr nz, pause_loop
    jr mainloop

no_pause:
    ; Store the character
    ld hl, sendtext
    ld (hl), a

    ; Check if it's ENTER (CR)
    cp 0xD
    jr z, is_enter

    ; Regular character - echo it
    push af
    ld b, a
    call printchar
    pop af

    ; Send single character
    ld hl, sendtext
    ld bc, 1
    call NET_SEND
    jp mainloop

is_enter:
    ; Echo CR+LF locally
    ld a, 13
    ld b, a
    call printchar
    ld a, 10
    ld b, a
    call printchar

    ; Send CR+LF to server
    ld hl, sendtext
    ld (hl), 0xD
    inc hl
    ld (hl), 0xA
    ld hl, sendtext
    ld bc, 2
    call NET_SEND
    jp mainloop

recv_noblock2:
    push af
    push bc
    push de
    push hl

    ; Check if still connected
    call CHECK_CONNECTION
    jr nc, .still_ok

    ; Debug: show why we're disconnecting
    push af
    ld hl, msgdebug_disconn
    call disptextz
    ld hl, S0_SR
    call W5100_READ_REG
    call disp_hex_byte
    call crlf
    pop af
    jp exit_close

.still_ok:

    ; Try to receive data
    ld hl, recvbuf
    ld bc, 1            ; Read 1 byte at a time
    call NET_RECV

    ; Check if got data
    ld a, b
    or c
    jr z, recv_done     ; No data

    ; Got data - display it
    ld hl, recvbuf
    ld a, (hl)

    cp CMD              ; Telnet command?
    jr nz, not_tel_cmd
    call negotiate
    jr recv_done

not_tel_cmd:
    ; Display the character (printchar expects char in B)
    ld b, a
    call printchar

recv_done:
    pop hl
    pop de
    pop bc
    pop af
    ret

; Display text routines
disptext:
    xor a
    cp c
    jr nz, not_dispend
    cp b
    ret z
not_dispend:
    ld a, (hl)
    push bc
    call printchar
    pop bc
    inc hl
    dec bc
    jr disptext

disptextz:
    ld a, (hl)
    or a
    ret z
    call PRINTCHAR
    inc hl
    jr disptextz

drawline:
    push af
    push bc
    ld a, 196
    call PrintChar80Times
    pop bc
    pop af
    ret

PrintChar80Times:
    ld b, 80

PrintLoop:
    push bc
    call PrintChar
    pop bc
    djnz PrintLoop
    ret

socket_error:
    call crlf
    ld hl, msgsocket_error
    call disptextz
    jp loop_ip

connect_error:
    call crlf
    ld hl, msgconnect_error
    call disptextz

    ; Read socket status to see why it failed
    ld hl, msgdebug_socket_status
    call disptextz
    ld hl, S0_SR
    call W5100_READ_REG
    push af
    call disp_hex_byte
    call crlf
    pop af

    ; Read socket interrupt register
    ld hl, msgdebug_socket_ir
    call disptextz
    ld hl, S0_IR
    call W5100_READ_REG
    call disp_hex_byte
    call crlf

    ; Read and show gateway IP
    ld hl, msgdebug_gateway
    call disptextz
    ld hl, N_GAR0
    call W5100_READ_REG
    call disp_dec
    ld a, '.'
    call printchar
    ld hl, N_GAR1
    call W5100_READ_REG
    call disp_dec
    ld a, '.'
    call printchar
    ld hl, N_GAR2
    call W5100_READ_REG
    call disp_dec
    ld a, '.'
    call printchar
    ld hl, N_GAR3
    call W5100_READ_REG
    call disp_dec
    call crlf

    ; Read and show subnet mask
    ld hl, msgdebug_subnet
    call disptextz
    ld hl, N_SUBR0
    call W5100_READ_REG
    call disp_dec
    ld a, '.'
    call printchar
    ld hl, N_SUBR1
    call W5100_READ_REG
    call disp_dec
    ld a, '.'
    call printchar
    ld hl, N_SUBR2
    call W5100_READ_REG
    call disp_dec
    ld a, '.'
    call printchar
    ld hl, N_SUBR3
    call W5100_READ_REG
    call disp_dec
    call crlf

    ; Read and show our IP
    ld hl, msgdebug_ourip
    call disptextz
    ld hl, N_SIPR0
    call W5100_READ_REG
    call disp_dec
    ld a, '.'
    call printchar
    ld hl, N_SIPR1
    call W5100_READ_REG
    call disp_dec
    ld a, '.'
    call printchar
    ld hl, N_SIPR2
    call W5100_READ_REG
    call disp_dec
    ld a, '.'
    call printchar
    ld hl, N_SIPR3
    call W5100_READ_REG
    call disp_dec
    call crlf

    jp loop_ip

disp_error:
    ld hl, msgerror
    jp disptextz

exit_error:
    call crlf
    call disp_error
    jp loop_ip
    ret

exit_close:
    call crlf

    ld hl, msgclosing
    call disptextz

    call NET_CLOSE
    jp loop_ip
    ret

Check_n4c:
    ; Check if W5100S is present by reading mode register
    ld hl, N_MR         ; N_MR = 0x0000 (register address, not port!)
    call W5100_READ_REG
    cp 3                ; Should return 3 if initialized
    jr z, found_n4c

    ld hl, msgno_n4c
    call disptextz
    ret

found_n4c:
    ld hl, msgfound_n4c
    call disptextz
    ret

; Messages
msgconnect:     db 10,13,"Connected.",10,13,0
msgserverip:    db 10,13,"Input server name or IP (:PORT or default to 23):",10,13,0
msgno_n4c:      db "No Net4CPC found, check connection.",10,13,0
msgfound_n4c:   db "Net4CPC W5100S detected",10,13,0
msgtest:        db "EwenN4C 2026 v1.0 - Based on Ewenterm (1991) and M4EWENTERM (2023)",10,13,0
msgclosing:     db 10,13,"Connection closed.",10,13,0
msgerror:       db 10,13,"ERROR: Network error.",10,13,0
msgconnecting:  db 10,13, "Connecting to IP ",0
msgport:        db  " port ",0
msgdebug_socket: db 10,13,"[DEBUG] Creating TCP socket...",0
msgdebug_socket_ok: db " OK",10,13,0
msgdebug_connect: db "[DEBUG] Connecting...",10,13,0
msgsocket_error: db "ERROR: Failed to create socket",10,13,0
msgconnect_error: db "ERROR: Connection failed",10,13,0
msgdebug_socket_status: db "[DEBUG] Socket status register: 0x",0
msgdebug_socket_ir: db "[DEBUG] Socket interrupt register: 0x",0
msgdebug_gateway: db "[DEBUG] Gateway register: ",0
msgdebug_subnet: db "[DEBUG] Subnet mask: ",0
msgdebug_ourip: db "[DEBUG] Our IP: ",0
msgdebug_dest_ip: db "[DEBUG] W5100S Dest IP: ",0
msgdebug_dest_port: db "[DEBUG] W5100S Dest Port: ",0
msgready: db "Ready. ESC to disconnect, TAB to pause.",10,13,0
msgdebug_disconn: db "[DEBUG] Disconnect detected, socket status: 0x",0
msgdebug_keypress: db "[DEBUG] Key pressed: 0x",0
msgdebug_sent: db "[DEBUG] Send: ",0
msgdebug_rxsize: db "[DEBUG] RX buffer has ",0

; Data buffers
ip_addr:        db 127,0,0,1    ; Default localhost (for testing)
port:           dw 23           ; Port 23 (default telnet port)
sendtext:       ds 255
recvbuf:        ds 2048

; Compatibility stubs for negotiate.s (which expects M4 interface)
; recv - receive data (simplified stub)
recv:
    push hl
    push de

    ; BC has requested length
    ld hl, recvbuf
    call NET_RECV

    ; BC now has actual length received
    ; Copy to IY+6 for negotiate.s
    push iy
    pop hl
    ld de, 6
    add hl, de
    ld de, recvbuf
    ; Copy first 2 bytes for telnet negotiation
    ld a, (de)
    ld (hl), a
    inc de
    inc hl
    ld a, (de)
    ld (hl), a

    xor a           ; Return 0 (success)
    pop de
    pop hl
    ret

; sendcmd - send command (compatibility stub)
sendcmd:
    push hl
    push bc

    ; HL points to command buffer
    ; Get length from sendsize
    ld bc, (sendsize)
    call NET_SEND

    pop bc
    pop hl
    ret

; Data areas for negotiate.s compatibility
cmdsend:        ds 16
sendsize:       dw 0

; dispdec - display decimal (stub for negotiate.s)
dispdec:
    ; HL points to value
    ld a, (hl)
    ; Just print it as hex for now (simple stub)
    call printchar
    ret
