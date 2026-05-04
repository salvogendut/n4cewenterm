#!/bin/bash
# Build DNS test program

# Try to find RASM
if command -v rasm &> /dev/null; then
    RASM=rasm
elif [ -f "../../../Dev/LEISURE/rasm/rasm.exe" ]; then
    RASM="../../../Dev/LEISURE/rasm/rasm.exe"
elif [ -f "../../rasm/rasm.exe" ]; then
    RASM="../../rasm/rasm.exe"
else
    echo "ERROR: RASM assembler not found!"
    exit 1
fi

echo "Building DNS Test..."
echo "Using: $RASM"

$RASM src/dnstest.s -o DNSTEST.BIN

if [ $? -eq 0 ]; then
    echo ""
    echo "Build successful!"
    echo "File: DNSTEST.BIN ($(stat -c%s DNSTEST.BIN) bytes)"
    echo ""
    echo "To run on CPC:"
    echo "  LOAD\"DNSTEST.BIN\",&8000"
    echo "  CALL &8000"
else
    echo "Build failed!"
    exit 1
fi
