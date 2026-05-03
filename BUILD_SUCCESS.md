# Build Complete! ✅

## Generated Files

Your N4CWENTERM terminal has been successfully built!

### Files Ready for CPC:

1. **EWEN.BAS** (995 bytes)
   - BASIC loader program
   - Configures DNS (8.8.8.8)
   - Loads binaries and installs RSX

2. **EWENN4C.BIN** (10,418 bytes)
   - Main terminal binary
   - TCP/IP networking
   - DNS resolution
   - ANSI terminal emulation
   - Telnet protocol

3. **CHARSET.BIN** (2,176 bytes)
   - Character set (Code Page 437)
   - Required for proper display

## Installation

### On M4 Board (SD Card):
```
Copy all three files to the root of your M4 SD card
```

### On Real CPC:
```
Transfer via serial, disc, or other method to CPC
```

### On Emulator:
```
Add files to disc image or drag-and-drop into emulator
```

## Usage

1. On CPC, type:
   ```
   RUN"EWEN
   ```

2. You'll see:
   ```
   Loading N4C-EWEN Terminal...
   
   Configuring DNS server (8.8.8.8)...
   DNS configured OK
   
   Ewen-Term Communications program, v3.0 N4C installed.
   DNS: 8.8.8.8 (Google)
   
   Type |TERM to start terminal mode
   ```

3. Start the terminal:
   ```
   |TERM
   ```

4. Connect to a server:
   ```
   Input server name or IP (:PORT or default to 23):
   telehack.com
   
   Resolving: telehack.com... OK
   Connecting to IP 206.125.69.232 port 23
   Connected.
   ```

5. Enjoy vintage computing on the modern internet!

## Features Included

✅ TCP/IP networking via W5100S  
✅ DNS resolution (automatic with Google DNS)  
✅ Telnet protocol with basic negotiation  
✅ ANSI terminal emulation  
✅ Code Page 437 character set  
✅ Domain name and IP address support  
✅ Pause (SHIFT-TAB) and Disconnect (SHIFT-ESC)  

## Prerequisites

Before running, ensure:
- ✅ Net4CPC hardware installed
- ✅ Network configured via CP/M NCFG.COM
  - IP address set
  - Subnet mask set
  - Gateway set
- ✅ Network cable connected
- ✅ DNS works (8.8.8.8 reachable from your network)

## Testing

Try these services:
- `telehack.com` - Retro simulation
- `sdf.org` - Public UNIX
- `amstrad.simulant.uk:464` - Amstrad BBS
- Or any telnet server you can reach!

## Troubleshooting

See:
- **README.md** - Full documentation
- **QUICK_START.md** - Quick start guide
- **DNS_SETUP.md** - DNS configuration help

## Build Info

- **Assembler**: RASM (www.roudoudou.com/rasm)
- **Based on**: M4EWENTERM by F Leen (2023)
- **Original**: Ewenterm by Ewen McNeill (1991)
- **Net4CPC**: KCNet by susowa (2008)
- **Build date**: 2026-05-03

---

**Happy retro networking!** 🎮📡
