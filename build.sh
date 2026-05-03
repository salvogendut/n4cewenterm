#!/bin/bash
# Build script for N4CWENTERM - Net4CPC Terminal
# Requires RASM assembler (www.roudoudou.com/rasm)

# Try to find RASM
if command -v rasm &> /dev/null; then
    RASM=rasm
elif [ -f "../../../Dev/LEISURE/rasm/rasm.exe" ]; then
    RASM="../../../Dev/LEISURE/rasm/rasm.exe"
elif [ -f "../../rasm/rasm.exe" ]; then
    RASM="../../rasm/rasm.exe"
else
    echo "ERROR: RASM assembler not found!"
    echo "Please install RASM or set RASM environment variable"
    exit 1
fi

echo "Building N4CWENTERM..."
echo "Using: $RASM"

# Assemble the character set
$RASM src/charset.s -o CHARSET.BIN
if [ $? -ne 0 ]; then
    echo "Character set build failed!"
    exit 1
fi

# Assemble the main binary
$RASM src/termN4C.s -o EWENN4C.BIN

if [ $? -eq 0 ]; then
    echo ""
    echo "Build successful!"
    echo ""
    echo "Files generated:"
    echo "  - EWENN4C.BIN (terminal binary, $(stat -c%s EWENN4C.BIN) bytes)"
    echo "  - CHARSET.BIN (character set, $(stat -c%s CHARSET.BIN) bytes)"
    echo ""
    echo "Files to copy to your CPC:"
    echo "  1. src/EWEN.BAS"
    echo "  2. EWENN4C.BIN"
    echo "  3. CHARSET.BIN"
    echo ""
    echo "Then on CPC: RUN\"EWEN"
else
    echo "Build failed!"
    exit 1
fi
