# CPC File Format Requirements

## Critical: Line Endings

**ALL text files that will be used on the Amstrad CPC MUST have DOS-style line endings (CR+LF).**

### Why This Matters

The Amstrad CPC uses CP/M-style line endings (same as DOS/Windows):
- **CR** = Carriage Return (0x0D, ASCII 13)
- **LF** = Line Feed (0x0A, ASCII 10)
- **Together** = CR+LF (0x0D 0x0A)

Unix/Linux files use only LF (0x0A), which causes problems on the CPC:
- BASIC files show "Line too long" error
- Config files may not be read correctly
- Programs may hang or crash

### Files That Need CR+LF

1. **BASIC files** (*.BAS)
   - EWEN.BAS
   - DNS.BAS
   - Any BASIC loader

2. **Configuration files**
   - N4C.CFG
   - Any .CFG files

3. **Text data files**
   - Any text file loaded by the CPC program

### Files That Don't Need CR+LF

- Source code (*.s) - only used on PC/Mac for assembly
- Build scripts (*.sh) - only used on PC/Mac
- Documentation (*.md) - only used on PC/Mac
- Binary files (*.BIN) - not text files

## How to Fix Line Endings

### Automated (Recommended)

Run the provided script:
```bash
./fix_cpc_files.sh
```

This checks and converts all BASIC and config files.

### Manual Conversion

#### On Linux/Mac:

**Method 1: perl**
```bash
perl -pi -e 's/\r?\n/\r\n/' filename.BAS
```

**Method 2: unix2dos (if installed)**
```bash
unix2dos filename.BAS
```

**Method 3: sed**
```bash
sed -i 's/$/\r/' filename.BAS
```

#### On Windows:

Files created in Notepad or most Windows editors automatically have CR+LF.

#### Create Directly on CPC:

The CPC automatically uses CR+LF when creating files:
```basic
10 OPENOUT "N4C.CFG"
20 PRINT #9,"192.168.68.254"
30 CLOSEOUT
```

## How to Verify

### Check File Format

```bash
file EWEN.BAS
```

**Good:** `ASCII text, with CRLF line terminators`  
**Bad:** `ASCII text` (Unix LF only)

### Check Hex Dump

```bash
hexdump -C EWEN.BAS | head
```

Look for `0d 0a` at line endings:

**Good:**
```
00000020  69 6e 61 6c 0d 0a 32 30  20 52 45 4d
            ^^^^^ ^^^^^ 
            CR    LF    = Correct!
```

**Bad:**
```
00000020  69 6e 61 6c 0a 32 30 20  52 45 4d
                  ^^^^^ 
                  LF only = Wrong!
```

## Pre-Release Checklist

Before copying files to CPC or creating a release:

- [ ] Run `./fix_cpc_files.sh`
- [ ] Verify EWEN.BAS: `file src/EWEN.BAS` shows "with CRLF"
- [ ] Verify N4C.CFG: `file N4C.CFG` shows "with CRLF"
- [ ] Test on actual CPC or emulator
- [ ] If using git, ensure .gitattributes doesn't force LF

## Git Configuration

If using git, you may want to add `.gitattributes`:

```
# Force CRLF for CPC files
*.BAS text eol=crlf
*.CFG text eol=crlf

# Let git handle everything else normally
*.s text
*.md text
*.sh text eol=lf
```

This ensures CPC files always have correct line endings even when cloning on different systems.

## Common Errors and Solutions

### Error: "Line too long" in BASIC

**Cause:** BASIC file has Unix (LF only) line endings  
**Solution:** Convert to CR+LF

```bash
perl -pi -e 's/\r?\n/\r\n/' src/EWEN.BAS
```

### Error: Config file not read correctly

**Cause:** N4C.CFG has Unix line endings  
**Solution:** Convert to CR+LF

```bash
perl -pi -e 's/\r?\n/\r\n/' N4C.CFG
```

### Program hangs when reading file

**Cause:** Text data file has wrong line endings  
**Solution:** Convert all text files to CR+LF

## Best Practices

1. **Always use the fix script before testing on CPC**
2. **Check file format after editing** (especially on Linux/Mac)
3. **Add file checks to your build process**
4. **Document line ending requirements** in README
5. **Test on actual CPC** before releasing

## Reference

This issue affects all CP/M-based systems (Amstrad CPC, PCW, Spectrum +3, etc.) as they expect DOS-style line endings.

Modern systems:
- **Windows:** CR+LF (0x0D 0x0A) ✓ Compatible with CPC
- **Unix/Linux:** LF (0x0A) only ✗ Not compatible
- **Classic Mac:** CR (0x0D) only ✗ Not compatible
- **CP/M/DOS:** CR+LF (0x0D 0x0A) ✓ CPC standard
