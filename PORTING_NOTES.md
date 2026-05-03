# Porting Notes: M4EWENTERM → N4CWENTERM

## Key Changes Made

### 1. Hardware Interface Layer

**M4 Board → Net4CPC W5100S**

| M4 Command | W5100S Equivalent | Implementation |
|------------|-------------------|----------------|
| `C_NETSOCKET` (0x4331) | `NET_SOCKET` | Direct W5100S register setup at 0xFD20 |
| `C_NETCONNECT` (0x4332) | `NET_CONNECT` | W5100S socket commands |
| `C_NETSEND` (0x4334) | `NET_SEND` | TX buffer write + SEND command |
| `C_NETRECV` (0x4335) | `NET_RECV` | RX buffer read + RECV command |
| `C_NETCLOSE` (0x4333) | `NET_CLOSE` | DISCONNECT + CLOSE commands |
| `C_NETHOSTIP` (0x4336) | (Not yet implemented) | Will use KCNet DNS client |

### 2. ROM Detection

**M4**: Scans for M4 ROM using `find_m4_rom` routine

**Net4CPC**: Checks for W5100S presence by reading mode register at 0xFD20

```asm
; M4 version
Check_m4:
    ld a, (m4_rom_num)
    cp 0xFF
    call z, find_m4_rom

; N4C version  
Check_n4c:
    ld hl, W51MR
    call W5100_READ_REG
    cp 3                ; W5100S returns 3 when initialized
```

### 3. Data Flow

**M4 Board**:
- Command packets sent to port 0xFE00
- ACK on port 0xFC00
- Response buffer at (0xFF02)
- Socket info at (0xFF06)

**Net4CPC**:
- Direct register access at 0xFD20-0xFD23
- No command packets - direct W5100S programming
- State tracked in W5100S socket registers

### 4. File Structure

**New Files**:
- `w5100.s` - Complete W5100S driver (replaces M4 command interface)
- `telnetfunc_n4c.s` - Adapted telnet functions
- `urlmenu_n4c.s` - Simplified IP input (DNS to be added)

**Unchanged**:
- `main.s` - Terminal setup and keyboard handling
- `ansiterm.s` - ANSI escape sequence processing
- `screen.s` - Screen management
- `negotiate.s` - Telnet negotiation
- `data.s` - Data definitions
- `charset.s` - Character set

### 5. Socket Management

**M4**: 
- Multiple sockets managed by M4 firmware
- Socket handle returned by firmware

**Net4CPC**:
- Currently uses Socket 0 only
- Could be extended to use Sockets 0-3
- Socket state in W5100S registers (SR, IR, etc.)

### 6. Network Order

Both systems use network byte order (big-endian) for:
- IP addresses
- Port numbers

Port conversion example:
```asm
; Convert port 23 to network order (0x0017)
port:   dw 0x1700       ; Stored as 0x17 0x00 in memory
```

### 7. Buffer Sizes

**M4**: Determined by firmware

**Net4CPC**: 
- 2KB TX buffer at 0x4000
- 2KB RX buffer at 0x6000
- Masks: 0x07FF

### 8. Testing Strategy

**Development**:
1. Test W5100S detection first
2. Test socket open/close
3. Test local telnet server (127.0.0.1:23)
4. Test internet servers (once routing configured)

**Required Configuration**:
- Run KCNet `NCFG.COM` under CP/M to set:
  - IP address
  - Subnet mask
  - Gateway
  - (Optional) DNS server

## Future Enhancements

### DNS Support
Add DNS lookup by interfacing with KCNet DNS client (`DNSC-11.INC`):
- Load DNS client code
- Use shared DNS IP storage at W5100S PPPoE register (0x0032)
- Parse domain names before numeric IP check

### Multi-Socket Support
Extend to use all 4 W5100S sockets:
- Array of socket structures
- Socket selection menu
- Background connections

### CP/M Integration
Could be adapted to run under CP/M:
- Use BDOS calls for console I/O
- Interface with other KCNet utilities
- Share network configuration

## Debugging Tips

1. **W5100S not detected**: Check Net4CPC hardware, verify 0xFD20 address
2. **Connection fails**: Verify network config with NCFG.COM
3. **No data received**: Check RX_RSR register (0x0426/0x0427)
4. **Send fails**: Check TX_FSR register (0x0420/0x0421)
5. **Unexpected disconnects**: Monitor SR register (0x0403) for state changes

## Register Reference

### Common Registers
- `0x0000` - MR (Mode Register)
- `0x0009-0x000E` - MAC Address
- `0x000F-0x0012` - Source IP

### Socket 0 Registers
- `0x0400` - S0_MR (Mode)
- `0x0401` - S0_CR (Command)
- `0x0402` - S0_IR (Interrupt)
- `0x0403` - S0_SR (Status)
- `0x0404-0x0405` - S0_PORT (Source Port)
- `0x040C-0x040F` - S0_DIPR (Dest IP)
- `0x0410-0x0411` - S0_DPORT (Dest Port)
- `0x0420-0x0421` - S0_TX_FSR (TX Free Size)
- `0x0424-0x0425` - S0_TX_WR (TX Write Pointer)
- `0x0426-0x0427` - S0_RX_RSR (RX Received Size)
- `0x0428-0x0429` - S0_RX_RD (RX Read Pointer)

## Resources

- [W5100S Datasheet](https://www.wiznet.io/product-item/w5100s/)
- [KCNet Documentation](http://kc85.info/index.php/kcnet-de.html)
- [Net4CPC GitHub](https://github.com/salafek/Net4CPC)
- [M4EWENTERM GitHub](https://github.com/fleen/m4ewenterm/)
