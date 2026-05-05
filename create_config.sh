#!/bin/bash
# Helper script to create N4C.CFG with proper CPC-compatible line endings

if [ -f N4C.CFG ]; then
    echo "WARNING: N4C.CFG already exists!"
    read -p "Overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

echo "Creating N4C.CFG with default settings..."
echo ""
echo "Enter your network configuration:"
echo "(Press ENTER to use default values shown in brackets)"
echo ""

read -p "IP Address [192.168.1.100]: " IP
IP=${IP:-192.168.1.100}

read -p "Netmask [255.255.255.0]: " NETMASK
NETMASK=${NETMASK:-255.255.255.0}

read -p "Gateway [192.168.1.1]: " GATEWAY
GATEWAY=${GATEWAY:-192.168.1.1}

read -p "DNS Server [192.168.1.1]: " DNS
DNS=${DNS:-192.168.1.1}

# Create file with Unix line endings first
cat > N4C.CFG << CFGEOF
$IP
$NETMASK
$GATEWAY
$DNS
CFGEOF

# Convert to DOS/CPC format (CR+LF)
if command -v unix2dos &> /dev/null; then
    unix2dos N4C.CFG 2>/dev/null
else
    # Fallback: use perl
    perl -pi -e 's/\n/\r\n/' N4C.CFG 2>/dev/null || {
        # Last resort: use sed
        sed -i 's/$/\r/' N4C.CFG
    }
fi

echo ""
echo "N4C.CFG created successfully!"
echo ""
echo "Configuration:"
echo "  IP Address: $IP"
echo "  Netmask:    $NETMASK"
echo "  Gateway:    $GATEWAY"
echo "  DNS Server: $DNS"
echo ""
echo "File has DOS-style line endings (CR+LF) for CPC compatibility."
echo "Copy this file to your CPC disk along with the binaries."
