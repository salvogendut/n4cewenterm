# Build Instructions for N4CEWENTERM

## Prerequisites

You need the RASM assembler to build this project.

**Download RASM:** http://www.roudoudou.com/rasm/

## Setting Up RASM

You have two options:

### Option 1: Add RASM to PATH (Recommended)

Install rasm and add it to your system PATH. The build script will automatically find it.

### Option 2: Set RASM Environment Variable

Set the `RASM` environment variable to point to your rasm executable:

```bash
export RASM=/path/to/rasm.exe
```

Add this to your `~/.bashrc` or `~/.zshrc` to make it permanent.

## Building

Simply run:

```bash
./build.sh
```

This will:
1. Create a `bin/` directory if it doesn't exist
2. Assemble the character set and main binary
3. Move the output files to `bin/`

## Build Output

After a successful build, you'll find:

```
bin/
├── CHARSET.BIN  - Character set (2176 bytes)
└── N4CEWEN.BIN  - Terminal binary (12466 bytes)
```

## Installing on CPC

Copy these files to your Amstrad CPC:
1. `src/N4CEWEN.BAS` - BASIC loader
2. `bin/N4CEWEN.BIN` - Main program
3. `bin/CHARSET.BIN` - Character set

Then run on your CPC:
```basic
RUN"N4CEWEN
```

## Troubleshooting

**Error: "RASM assembler not found!"**

Make sure you've either:
- Installed RASM and added it to your PATH, or
- Set the RASM environment variable

**Build succeeds but files are missing:**

Check the `bin/` directory - all output files go there.

**Permission denied when running build.sh:**

Make the script executable:
```bash
chmod +x build.sh
```
