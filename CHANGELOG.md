# Changelog

## [Unreleased] - Configuration File Support

### Added
- **N4C.CFG configuration file** - Network settings now in external text file
- **n4c-netinit.s module** - Shared network initialization code
- **CONFIG.md** - Comprehensive configuration documentation
- **N4C.CFG.example** - Example configuration file
- Automatic network initialization on startup
- Configuration display on screen during initialization
- Error handling for missing or invalid config files

### Changed
- **EWEN.BAS simplified** - Removed all network configuration code
- **main.s** - Added N4C_INIT call at startup
- **termN4C.s** - Included n4c-netinit.s module
- Binary size increased from 12466 to 13234 bytes (+768 bytes for config module)

### Removed
- Hardcoded network settings from EWEN.BAS
- Manual W5100S register configuration in BASIC
- Network verification code in BASIC

### Benefits
- ✅ Easy to change network settings (edit one text file)
- ✅ No BASIC code modification required
- ✅ Same config file for all n4c-nettools applications
- ✅ Clear error messages if config missing or invalid
- ✅ Network settings portable between disks

### Migration from Old Version

**Old method (EWEN.BAS lines 169-193):**
```basic
169 REM Write IP: 192.168.68.254
170 OUT &FD21,0:OUT &FD22,&F:OUT &FD23,192
171 OUT &FD21,0:OUT &FD22,&10:OUT &FD23,168
...
```

**New method (N4C.CFG file):**
```
192.168.68.254
255.255.255.0
192.168.68.1
192.168.68.54
```

### Files to Copy to CPC

**Before:**
- EWEN.BAS (with your settings edited)
- EWENN4C.BIN
- CHARSET.BIN

**After:**
- EWEN.BAS (no editing needed!)
- EWENN4C.BIN
- CHARSET.BIN
- N4C.CFG (your settings)

### Upgrading

1. Create `N4C.CFG` with your network settings (4 lines)
2. Copy new EWEN.BAS, EWENN4C.BIN, CHARSET.BIN to your disk
3. Copy N4C.CFG to your disk
4. Run as normal with `RUN"EWEN`

Your old EWEN.BAS with hardcoded settings will no longer work with the new binary.

## Previous Versions

### [1.0.0] - DNS Integration
- Added DNS hostname resolution
- Integrated dns_simple.s library
- Fixed 9 critical bugs in DNS implementation
- Can connect using hostnames (e.g., "aardwolf.org")

### [0.9.0] - Initial Net4CPC Port
- Ported from M4EWENTERM
- Adapted for Net4CPC (W5100S) hardware
- ANSI terminal emulation
- Telnet protocol support
- TCP connections via IP address
