# Quick Start Guide - N4CWENTERM

## Prerequisites

1. **Amstrad CPC** with Net4CPC board installed
2. **Network configured** via CP/M NCFG.COM:
   - IP address set
   - Subnet mask set
   - Gateway set

## Installation

1. Copy these files to your CPC (M4 SD card, disc, etc.):
   - `EWEN.BAS`
   - `EWENN4C.BIN`
   - `CHARSET.BIN`

2. On your CPC, run:
   ```
   RUN"EWEN
   ```

## What You'll See

```
Loading N4C-EWEN Terminal...

Configuring DNS server (8.8.8.8)...
DNS configured OK

Ewen-Term Communications program, v3.0 N4C installed.
DNS: 8.8.8.8 (Google)

Type |TERM to start terminal mode
```

## Using the Terminal

1. Type:
   ```
   |TERM
   ```

2. Enter a domain name or IP address:
   ```
   Input server name or IP (:PORT or default to 23):
   telehack.com
   ```
   
   Or with a port:
   ```
   Input server name or IP (:PORT or default to 23):
   sdf.org:22
   ```

3. DNS resolution happens automatically:
   ```
   Resolving: telehack.com... OK
   Connecting to IP 206.125.69.232 port 23
   Connected.
   ```

4. You're now connected! All keypresses go to the remote host.

## Special Keys

- **SHIFT-TAB** - Pause (press SHIFT-TAB again to resume)
- **SHIFT-ESC** - Disconnect and return to input screen

## Try These Services

### BBS & Telnet Servers
- `telehack.com` - Retro simulation (try: `starwars`, `phoon`, `rain`)
- `sdf.org` - Public UNIX system
- `amstrad.simulant.uk:464` - Amstrad BBS

### Games
- `godwars.net:2250` - MUD game

### Educational
- `horizons.jpl.nasa.gov:6775` - NASA JPL Horizons system

## Troubleshooting

### "No Net4CPC found"
- Check hardware connections
- Run CP/M NCFG.COM to initialize

### "DNS lookup failed"
- Your network may not route to 8.8.8.8
- Try editing EWEN.BAS to use your router's IP (usually 192.168.1.1 or 192.168.0.1)
- See DNS_SETUP.md for details

### "Connection failed"
- Check network cable
- Verify gateway is configured correctly in NCFG.COM
- Ping test: Under CP/M, try `PING 8.8.8.8`

### Connection is very slow
- Normal! The CPC and W5100S are not speed demons
- Large downloads will take time
- ANSI rendering can be slow on complex screens

## Tips

- MODE 2 (monochrome) gives best results
- Use simple, text-based services for best experience
- MUDs and BBSs work great!
- Modern web-based services may timeout
- Some services may not work well with basic telnet negotiation

## Going Further

- Edit EWEN.BAS line 610 to auto-start terminal mode
- Modify DNS server in EWEN.BAS lines 170-200
- See README.md for technical details
- See PORTING_NOTES.md for developer info

---

**Have fun exploring the net on your CPC!** 🎮🌐
