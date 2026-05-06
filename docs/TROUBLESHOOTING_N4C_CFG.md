# Troubleshooting: N4C.CFG Not Found

## Symptom
When running `|TERM`, you see:
```
N4C Network Initialization
ERROR: N4C.CFG not found
```

## Common Causes

### 1. File Not on Disk
**Most Common Issue**

The N4C.CFG file must be on the **same disk** as N4CEWEN.BIN.

**Check:**
```basic
CAT
```
or
```basic
|DIR
```

You should see N4C.CFG in the file listing.

**Solution:**
Copy N4C.CFG to your CPC disk alongside the other files.

### 2. Wrong Filename or Extension

The file MUST be named exactly: `N4C.CFG`

**Common mistakes:**
- ❌ `N4C.CFG.txt` (extra extension)
- ❌ `N4C.CONFIG` (wrong extension)
- ❌ `n4c.cfg` (lowercase - usually OK but try uppercase)
- ❌ `N4C .CFG` (space in name)

**Solution:**
Rename the file to exactly `N4C.CFG`

### 3. File on Different Drive

If you have multiple drives, the file might be on the wrong one.

**Solution:**
Make sure N4C.CFG is on the same drive (A: or B:) as the program.

### 4. File Format Issues

The file might have the wrong format or be corrupted.

**Check file size:**
Should be around 60 bytes (varies slightly with IP lengths)

**Test on CPC:**
```basic
OPENIN "N4C.CFG"
IF EOF THEN PRINT "Not found!" ELSE PRINT "Found!"
CLOSEIN
```

## Step-by-Step Diagnosis

### Step 1: Verify File Exists

On your CPC:
```basic
CAT
```

Look for `N4C.CFG` in the output.

### Step 2: Test File Can Be Opened

Run the test program:
```basic
LOAD "TEST_CFG.BAS"
RUN
```

Expected output:
```
Testing N4C.CFG file...
File opened successfully!
Line 1: IP=192.168.1.100
Line 2: MASK=255.255.255.0
Line 3: GW=192.168.1.1
Line 4: DNS=192.168.1.1
Test complete.
```

If you get "ERROR: File not found!" then the file isn't on the disk or has the wrong name.

### Step 3: Check File Contents

```basic
OPENIN "N4C.CFG"
FOR I=1 TO 4
INPUT #9,A$
PRINT A$
NEXT I
CLOSEIN
```

Should show your 4 config lines (key=value format).

### Step 4: Recreate File on CPC

If the file isn't found, create it directly on the CPC:

```basic
10 OPENOUT "N4C.CFG"
20 PRINT #9,"IP=192.168.1.100"
30 PRINT #9,"MASK=255.255.255.0"
40 PRINT #9,"GW=192.168.1.1"
50 PRINT #9,"DNS=192.168.1.1"
60 CLOSEOUT
70 PRINT "N4C.CFG created!"
```

Replace the IP addresses with your network settings.

## Alternative: Hardcode Configuration

If you can't get the file to work, you can hardcode the settings temporarily to test:

**Edit n4c-netinit.s** and replace the file reading code with hardcoded values. This is a temporary workaround for testing.

## Files to Copy Checklist

Make sure ALL these files are on your CPC disk:

- [ ] N4CEWEN.BAS
- [ ] N4CEWEN.BIN
- [ ] CHARSET.BIN
- [ ] N4C.CFG ← **Don't forget this one!**

## Verification Commands

On CPC:
```basic
PRINT FRE(0)              ' Check free memory
CAT                        ' List files
OPENIN "N4C.CFG":PRINT "OK":CLOSEIN   ' Quick test
```

## Creating N4C.CFG on CPC (Emergency)

If your PC-created file doesn't work, create it on the CPC:

```basic
10 OPENOUT "N4C.CFG"
20 PRINT #9,"IP=192.168.1.100"     :REM Your IP
30 PRINT #9,"MASK=255.255.255.0"   :REM Netmask
40 PRINT #9,"GW=192.168.1.1"       :REM Gateway
50 PRINT #9,"DNS=192.168.1.1"      :REM DNS
60 CLOSEOUT
```

Run this, then try `|TERM` again.

## Still Not Working?

### Debug: Check What Files Are Actually Present

```basic
10 PRINT "Checking for required files..."
20 OPENIN "N4C.CFG":IF EOF THEN PRINT "N4C.CFG: NOT FOUND":GOTO 40 ELSE PRINT "N4C.CFG: OK"
30 CLOSEIN
40 OPENIN "N4CEWEN.BIN":IF EOF THEN PRINT "N4CEWEN.BIN: NOT FOUND":GOTO 60 ELSE PRINT "N4CEWEN.BIN: OK"
50 CLOSEIN
60 OPENIN "CHARSET.BIN":IF EOF THEN PRINT "CHARSET.BIN: NOT FOUND":GOTO 80 ELSE PRINT "CHARSET.BIN: OK"
70 CLOSEIN
80 PRINT "Check complete."
```

### Debug: Show File Size

```basic
OPENIN "N4C.CFG"
L=0
WHILE NOT EOF
INPUT #9,A$
L=L+LEN(A$)+2
WEND
CLOSEIN
PRINT "N4C.CFG size: ";L;" bytes"
```

Should show around 60 bytes.

## Questions to Answer

1. **Did you copy N4C.CFG to the CPC disk?**
2. **Does CAT show N4C.CFG in the file list?**
3. **Can you open it with OPENIN "N4C.CFG" from BASIC?**
4. **What happens when you run TEST_CFG.BAS?**

Please try these steps and let me know what you find!

## Quick Fix: Create Config on CPC Now

The fastest solution - type this on your CPC right now:

```basic
OPENOUT"N4C.CFG":PRINT#9,"IP=192.168.1.100":PRINT#9,"MASK=255.255.255.0":PRINT#9,"GW=192.168.1.1":PRINT#9,"DNS=192.168.1.1":CLOSEOUT
```

Then run `|TERM` again.
