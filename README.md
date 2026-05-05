# N4CEWENTERM - ANSI Telnet Client for Amstrad CPC

An ANSI terminal emulator and Telnet client for the Amstrad CPC with Net4CPC (W5100S Ethernet) hardware.

## Overview

N4CEWENTERM is a full-featured telnet client based on the classic Ewenterm (1991) and M4EWENTERM (2023), adapted for the Net4CPC hardware. It supports:

- **ANSI terminal emulation** - Colors, cursor positioning, text attributes
- **Telnet protocol** - IAC command negotiation
- **DNS resolution** - Connect using hostnames (e.g., "aardwolf.org")
- **IP connections** - Direct IP address connections
- **Custom ports** - Specify ports (e.g., "example.com:23")

## Network Library

This application includes local copies of the n4c-nettools networking library:
- `src/w5100.s` - W5100S hardware driver (28KB)
- `src/dns_simple.s` - DNS resolver (14KB)

These files are maintained in the main n4c-nettools repository. See `../n4c-nettools/` for the reference implementation and documentation.

**Note:** This is a self-contained application. All required files are included in this directory.

## Building

### Requirements
- **RASM** assembler (http://www.roudoudou.com/rasm/)

### Build Steps
```bash
./build.sh
```

This produces:
- `EWENN4C.BIN` - Terminal program (12466 bytes)
- `CHARSET.BIN` - Character set (2176 bytes)

## Installation

Copy these files to your CPC:
1. `src/EWEN.BAS`
2. `EWENN4C.BIN`
3. `CHARSET.BIN`

Then run: `RUN"EWEN`

## Usage

**Connect by hostname:** `aardwolf.org`
**With custom port:** `example.com:2323`  
**By IP:** `192.168.1.50:23`

**During session:**
- ESC - Disconnect
- TAB - Pause/unpause

## Project Structure

Shared library: `../n4c-nettools/` (W5100S driver, DNS resolver)
This app: Telnet-specific code only

See README files in each directory for details.
