#!/bin/bash
# Build script for N4CWENTERM - Net4CPC Terminal
# Requires RASM assembler (www.roudoudou.com/rasm)

# Try to find RASM
if [ -n "$RASM" ]; then
    # RASM environment variable is set
    echo "Using RASM from environment: $RASM"
elif command -v rasm &> /dev/null; then
    # rasm is in PATH
    RASM=rasm
else
    echo "ERROR: RASM assembler not found!"
    echo "Please either:"
    echo "  1. Install RASM and add to PATH, or"
    echo "  2. Set RASM environment variable to rasm executable path"
    echo ""
    echo "Example: export RASM=/path/to/rasm"
    exit 1
fi

echo "Building N4CWENTERM..."
echo "Using: $RASM"

# Create bin directory if it doesn't exist
mkdir -p bin

# Assemble the main binary (now includes charset)
$RASM src/termN4C.s

if [ $? -eq 0 ]; then
    # Move binary to bin directory (RASM SAVE directive outputs to current dir)
    mv EWENN4C.BIN bin/ 2>/dev/null

    echo ""
    echo "Build successful!"
    echo ""
    echo "Files generated in bin/:"
    echo "  - EWENN4C.BIN (combined binary with charset, $(stat -c%s bin/EWENN4C.BIN) bytes)"
    echo ""
    echo "Files to copy to your CPC:"
    echo "  1. src/EWEN.BAS"
    echo "  2. bin/EWENN4C.BIN"
    echo "  3. N4C.CFG (your network configuration)"
    echo ""
    echo "Then on CPC: RUN\"EWEN"
else
    echo "Build failed!"
    exit 1
fi
