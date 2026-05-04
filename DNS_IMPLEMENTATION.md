# DNS Resolution Implementation for N4CWENTERM

## Overview
DNS resolution is now fully implemented for the N4C Telnet client, allowing you to connect using hostnames like `bbs.example.com:23` instead of just IP addresses.

## Components

### 1. Hardware Initialization (EWEN.BAS)
The BASIC loader now properly configures the W5100S chip with all necessary parameters:

- **Mode Register** (0xFD20): Set to 3 (auto-increment + indirect bus mode)
- **MAC Address** (0x0009-0x000E): DE:AD:BE:EF:00:FF
- **IP Address** (0x000F-0x0012): 192.168.68.254
- **Subnet Mask** (0x0005-0x0008): 255.255.255.0
- **Gateway** (0x0001-0x0004): 192.168.68.1
- **Retry Timeout** (0x0017-0x0018): 10000 (1 second in 100µs units)
- **Retry Count** (0x0019): 10 retries
- **DNS Server IP** (0x0032-0x0035): 192.168.68.54

### 2. W5100S Socket Layer (w5100.s)
Provides the low-level KCNet-compatible socket API:

#### TCP Functions (Socket 0):
- `NET_SOCKET` - Initialize TCP socket
- `NET_CONNECT` - Connect to remote host
- `NET_SEND` - Send data over TCP
- `NET_RECV` - Receive data from TCP
- `NET_CLOSE` - Close TCP connection
- `CHECK_CONNECTION` - Check connection status

#### UDP Functions (Socket 1):
- `SOCKET` - Create socket (TCP or UDP)
- `CONNECT` - Bind socket
- `CLOSE` - Close socket
- `SENDTO` - Send UDP datagram
- `RECVFR` - Receive UDP datagram
- `SELECT` - Check for available data

#### Helper Functions:
- `N_TIME` - Read timer value (CPC frame counter)
- `N_WIPA` / `N_RIPA` - Write/Read IP address storage (DNS IP at 0x0032)
- `N_DPRT` - Get dynamic port number (49152-65535 range)
- `NTOHS` / `HTONS` - Network/host byte order conversion (16-bit)
- `NTOHL` - Network to host byte order (32-bit)
- `I_NTOA` - Convert IP address to dotted decimal string

### 3. DNS Client (dnsc-11.s)
Complete DNS resolver implementation based on KCNet:

#### Main Functions:
- `GHBNAM` - Get Host By Name (main entry point)
  - Resolves hostname to IP address
  - Implements 3 retries with exponential backoff
  - Returns IP address in binary format
  - Error codes: 1-15 (server), 16-25 (client)

#### Internal Functions:
- `DQUERY` - DNS Query handler
- `MKQUER` - Build DNS query message
- `PRSQUE` - Parse question section
- `PRSANS` - Parse answer section
- `PRSNAM` - Parse DNS names (handles compression)

### 4. User Interface (urlmenu_n4c.s)
Hostname/IP input handler:

- Accepts input in formats:
  - `192.168.1.1` (IP only, uses port 23)
  - `192.168.1.1:8023` (IP with custom port)
  - `bbs.example.com` (hostname, uses port 23)
  - `bbs.example.com:8023` (hostname with custom port)
- Auto-detects numeric vs. hostname input
- Calls DNS resolver for non-numeric input
- Displays resolved IP before connecting
- Shows error codes on DNS failure

## How It Works

1. **User Input**: User enters hostname or IP at the "Server IP or hostname:" prompt
2. **Detection**: Code checks if input is numeric (IP) or contains letters (hostname)
3. **DNS Resolution** (if hostname):
   - Allocates 534-byte message buffer
   - Calls `GHBNAM(dns_msgbuf, lookup_name)`
   - `GHBNAM` calls `DQUERY` which:
     - Opens UDP socket (Socket 1)
     - Builds DNS query with `MKQUER`
     - Sends query to DNS server (192.168.68.54:53)
     - Waits for response (with timeout)
     - Parses response to extract IP address
     - Closes UDP socket
   - Resolved IP is copied to `ip_addr`
4. **Port Parsing**: Code checks for `:port` suffix
5. **Connection**: TCP connection established using resolved IP

## DNS Message Format

### Query Message Structure (sent to DNS server):
```
+6 bytes: Peer data (DNS IP + port)
+12 bytes: DNS header
  - 2 bytes: Message ID (dynamic port number)
  - 1 byte: Flags 0 (RD bit set for recursion)
  - 1 byte: Flags 1
  - 2 bytes: Question count (1)
  - 2 bytes: Answer count (0)
  - 2 bytes: Authority count (0)
  - 2 bytes: Additional count (0)
+Variable: Question section
  - Domain name (label format: length + chars, terminated by 0)
  - 2 bytes: QTYPE (TYPE_A = 1 for IPv4 address)
  - 2 bytes: QCLASS (CLASS_IN = 1 for Internet)
```

### Response Message (from DNS server):
```
+22 bytes: Header + peer data
+Variable: Response message
  - Header (same structure as query)
  - Question section (echoed from query)
  - Answer section:
    - Name (may use compression pointers)
    - Type, Class, TTL, RDLENGTH
    - RDATA (4 bytes for TYPE_A)
```

## Error Codes

| Code | Type   | Meaning |
|------|--------|---------|
| 1    | Server | Format error |
| 2    | Server | Server failure |
| 3    | Server | Name error (domain doesn't exist) |
| 4    | Server | Not implemented |
| 5    | Server | Refused |
| 16   | Client | SOCKET function error |
| 17   | Client | CONNECT function error |
| 18   | Client | NAME ERROR (invalid domain format) |
| 19   | Client | SENDTO function error |
| 20   | Client | TIMEOUT (no response from DNS server) |
| 21   | Client | QR=0 (response bit not set) |
| 22/150 | Client | PARSE QUESTION error |
| 23/151 | Client | NO ANSWER |
| 24/152 | Client | PARSE ANSWER error |

## Testing

### Prerequisites:
1. Net4CPC hardware properly connected
2. DNS server running at 192.168.68.54
3. Network accessible from CPC

### Test Procedure:
1. Load program: `RUN"EWEN`
2. Wait for "Type |TERM to start terminal mode"
3. Run: `|TERM`
4. At "Server IP or hostname:" prompt:
   - Test IP: `192.168.68.1:23`
   - Test hostname: `bbs.example.com:23`
5. Watch for "Resolving: ..." message
6. Verify "Resolved to: x.x.x.x" appears
7. Connection should proceed normally

### Debugging:
- Debug messages show the resolution process
- Error codes displayed on failure
- Check DNS server logs for query reception
- Verify W5100S chip initialization in EWEN.BAS

## Memory Usage

- DNS message buffer: 534 bytes
- Hostname buffer: 256 bytes
- Input buffer: 128 bytes
- Socket 0: TCP (telnet connection)
- Socket 1: UDP (DNS queries)

## Build

```bash
./build.sh
```

Generates:
- `EWENN4C.BIN` - Main terminal binary (~11.7 KB)
- `CHARSET.BIN` - Character set (2 KB)

## Files to Transfer to CPC

1. `src/EWEN.BAS` - Loader
2. `EWENN4C.BIN` - Terminal binary
3. `CHARSET.BIN` - Character set

## Known Limitations

- IPv4 only (TYPE_A records)
- Single DNS server (no fallback)
- No DNS caching
- Maximum hostname length: 255 characters
- Maximum label length: 63 characters
- 3 retries with fixed timeout (750ms initial)
