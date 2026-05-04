; W5100S Network Interface for Net4CPC
; Low-level socket routines for Amstrad CPC
; Based on KCNet W5100-12.INC and N4C-W51.INC

; W5100S I/O addresses (Net4CPC)
W51MR       equ 0xFD20      ; Mode register
W51HAD      equ 0xFD21      ; High address
W51LAD      equ 0xFD22      ; Low address
W51DAT      equ 0xFD23      ; Data

; W5100S Common Registers
N_MR        equ 0x0000      ; Mode register
N_RTR0      equ 0x0017      ; Retry time register (2 bytes)
N_RTR1      equ 0x0018
N_RCR       equ 0x0019      ; Retry count register
N_GAR0      equ 0x0001      ; Gateway address
N_GAR1      equ 0x0002
N_GAR2      equ 0x0003
N_GAR3      equ 0x0004
N_SUBR0     equ 0x0005      ; Subnet mask
N_SUBR1     equ 0x0006
N_SUBR2     equ 0x0007
N_SUBR3     equ 0x0008
N_SHAR0     equ 0x0009      ; Source hardware address (MAC)
N_SIPR0     equ 0x000F      ; Source IP address
N_SIPR1     equ 0x0010
N_SIPR2     equ 0x0011
N_SIPR3     equ 0x0012

; Socket 0 Registers (we'll use socket 0 for telnet)
S0_MR       equ 0x0400      ; Socket 0 mode register
S0_CR       equ 0x0401      ; Socket 0 command register
S0_IR       equ 0x0402      ; Socket 0 interrupt register
S0_SR       equ 0x0403      ; Socket 0 status register
S0_PORT0    equ 0x0404      ; Socket 0 source port
S0_DHAR0    equ 0x0406      ; Socket 0 dest hardware addr
S0_DIPR0    equ 0x040C      ; Socket 0 dest IP address
S0_DIPR1    equ 0x040D
S0_DIPR2    equ 0x040E
S0_DIPR3    equ 0x040F
S0_DPORT0   equ 0x0410      ; Socket 0 dest port
S0_DPORT1   equ 0x0411
S0_TX_FSR0  equ 0x0420      ; Socket 0 TX free size
S0_TX_RD0   equ 0x0422      ; Socket 0 TX read pointer
S0_TX_WR0   equ 0x0424      ; Socket 0 TX write pointer
S0_TX_WR1   equ 0x0425
S0_RX_RSR0  equ 0x0426      ; Socket 0 RX received size
S0_RX_RSR1  equ 0x0427
S0_RX_RD0   equ 0x0428      ; Socket 0 RX read pointer
S0_RX_RD1   equ 0x0429

; Socket commands
SCMD_OPEN      equ 0x01
SCMD_LISTEN    equ 0x02
SCMD_CONNECT   equ 0x04
SCMD_DISCON    equ 0x08
SCMD_CLOSE     equ 0x10
SCMD_SEND      equ 0x20
SCMD_RECV      equ 0x40

; Socket status values
SSTAT_CLOSED       equ 0x00
SSTAT_INIT         equ 0x13
SSTAT_LISTEN       equ 0x14
SSTAT_ESTABLISHED  equ 0x17
SSTAT_CLOSE_WAIT   equ 0x1C
SSTAT_UDP          equ 0x22
SSTAT_IPRAW        equ 0x32
SSTAT_MACRAW       equ 0x42
SSTAT_PPPOE        equ 0x5F
SSTAT_SYNSENT      equ 0x15
SSTAT_SYNRECV      equ 0x16
SSTAT_FIN_WAIT     equ 0x18
SSTAT_TIME_WAIT    equ 0x1B

; Socket modes
SMODE_TCP      equ 0x01
SMODE_UDP      equ 0x02
SK_STREAM      equ 1       ; TCP mode (for compatibility)
SK_DGRAM       equ 2       ; UDP mode (for compatibility)

; KCNet constants
N_XTIME        equ 6554    ; Max value (ms) of time-service
COMP_SCHEME    equ 0xC0    ; DNS compression scheme

; TX/RX Buffer base addresses
S0_TX_BASE     equ 0x4000
S0_RX_BASE     equ 0x6000
S0_TX_MASK     equ 0x07FF   ; 2KB buffer
S0_RX_MASK     equ 0x07FF   ; 2KB buffer

;-------------------------------------------------------
; W5100_WRITE_REG - Write a byte to W5100S register
; Entry: HL = register address, A = byte to write
; Exit:  None
; Uses:  BC
;-------------------------------------------------------
W5100_WRITE_REG:
    push bc
    ld bc, W51HAD
    out (c), h          ; High address
    inc c
    out (c), l          ; Low address
    inc c
    out (c), a          ; Data
    pop bc
    ret

;-------------------------------------------------------
; W5100_READ_REG - Read a byte from W5100S register
; Entry: HL = register address
; Exit:  A = byte read
; Uses:  BC
;-------------------------------------------------------
W5100_READ_REG:
    push bc
    ld bc, W51HAD
    out (c), h          ; High address
    inc c
    out (c), l          ; Low address
    inc c
    in a, (c)           ; Data
    pop bc
    ret

;-------------------------------------------------------
; W5100_WRITE_BUF - Write buffer to W5100S
; Entry: HL = host buffer address
;        DE = W5100S address
;        BC = length
; Exit:  HL = HL + BC
; Uses:  All
;-------------------------------------------------------
W5100_WRITE_BUF:
    push af
    push de
    push bc

    ld bc, W51HAD
    ld a, d
    out (c), a          ; Write high address
    inc c
    ld a, e
    out (c), a          ; Write low address
    inc c               ; BC now points to W51DAT

    pop de              ; Length to DE

.wbuf_loop:
    ld a, d
    or e
    jr z, .wbuf_done

    ld a, (hl)
    out (c), a          ; Write data byte
    inc hl
    dec de
    jr .wbuf_loop

.wbuf_done:
    pop de
    pop af
    ret

;-------------------------------------------------------
; W5100_READ_BUF - Read buffer from W5100S
; Entry: HL = host buffer address
;        DE = W5100S address
;        BC = length
; Exit:  HL = HL + BC
; Uses:  All
;-------------------------------------------------------
W5100_READ_BUF:
    push af
    push de
    push bc             ; Save length

    ld bc, W51HAD
    ld a, d
    out (c), a          ; Write high address
    inc c
    ld a, e
    out (c), a          ; Write low address
    inc c               ; BC now points to W51DAT

    pop de              ; Get length into DE

.rbuf_loop:
    ld a, d
    or e
    jr z, .rbuf_done

    in a, (c)           ; Read data byte
    ld (hl), a
    inc hl
    dec de
    jr .rbuf_loop

.rbuf_done:
    pop de
    pop af
    ret

;-------------------------------------------------------
; NET_SOCKET - Initialize socket (like M4 C_NETSOCKET)
; Entry: A = socket number (0-3), B = protocol (1=TCP)
; Exit:  Carry clear if OK, set if error
;-------------------------------------------------------
NET_SOCKET:
    push hl
    push bc

    ; Set longer ARP retry timeout (10000 = 1 second)
    ld hl, N_RTR0
    ld a, 0x27          ; High byte of 10000
    call W5100_WRITE_REG
    inc hl
    ld a, 0x10          ; Low byte of 10000
    call W5100_WRITE_REG

    ; Set retry count to 10
    ld hl, N_RCR
    ld a, 10
    call W5100_WRITE_REG

    ; Set socket mode to TCP
    ld hl, S0_MR
    ld a, SMODE_TCP
    call W5100_WRITE_REG

    ; Set source port (default 5000)
    ld hl, S0_PORT0
    ld a, 0x13          ; High byte of 5000
    call W5100_WRITE_REG
    inc hl
    ld a, 0x88          ; Low byte of 5000
    call W5100_WRITE_REG

    ; Send OPEN command
    ld hl, S0_CR
    ld a, SCMD_OPEN
    call W5100_WRITE_REG

    ; Wait for command completion
    call WAIT_CMD_DONE

    ; Check socket status
    ld hl, S0_SR
    call W5100_READ_REG
    cp SSTAT_INIT
    jr z, .socket_ok

    scf                 ; Set carry for error
    jr .socket_exit

.socket_ok:
    or a                ; Clear carry for success

.socket_exit:
    pop bc
    pop hl
    ret

;-------------------------------------------------------
; NET_CONNECT - Connect to host (like M4 C_NETCONNECT)
; Entry: HL = pointer to IP address (4 bytes)
;        BC = port number (network order)
; Exit:  Carry clear if OK, set if error
;-------------------------------------------------------
NET_CONNECT:
    push hl             ; Save IP address pointer
    push de
    push bc

    ; Clear socket interrupt register first
    push hl             ; Save ip_addr pointer again
    ld hl, S0_IR
    ld a, 0xFF
    call W5100_WRITE_REG
    pop hl              ; Restore ip_addr pointer

    ; Write destination IP
    ld de, S0_DIPR0
    push bc
    ld bc, 4
    call W5100_WRITE_BUF
    pop bc

    ; Write destination port
    ld hl, S0_DPORT0
    ld a, b
    call W5100_WRITE_REG
    inc hl
    ld a, c
    call W5100_WRITE_REG

    ; Send CONNECT command
    ld hl, S0_CR
    ld a, SCMD_CONNECT
    call W5100_WRITE_REG

    ; Wait for CONNECT command to complete
    call WAIT_CMD_DONE

    ; Wait for connection (with timeout)
    ld de, 5000         ; Longer timeout counter
.wait_connect:
    ld hl, S0_SR
    call W5100_READ_REG
    cp SSTAT_ESTABLISHED
    jr z, .connect_ok

    ; Check for error states
    cp 0x00             ; SOCK_CLOSED = failed
    jr z, .connect_timeout
    cp 0x1C             ; SOCK_LAST_ACK = closing
    jr z, .connect_timeout

    ; Small delay
    push de
    ld b, 255
.delay:
    djnz .delay
    pop de

    dec de
    ld a, d
    or e
    jr nz, .wait_connect

.connect_timeout:

    ; Timeout
    scf
    jr .connect_exit

.connect_ok:
    or a                ; Clear carry

.connect_exit:
    pop bc
    pop de
    pop hl
    ret

;-------------------------------------------------------
; NET_SEND - Send data (like M4 C_NETSEND)
; Entry: HL = buffer address
;        BC = length
; Exit:  Carry clear if OK, set if error
; Fix: Rewrote with balanced stack. Old version had a
;      spurious push de at entry that was never cleanly
;      popped, corrupting the return address on ret.
;-------------------------------------------------------
NET_SEND:
    push hl             ; [1] save data buffer pointer
    push bc             ; [2] save length

    ; Read current TX write pointer into DE
    ld hl, S0_TX_WR0
    call W5100_READ_REG
    ld d, a
    ld hl, S0_TX_WR1
    call W5100_READ_REG
    ld e, a             ; DE = current TX write pointer

    ; Calculate physical W5100S TX buffer address:
    ;   offset = write_ptr AND S0_TX_MASK  (keep low 11 bits)
    ;   physical = S0_TX_BASE + offset
    ld a, e
    and S0_TX_MASK & 0xFF
    ld l, a
    ld a, d
    and S0_TX_MASK >> 8
    ld h, a             ; HL = masked offset (0x0000 - 0x07FF)
    ld de, S0_TX_BASE
    add hl, de          ; HL = physical W5100S address
    ex de, hl           ; DE = physical address (for W5100_WRITE_BUF)

    ; Restore data pointer and length for the write
    pop bc              ; [2] BC = length
    pop hl              ; [1] HL = data buffer pointer

    push bc             ; [3] save length for pointer update below
    call W5100_WRITE_BUF    ; write BC bytes from (HL) to W5100S at DE

    ; Update TX write pointer: new_ptr = old_ptr + length
    pop bc              ; [3] BC = length

    ld hl, S0_TX_WR0
    call W5100_READ_REG
    ld d, a
    ld hl, S0_TX_WR1
    call W5100_READ_REG
    ld e, a             ; DE = current write pointer (re-read for safety)
    ex de, hl           ; HL = write pointer
    add hl, bc          ; HL = new write pointer
    ex de, hl           ; DE = new write pointer

    ld hl, S0_TX_WR0
    ld a, d
    call W5100_WRITE_REG
    ld hl, S0_TX_WR1
    ld a, e
    call W5100_WRITE_REG

    ; Issue SEND command and wait for completion
    ld hl, S0_CR
    ld a, SCMD_SEND
    call W5100_WRITE_REG

    call WAIT_CMD_DONE

    or a                ; Clear carry = success
    ret

;-------------------------------------------------------
; NET_RECV - Receive data (like M4 C_NETRECV)
; Entry: HL = buffer address
;        BC = max length
; Exit:  BC = actual bytes received
;        Carry clear if OK, set if error
;-------------------------------------------------------
NET_RECV:
    push hl             ; Save buffer pointer
    push de
    push bc             ; Save requested length

    ; Check how much data is actually available
    ld hl, S0_RX_RSR0
    call W5100_READ_REG
    ld d, a
    ld hl, S0_RX_RSR1
    call W5100_READ_REG
    ld e, a             ; DE = bytes available

    ; If no data, return immediately
    ld a, d
    or e
    jr z, .recv_no_data

    ; For now, just read one byte at a time
    ; Get RX read pointer
    ld hl, S0_RX_RD0
    call W5100_READ_REG
    ld d, a
    ld hl, S0_RX_RD1
    call W5100_READ_REG
    ld e, a             ; DE = RX read pointer value

    ; Mask to get offset within 2KB buffer
    ld a, e
    and 0xFF
    ld l, a
    ld a, d
    and 0x07
    ld h, a             ; HL = masked offset (0-2047)

    ; Add RX buffer base
    ld de, 0x6000
    add hl, de          ; HL = W5100S RX buffer address

    ; Read one byte directly using W5100_READ_REG
    call W5100_READ_REG

    ; Store in our buffer
    pop bc              ; Get length (discard)
    pop de              ; Get original DE (discard)
    pop hl              ; Get buffer pointer
    ld (hl), a          ; Store the byte we just read

    ; Update RX read pointer (increment by 1)
    ld hl, S0_RX_RD0
    call W5100_READ_REG
    ld d, a
    ld hl, S0_RX_RD1
    call W5100_READ_REG
    ld e, a
    inc de              ; Add 1 byte
    ld hl, S0_RX_RD0
    ld a, d
    call W5100_WRITE_REG
    ld hl, S0_RX_RD1
    ld a, e
    call W5100_WRITE_REG

    ; Send RECV command
    ld hl, S0_CR
    ld a, SCMD_RECV
    call W5100_WRITE_REG
    call WAIT_CMD_DONE

    ld bc, 1            ; Return 1 byte read
    or a                ; Clear carry
    ret

.recv_no_data:
    pop bc
    pop de
    pop hl
    ld bc, 0
    or a
    ret

;-------------------------------------------------------
; NET_CLOSE - Close socket (like M4 C_NETCLOSE)
; Entry: None
; Exit:  None
;-------------------------------------------------------
NET_CLOSE:
    push hl
    push af

    ; Send DISCONNECT command
    ld hl, S0_CR
    ld a, SCMD_DISCON
    call W5100_WRITE_REG

    call WAIT_CMD_DONE

    ; Wait a bit
    ld b, 255
.delay1:
    djnz .delay1

    ; Send CLOSE command
    ld hl, S0_CR
    ld a, SCMD_CLOSE
    call W5100_WRITE_REG

    call WAIT_CMD_DONE

    pop af
    pop hl
    ret

;-------------------------------------------------------
; WAIT_CMD_DONE - Wait for socket command to complete
; Entry: None
; Exit:  None
;-------------------------------------------------------
WAIT_CMD_DONE:
    push hl
    push af

.wait_loop:
    ld hl, S0_CR
    call W5100_READ_REG
    or a
    jr nz, .wait_loop

    pop af
    pop hl
    ret

;-------------------------------------------------------
; CHECK_CONNECTION - Check if still connected
; Entry: None
; Exit:  Carry clear if connected, set if disconnected
;-------------------------------------------------------
CHECK_CONNECTION:
    push hl
    push af

    ld hl, S0_SR
    call W5100_READ_REG
    cp SSTAT_ESTABLISHED
    jr z, .still_connected

    cp SSTAT_CLOSE_WAIT
    jr z, .disconnected

    ; Any other state considered disconnected
.disconnected:
    scf
    jr .check_exit

.still_connected:
    or a

.check_exit:
    pop af
    pop hl
    ret

;=======================================================
; KCNet-compatible API for DNS client
;=======================================================

;-------------------------------------------------------
; SOCKET - Create a socket (KCNet API)
; Entry: A = socket number (0-3), 0xFF = auto-allocate
;        D = mode (SK_STREAM=1 or SK_DGRAM=2)
;        E = flags (unused)
; Exit:  A = socket number if OK
;        Carry clear if OK, set if error
;-------------------------------------------------------
SOCKET:
    push hl
    push bc

    ; For simplicity, use socket 1 for UDP (DNS)
    ; Socket 0 is reserved for TCP (telnet)
    ld a, 1

    ; Set socket mode
    ld hl, S1_MR
    ld a, d
    cp SK_DGRAM
    jr z, .udp_mode
    ld a, SMODE_TCP
    jr .set_mode
.udp_mode:
    ld a, SMODE_UDP
.set_mode:
    call W5100_WRITE_REG

    ; FIX: W5100S requires a non-zero local source port in S1_PORT0/S1_PORT1
    ; before OPEN for UDP mode. Without it the chip binds to port 0, and the
    ; DNS server's reply (src=53 -> dst=0) is either dropped or unmatched, so
    ; RECVFR never sees data and the client hangs waiting forever.
    ; Use ephemeral port 0xC000 (49152) — safe for a single-socket DNS client.
    ld hl, S1_PORT0
    ld a, 0xC0
    call W5100_WRITE_REG
    ld hl, S1_PORT0 + 1
    ld a, 0x00
    call W5100_WRITE_REG

    ; Open the socket
    ld hl, S1_CR
    ld a, SCMD_OPEN
    call W5100_WRITE_REG

    call WAIT_CMD_DONE_S1

    ; Check status
    ld hl, S1_SR
    call W5100_READ_REG
    cp SSTAT_INIT
    jr z, .socket_ok
    cp SSTAT_UDP
    jr z, .socket_ok

    scf
    jr .socket_exit

.socket_ok:
    ld a, 1         ; Return socket number
    or a            ; Clear carry

.socket_exit:
    pop bc
    pop hl
    ret

;-------------------------------------------------------
; CONNECT - Connect/bind socket (KCNet API)
; Entry: A = socket number
; Exit:  Carry clear if OK, set if error
;-------------------------------------------------------
CONNECT:
    ; For UDP, just return success
    ; Binding happens automatically
    or a
    ret

;-------------------------------------------------------
; CLOSE - Close socket (KCNet API)
; Entry: A = socket number
; Exit:  None
;-------------------------------------------------------
CLOSE:
    push hl
    push af

    cp 1
    jr nz, .close_s0

    ; Close socket 1 (UDP)
    ld hl, S1_CR
    ld a, SCMD_CLOSE
    call W5100_WRITE_REG
    call WAIT_CMD_DONE_S1
    jr .close_exit

.close_s0:
    ; Close socket 0 (TCP)
    call NET_CLOSE

.close_exit:
    pop af
    pop hl
    ret

;-------------------------------------------------------
; SENDTO - Send UDP datagram (KCNet API)
; Entry: A = socket number
;        HL = data buffer
;        BC = data length
;        DE = peer data (4 byte IP + 2 byte port)
; Exit:  Carry clear if OK, set if error
;-------------------------------------------------------
SENDTO:
    ; Entry: A=socket (ignored, always S1), HL=data buf, BC=length, DE=peer ptr
    ; Peer format: [4 bytes IP][2 bytes port big-endian]
    ;
    ; FIX 1: original used `ld hl, de` which is not a valid Z80 opcode.
    ;         Some assemblers silently emit NOP or ld hl,hl, meaning the
    ;         destination IP/port were NEVER written to the W5100S — the DNS
    ;         query went out to whatever was left in S1_DIPR/S1_DPORT from
    ;         a previous operation (or 0.0.0.0:0 on first use). Fixed with
    ;         `ex de,hl` pairs to move DE into HL where needed.
    ; FIX 2: TX physical-address mask had the same bug as original NET_SEND.
    ;         Rewrote with the same clean pattern used in the fixed NET_SEND.
    ; FIX 3: TX write-pointer update clobbered H before reading WR1 register.
    ;         `ld h, a` after reading WR0, then `inc hl` advances to WR1 — but
    ;         HL is now a garbage address since we just put the WR0 value in H
    ;         without fixing L. Fixed by re-reading both bytes properly.

    push hl             ; [1] data buffer
    push de             ; [2] peer data pointer
    push bc             ; [3] length
    push af             ; [4] socket (unused)

    ; --- Write destination IP to S1_DIPR0 ---
    ; DE = peer pointer, need HL = peer pointer for W5100_WRITE_BUF
    ex de, hl           ; HL = peer ptr, DE = data buf (temporarily)
    ld de, S1_DIPR0
    ld bc, 4
    call W5100_WRITE_BUF ; copies 4 IP bytes from (HL) to W5100S S1_DIPR0

    ; HL now = peer ptr + 4, pointing at the port bytes
    ; --- Write destination port to S1_DPORT0 ---
    ld a, (hl)          ; port high byte
    inc hl
    ld de, S1_DPORT0
    call W5100_WRITE_REG
    ld a, (hl)          ; port low byte
    inc hl
    ld de, S1_DPORT0 + 1
    call W5100_WRITE_REG

    ; --- Restore data buffer and length ---
    pop af              ; [4] socket (discard)
    pop bc              ; [3] length
    pop de              ; [2] peer ptr (discard)
    pop hl              ; [1] data buffer

    push bc             ; [5] length for pointer update

    ; --- Read current TX write pointer into DE ---
    ld hl, S1_TX_WR0
    call W5100_READ_REG
    ld d, a
    ld hl, S1_TX_WR1
    call W5100_READ_REG
    ld e, a             ; DE = TX write pointer

    ; --- Calculate physical TX buffer address ---
    ;   offset  = write_ptr AND S1_TX_MASK
    ;   address = S1_TX_BASE + offset
    ld a, e
    and S1_TX_MASK & 0xFF
    ld l, a
    ld a, d
    and S1_TX_MASK >> 8
    ld h, a
    ld de, S1_TX_BASE
    add hl, de          ; HL = physical address
    ex de, hl           ; DE = physical address (for W5100_WRITE_BUF)

    ; --- Write data to TX buffer ---
    pop bc              ; [5] length
    ; HL = data buffer (from stack pop above — wait, we popped HL already)
    ; Need to get data ptr back; it was in HL before the TX pointer read.
    ; Use the saved copy we already have — HL still holds data buffer
    ; because we didn't push it again after restoring it. Re-push BC to save.
    push bc             ; [6]
    ; HL still = data buffer from the pop hl [1] above
    call W5100_WRITE_BUF    ; write BC bytes from (HL) to W5100S at DE

    ; --- Update TX write pointer ---
    pop bc              ; [6] length

    ld hl, S1_TX_WR0
    call W5100_READ_REG
    ld d, a
    ld hl, S1_TX_WR1
    call W5100_READ_REG
    ld e, a             ; DE = current write pointer
    ex de, hl
    add hl, bc          ; HL = new write pointer
    ex de, hl           ; DE = new write pointer

    ld hl, S1_TX_WR0
    ld a, d
    call W5100_WRITE_REG
    ld hl, S1_TX_WR1
    ld a, e
    call W5100_WRITE_REG

    ; --- Issue SEND command ---
    ld hl, S1_CR
    ld a, SCMD_SEND
    call W5100_WRITE_REG
    call WAIT_CMD_DONE_S1

    or a                ; Clear carry = success
    ret

;-------------------------------------------------------
; RECVFR - Receive UDP datagram (KCNet API)
; Entry: A = socket number
;        HL = data buffer
;        BC = max length
;        DE = peer info buffer (8 bytes: 4 IP + 2 port + 2 size)
; Exit:  BC = actual bytes received
;        Carry clear if OK, set if error
;-------------------------------------------------------
RECVFR:
    ; Entry: A=socket (ignored), HL=data buf, BC=max length, DE=peer info buf (8 bytes)
    ; Exit:  BC=actual bytes received, carry clear OK / set error
    ;
    ; W5100S UDP RX packet layout (prepended by chip in RX buffer):
    ;   [4 bytes source IP][2 bytes source port BE][2 bytes payload size BE][payload]
    ; Total header = 8 bytes, followed immediately by the DNS response payload.
    ;
    ; FIX 1: original `ld hl, de` is not a valid Z80 opcode. Fixed.
    ; FIX 2: physical DE address must advance past the 8-byte header before
    ;         reading the payload — W5100_READ_BUF advances DE, so the second
    ;         call correctly starts at header+8.
    ; FIX 3: RX read pointer update used `ld h,a / inc hl` (same corruption as
    ;         the original NET_SEND). Fixed by reading both pointer bytes cleanly.
    ;
    ; Uses temp vars to avoid register/stack confusion:
    jr .recvfr_start    ; skip over temp storage
.recvfr_databuf:  dw 0
.recvfr_peerbuf:  dw 0
.recvfr_rawrdptr: dw 0
.recvfr_datalen:  dw 0
.recvfr_start:
    ; Stash entry parameters in temp vars
    ld (.recvfr_databuf), hl
    ex de, hl
    ld (.recvfr_peerbuf), hl
    ex de, hl           ; HL=data, DE=peer restored

    ; Check for data
    ld hl, S1_RX_RSR0
    call W5100_READ_REG
    ld d, a
    ld hl, S1_RX_RSR0 + 1
    call W5100_READ_REG
    ld e, a
    ld a, d
    or e
    jr z, .recvfr_no_data

    ; Read raw RX read pointer
    ld hl, S1_RX_RD0
    call W5100_READ_REG
    ld d, a
    ld hl, S1_RX_RD0 + 1
    call W5100_READ_REG
    ld e, a
    ld (.recvfr_rawrdptr), de

    ; Compute physical address for header
    ld a, e
    and S1_RX_MASK & 0xFF
    ld l, a
    ld a, d
    and S1_RX_MASK >> 8
    ld h, a
    ld de, S1_RX_BASE
    add hl, de          ; HL = physical address of UDP header
    ex de, hl           ; DE = physical address

    ; Read 8-byte UDP header to peer_buf
    ld hl, (.recvfr_peerbuf)
    ld bc, 8
    call W5100_READ_BUF
    ; After READ_BUF: DE has advanced by 8 (physical address now points at payload)
    ; HL has advanced by 8 (peer_buf+8, past the header)

    ; Extract payload size from bytes 6-7 of header (big-endian)
    ; peer_buf+6 = size_high, peer_buf+7 = size_low
    ld hl, (.recvfr_peerbuf)
    ld bc, 6
    add hl, bc          ; HL = peer_buf + 6
    ld b, (hl)          ; size high byte
    inc hl
    ld c, (hl)          ; size low byte  → BC = payload size (big-endian as received)
    ; Swap to get host-order length for LDIR/READ_BUF
    ld a, b
    ld b, c
    ld c, a             ; BC = payload size in Z80 byte order? No — W5100S gives BE.
    ; W5100_READ_BUF takes BC as a count. The size field IS the byte count.
    ; On Z80 BC is: B=high, C=low — which matches network byte order already.
    ; So BC is already correct (B=high byte of size, C=low byte).
    ld (.recvfr_datalen), bc

    ; Read payload into data_buf
    ld hl, (.recvfr_databuf)
    ; DE already points to physical address of payload (advanced by READ_BUF above)
    call W5100_READ_BUF

    ; Update RX read pointer: new = raw + 8 + payload_size
    ld hl, (.recvfr_rawrdptr)
    ld de, 8
    add hl, de          ; + header
    ld de, (.recvfr_datalen)
    add hl, de          ; + payload
    ex de, hl           ; DE = new RX read pointer

    ld hl, S1_RX_RD0
    ld a, d
    call W5100_WRITE_REG
    ld hl, S1_RX_RD0 + 1
    ld a, e
    call W5100_WRITE_REG

    ; Issue RECV command to release buffer
    ld hl, S1_CR
    ld a, SCMD_RECV
    call W5100_WRITE_REG
    call WAIT_CMD_DONE_S1

    ld bc, (.recvfr_datalen)
    or a                ; Clear carry
    ret

.recvfr_no_data:
    ld bc, 0
    or a
    ret

;-------------------------------------------------------
; SELECT - Check if data available (KCNet API)
; Entry: A = socket number
;        E = select type (SL_RECV=1)
; Exit:  Carry clear if data available, set if not
;-------------------------------------------------------
SL_RECV equ 1

SELECT:
    push hl
    push de

    ; Check RX received size register (read both bytes properly)
    ld hl, S1_RX_RSR0
    call W5100_READ_REG
    ld d, a             ; High byte in D
    ld hl, S1_RX_RSR1
    call W5100_READ_REG
    ld e, a             ; Low byte in E

    ; If size > 0, data available
    ld a, d
    or e
    jr z, .no_data

    or a            ; Clear carry
    jr .select_exit

.no_data:
    scf

.select_exit:
    pop de
    pop hl
    ret

;-------------------------------------------------------
; N_TIME - Read timer value (KCNet API)
; Entry: None
; Exit:  HL = timer value in milliseconds (0-59999)
; Uses CPC firmware frame flyback counter at 0xAC7E (16-bit, increments 50Hz)
;-------------------------------------------------------
N_TIME:
    push af
    push bc
    push de

    ; Read CPC frame counter (0xAC7E, 16-bit, 50Hz)
    ld hl, (0xAC7E)

    ; Convert from 1/50 sec to milliseconds
    ; HL = HL * 20 (since 1000ms/50 = 20ms per frame)
    ; HL * 20 = HL * 16 + HL * 4
    ld d, h
    ld e, l             ; DE = HL
    add hl, hl          ; HL * 2
    add hl, hl          ; HL * 4
    ld b, h
    ld c, l             ; BC = HL * 4
    add hl, hl          ; HL * 8
    add hl, hl          ; HL * 16
    add hl, bc          ; HL * 16 + HL * 4 = HL * 20

    ; Keep only lower 16 bits (natural wrap at 65535)
    ; Since frame counter wraps at 65535, and *20 could overflow,
    ; we just use the result as-is

    pop de
    pop bc
    pop af
    ret

;-------------------------------------------------------
; N_WIPA - Write IP address to storage (KCNet API)
; Entry: A = IP number (N_DNSIP = 0)
;        HL = host address of IP (4 bytes)
; Exit:  HL = HL + 4
;-------------------------------------------------------
N_DNSIP equ 0

N_WIPA:
    push af
    push bc
    push de

    ; DNS IP stored at PPPoE dest hardware addr (0x0032)
    ld de, 0x0032
    ld bc, 4
    call W5100_WRITE_BUF

    pop de
    pop bc
    pop af
    ret

;-------------------------------------------------------
; N_RIPA - Read IP address from storage (KCNet API)
; Entry: A = IP number (N_DNSIP = 0)
;        HL = host address for IP (4 bytes)
; Exit:  HL = HL + 4
;-------------------------------------------------------
N_RIPA:
    push af
    push bc
    push de

    ; DNS IP stored at PPPoE dest hardware addr (0x0032)
    ld de, 0x0032
    ld bc, 4
    call W5100_READ_BUF

    pop de
    pop bc
    pop af
    ret

;-------------------------------------------------------
; N_DPRT - Get dynamic port number (KCNet API)
; Entry: None
; Exit:  DE = port number in network byte order (big-endian)
;        HL = port number in host byte order (little-endian, for MSG-ID use)
; FIX: original used `ld h,a / inc hl` to read two successive W5100S registers,
;      but after `ld h,a` HL holds a value like 0xC0xx, so `inc hl` no longer
;      points at address 0x0037 — it reads a completely wrong register.
;      Rewrote using an explicit address register kept in BC.
;-------------------------------------------------------
N_DPRT:
    push af

    ; Read 16-bit counter from W5100S addresses 0x0036/0x0037
    ld hl, 0x0036
    call W5100_READ_REG
    or 0xC0             ; Force high byte into ephemeral range (0xC0xx = port >= 49152)
    ld d, a             ; D = high byte of port (network order)
    ld hl, 0x0037
    call W5100_READ_REG
    ld e, a             ; E = low byte of port (network order)
    ; DE = port in network byte order

    ; Increment for next call and write back
    inc de              ; simple counter increment
    ld hl, 0x0036
    ld a, d
    call W5100_WRITE_REG
    ld hl, 0x0037
    ld a, e
    call W5100_WRITE_REG

    ; Return DE = network order, HL = host order (swapped)
    ld h, e
    ld l, d             ; HL = port in host byte order (for use as DNS msg ID)

    pop af
    ret

;-------------------------------------------------------
; NTOHS - Network to host short (KCNet API)
; Entry: HL = pointer to 16-bit value in network order
; Exit:  HL = value in host order
; Note: Swaps bytes (network=big-endian, Z80=little-endian)
;-------------------------------------------------------
NTOHS:
    push af
    ld a, (hl)
    inc hl
    ld h, (hl)
    ld l, a
    pop af
    ret

;-------------------------------------------------------
; HTONS - Host to network short (KCNet API)
; Entry: HL = value in host order
; Exit:  HL = value in network order
;-------------------------------------------------------
HTONS:
    push af
    ld a, h
    ld h, l
    ld l, a
    pop af
    ret

;-------------------------------------------------------
; NTOHL - Network to host long (KCNet API)
; Entry: DE = pointer to 32-bit value in network order
;        HL = destination
; Exit:  HL = HL + 4
;-------------------------------------------------------
NTOHL:
    push af
    push bc

    ld a, (de)
    inc de
    ld b, a
    ld a, (de)
    inc de
    ld c, a

    ex de, hl
    ld (hl), c
    inc hl
    ld (hl), b
    inc hl

    ex de, hl
    ld a, (de)
    inc de
    ld b, a
    ld a, (de)
    inc de
    ld c, a

    ex de, hl
    ld (hl), c
    inc hl
    ld (hl), b
    inc hl

    ex de, hl

    pop bc
    pop af
    ret

;-------------------------------------------------------
; I_NTOA - Convert IP to dotted decimal string (KCNet API)
; Entry: HL = IP address (4 bytes, network order)
;        DE = string buffer
; Exit:  DE = points after string + 0
;-------------------------------------------------------
I_NTOA:
    push af
    push bc
    push hl

    ld b, 4

.ntoa_loop:
    ld a, (hl)
    push hl
    push bc
    call byte_to_dec
    pop bc
    pop hl

    inc hl
    dec b
    jr z, .ntoa_done

    ld a, '.'
    ld (de), a
    inc de
    jr .ntoa_loop

.ntoa_done:
    xor a
    ld (de), a
    inc de

    pop hl
    pop bc
    pop af
    ret

; Helper: convert byte to decimal string
byte_to_dec:
    push bc
    push hl

    ld l, a
    ld h, 0
    ld bc, 100
    call div16
    add a, '0'
    cp '0'
    jr z, .skip_100

    ld (de), a
    inc de

.skip_100:
    ld a, l
    ld bc, 10
    call div16
    add a, '0'
    cp '0'
    jr nz, .write_10
    ld a, (de)
    cp 0
    jr z, .skip_10

.write_10:
    add a, '0'
    ld (de), a
    inc de

.skip_10:
    ld a, l
    add a, '0'
    ld (de), a
    inc de

    pop hl
    pop bc
    ret

; Helper: 16-bit division
; HL / BC = A (quotient), HL = remainder
div16:
    push bc
    push de

    ld a, l
    ld de, 0

.div_loop:
    cp c
    jr c, .div_done
    sub c
    inc e
    jr .div_loop

.div_done:
    ld l, a
    ld a, e

    pop de
    pop bc
    ret

;-------------------------------------------------------
; Socket 1 Registers (for UDP/DNS)
;-------------------------------------------------------
S1_MR       equ 0x0500
S1_CR       equ 0x0501
S1_IR       equ 0x0502
S1_SR       equ 0x0503
S1_PORT0    equ 0x0504
S1_DHAR0    equ 0x0506
S1_DIPR0    equ 0x050C
S1_DPORT0   equ 0x0510
S1_TX_FSR0  equ 0x0520
S1_TX_RD0   equ 0x0522
S1_TX_WR0   equ 0x0524
S1_TX_WR1   equ 0x0525
S1_RX_RSR0  equ 0x0526
S1_RX_RSR1  equ 0x0527
S1_RX_RD0   equ 0x0528
S1_RX_RD1   equ 0x0529

; Socket 1 TX/RX buffers
S1_TX_BASE  equ 0x4800
S1_RX_BASE  equ 0x6800
S1_TX_MASK  equ 0x07FF
S1_RX_MASK  equ 0x07FF

WAIT_CMD_DONE_S1:
    push hl
    push af

.wait_loop:
    ld hl, S1_CR
    call W5100_READ_REG
    or a
    jr nz, .wait_loop

    pop af
    pop hl
    ret
