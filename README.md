# N4CWENTERM

Under developement. Name resolution does not work yet

## An ANSI Telnet client for the Amstrad CPC with Net4CPC

*Built for time travel to 1985... with a Net4CPC board.*

Based on:
- **M4EWENTERM** (https://github.com/fleen/m4ewenterm/) 2023 by F Leen
- **Ewenterm** (https://ewen.mcneill.gen.nz/programs/cpc/ewenterm/) 1991 by Ewen McNeill
- **Net4CPC** (https://github.com/salafek/Net4CPC) - W5100S Ethernet interface

## Requirements

- Amstrad CPC (464/664/6128)
- Net4CPC Ethernet interface board with W5100S chip
- RASM assembler (www.roudoudou.com/rasm) for building from source

## What is Net4CPC?

Net4CPC is an Ethernet interface for the Amstrad CPC that uses the WIZnet W5100S TCP/IP chip. The W5100S is accessed at I/O address `0xFD20` and provides hardware-accelerated TCP/IP networking.

## Building

```bash
./build.sh
```

This will generate:
- `EWENN4C.BIN` - The terminal binary
- `CHARSET.BIN` - Character set data

## Usage

1. Copy `EWEN.BAS`, `EWENN4C.BIN` and `CHARSET.BIN` to your CPC (or M4/SD card)

2. On the CPC:

```
RUN"EWEN
```

3. The program will install the `|TERM` RSX command. Type:

```
|TERM
```

4. Enter a domain name or IP address with optional port:

```
Input server name or IP (:PORT or default to 23):
telehack.com:23
```

or

```
Input server name or IP (:PORT or default to 23):
192.168.1.100:23
```

Format: 
- Domain: `hostname.com:port` (port defaults to 23 if omitted)
- IP: `xxx.xxx.xxx.xxx:port` (port defaults to 23 if omitted)

5. All keypresses will go to the remote host, except:
   - **SHIFT-TAB** - Pause (press SHIFT-TAB again to resume)
   - **SHIFT-ESC** - Disconnect

## Network Configuration

Before using N4CWENTERM, you need to configure your Net4CPC network settings using the KCNet utilities under CP/M:

1. Run `NCFG.COM` to configure:
   - IP address
   - Subnet mask
   - Gateway

**DNS is automatically configured!** The BASIC loader sets Google DNS (8.8.8.8) automatically. To use a different DNS server, see `DNS_SETUP.md` for configuration instructions.

## Features

- ANSI terminal emulation
- Telnet protocol support (basic negotiation)
- **DNS resolution** - Enter domain names directly!
- Direct W5100S socket interface for fast networking
- Works with BBS systems and telnet servers

## Limitations

- Dual socket usage - Socket 0 for TCP (telnet), Socket 1 for UDP (DNS)
- Basic telnet negotiation - Some advanced telnet options not implemented
- 2KB TX/RX buffers per socket (W5100S limitation)
- DNS must be configured before use (via NCFG.COM or manually)

## Testing

Good places to test (DNS now working!):

- **telehack.com** - Retro simulation with tons of commands
  - Try: `cat vttest.vt`, `phoon`, `rain`, `starwars`, `clock`
- **sdf.org** - Public access UNIX system
- **amstrad.simulant.uk:464** - Amstrad-specific BBS
- **ciaamigabbs.dynu.net:6400** - Amiga BBS
- **godwars.net:2250** - MUD game
- **horizons.jpl.nasa.gov:6775** - NASA JPL Horizons system

Or use IP addresses directly:
- Your local Linux box running telnetd
- Local BBS software (Synchronet, Mystic, etc.)

## Technical Details

### Memory Map

- `0x6800` - Character set
- `0x7000` - Main binary (RSX and terminal code)

### W5100S Socket Operations

The code uses two W5100S sockets:

**Socket 0 (TCP)** - Telnet connection:
- **NET_SOCKET** - Initialize TCP socket
- **NET_CONNECT** - Connect to IP:port
- **NET_SEND** - Send data
- **NET_RECV** - Receive data
- **NET_CLOSE** - Close connection
- **CHECK_CONNECTION** - Verify connection status

**Socket 1 (UDP)** - DNS queries:
- **SOCKET** - Initialize UDP socket (KCNet API)
- **SENDTO** - Send DNS query
- **RECVFR** - Receive DNS response
- **SELECT** - Check for data
- **CLOSE** - Close UDP socket

### File Structure

```
n4cwenterm/
├── build.sh              # Build script
├── README.md             # This file
├── DNS_SETUP.md          # DNS configuration guide
└── src/
    ├── EWEN.BAS          # BASIC loader
    ├── termN4C.s         # Main assembly entry point
    ├── w5100.s           # W5100S driver (TCP + UDP + KCNet API)
    ├── dnsc-11.s         # KCNet DNS client (RFC 1034)
    ├── telnetfunc_n4c.s  # Telnet protocol handling
    ├── urlmenu_n4c.s     # URL/IP input with DNS support
    ├── main.s            # Terminal mode setup
    ├── ansiterm.s        # ANSI escape sequence handling
    ├── screen.s          # Screen management
    ├── negotiate.s       # Telnet negotiation
    ├── data.s            # Data definitions
    └── charset.s         # Character set data
```

## TODO / Ideas

- [x] ~~Add DNS lookup support~~ **DONE!**
- [ ] Add upload/download protocols (XMODEM, YMODEM)
- [ ] Save/load connection presets (favorites)
- [ ] More complete telnet option negotiation
- [ ] Color support in MODE 1
- [ ] Capture to disc/tape
- [ ] Integration with KCNet utilities (FTP, TFTP, etc.)
- [ ] Connection timeout handling
- [ ] Better error messages

## Differences from M4EWENTERM

- Uses W5100S hardware TCP/IP instead of M4 network commands
- Direct I/O port access at `0xFD20`
- No ROM scanning (no M4 ROM to find)
- **DNS resolution using KCNet DNS client**
- Different initialization sequence for W5100S
- Dual socket architecture (TCP + UDP)

## Known Issues

- Port number parsing may have issues with very large ports
- No timeout on connection/DNS attempts yet
- Error messages could be more descriptive
- W5100S must be initialized by KCNet utilities first (run NCFG.COM)
- DNS queries have 3 retries with exponential backoff (can be slow on failure)

## Credits

- **F Leen** - M4EWENTERM (2023)
- **Ewen McNeill** - Original Ewenterm (1991)
- **Duke** - M4 telnet example (2018)
- **susowa** - KCNet TCP/IP stack
- **salafek** - Net4CPC hardware

## License

GNU General Public License v3.0 (same as M4EWENTERM)

See LICENSE file for details.

---

If this is useful to you, please consider buying F Leen (original M4EWENTERM author) a coffee!

**Adapted for Net4CPC - 2026**
