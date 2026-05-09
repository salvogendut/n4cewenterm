# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

N4CEWENTERM is an ANSI terminal emulator and Telnet client written in **Z80 assembly** for the **Amstrad CPC** microcomputer with **Net4CPC** (W5100S Ethernet) hardware. There is no host-side runtime — the code runs entirely on the CPC.

## Build

**Requirement:** [RASM assembler](http://www.roudoudou.com/rasm/) must be installed and on `$PATH`. If anything requires the `scc` compiler, use the binaries in `$HOME/Dev/scc/bin`.

```bash
./build.sh
```

Produces `bin/CHARSET.BIN` (2176 bytes) and `bin/N4CEWEN.BIN` (~13 KB). There is no test suite — verification requires running on real CPC hardware or an emulator.

## Architecture

All source is Z80 assembly under `src/`. `src/termN4C.s` is the master file that `INCLUDE`s every other module; RASM only needs to assemble this one file (and `src/charset.s` separately).

**Execution flow:** `N4CEWEN.BAS` (BASIC loader) → `main.s` (init keyboard/screen) → `n4c-netinit-kv.s` (parse `N4C.CFG`, init W5100S) → `urlmenu_n4c.s` (accept hostname/IP:port) → `dns_simple.s` (resolve hostname if needed) → `telnetfunc_n4c.s` (TCP connect) → `negotiate.s` (Telnet IAC) → `ansiterm.s` + `screen.s` (live terminal).

**Key modules:**

| File | Role |
|------|------|
| `w5100.s` | W5100S Ethernet chip driver — raw register access for socket ops |
| `telnetfunc_n4c.s` | TCP session management, send/receive loop |
| `ansiterm.s` | ANSI ESC sequence parser (colors, cursor, attributes) |
| `screen.s` | CPC screen output, scrolling |
| `urlmenu_n4c.s` | User input: hostname or IP, optional `:port` |
| `negotiate.s` | Telnet IAC negotiation (NAWS window size, echo) |
| `dns_simple.s` | Minimal DNS resolver (A record lookup) |
| `n4c-netinit-kv.s` | Parses `N4C.CFG` (key=value) and initializes networking |
| `data.s` | Shared buffers, lookup tables, constants |
| `charset.s` | Custom 8×8 character set bitmap data |

**Memory layout:** Binary loads at `0x7000`, charset at `0x6800`, CPC screen at `0xC000`.

**Firmware:** Uses standard CPC firmware calls (`KM_*` keyboard, `TXT_*` text, `SCR_*` screen) via RST/CALL.

## Critical: CPC File Line Endings

Any file that gets copied to the CPC disk (`.BAS`, `N4C.CFG`) **must use DOS CR+LF line endings** (`0x0D 0x0A`). Unix LF-only causes a "Line too long" error on the CPC BASIC interpreter.

```bash
./fix_cpc_files.sh   # converts line endings for all CPC-destined files
```

## Upstream Networking Library

`w5100.s`, `dns_simple.s`, and `n4c-netinit-kv.s` are **copied from** the sibling repo `../n4c-nettools` — that repo is the canonical source for these files. If you need to fix a bug or change behaviour in the networking layer, check whether the fix belongs upstream first, then sync the copy here.

`../n4c-nettools/docs/BUGS_FIXED.md` catalogs 9 previously-found Z80 register bugs in the networking code (register overwrite, pop-before-read, wrong parameter order, pointer lifetime errors). Read it before touching any of those three files.

## Network Configuration

`N4C.CFG` is a plain text file (with CR+LF endings) read at startup:

```
IP=192.168.1.100
MASK=255.255.255.0
GW=192.168.1.1
DNS=8.8.8.8
```

See `N4C.CFG.example` and `docs/CONFIG.md` for details.
