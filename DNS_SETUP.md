# DNS Configuration for N4CWENTERM

## Default Configuration

**DNS is automatically configured!** The BASIC loader (`EWEN.BAS`) automatically sets Google DNS (8.8.8.8) when you run it. This works for most users and no additional configuration is needed.

If you want to use a different DNS server, see the methods below.

## Method 1: Using NCFG.COM (Recommended)

1. Boot CP/M on your CPC
2. Run `NCFG.COM`
3. Follow the prompts to set:
   - Your IP address
   - Subnet mask
   - Gateway
   - **DNS Server IP** (e.g., 8.8.8.8 or your local DNS server)
4. Save the configuration

## Method 2: Edit EWEN.BAS (Easy)

You can edit `EWEN.BAS` to use a different DNS server. Change lines 170-200:

```basic
170 OUT &FD21,0:OUT &FD22,&32:OUT &FD23,8:REM First octet
180 OUT &FD21,0:OUT &FD22,&33:OUT &FD23,8:REM Second octet
190 OUT &FD21,0:OUT &FD22,&34:OUT &FD23,8:REM Third octet
200 OUT &FD21,0:OUT &FD22,&35:OUT &FD23,8:REM Fourth octet
```

For example, to use Cloudflare DNS (1.1.1.1):
```basic
170 OUT &FD21,0:OUT &FD22,&32:OUT &FD23,1:REM First octet
180 OUT &FD21,0:OUT &FD22,&33:OUT &FD23,1:REM Second octet
190 OUT &FD21,0:OUT &FD22,&34:OUT &FD23,1:REM Third octet
200 OUT &FD21,0:OUT &FD22,&35:OUT &FD23,1:REM Fourth octet
```

## Method 3: Manual Configuration (Advanced)

If you want to configure DNS separately without modifying EWEN.BAS, you can run this before loading the terminal:

```basic
10 REM Configure DNS Server IP
20 REM Set DNS IP to your preferred server
30 OUT &FD21, 0 : OUT &FD22, &32 : OUT &FD23, 8
40 OUT &FD21, 0 : OUT &FD22, &33 : OUT &FD23, 8
50 OUT &FD21, 0 : OUT &FD22, &34 : OUT &FD23, 4
60 OUT &FD21, 0 : OUT &FD22, &35 : OUT &FD23, 4
70 PRINT "DNS server set to 8.8.4.4"
80 RUN"EWEN
```

## Common DNS Servers

- **Google DNS**: 8.8.8.8 or 8.8.4.4
- **Cloudflare DNS**: 1.1.1.1 or 1.0.0.1
- **OpenDNS**: 208.67.222.222 or 208.67.220.220
- **Your Router**: Usually 192.168.1.1 or 192.168.0.1

## Testing DNS

Once configured, you can test DNS resolution in N4CWENTERM:

```
|TERM

Input server name or IP (:PORT or default to 23):
telehack.com:23

Resolving: telehack.com... OK
Connecting to IP 206.125.69.232 port 23
Connected.
```

## Troubleshooting

### "DNS lookup failed"

1. Check your DNS server IP is correctly configured
2. Verify network connectivity:
   - Under CP/M, try `PING.COM 8.8.8.8`
   - Ensure gateway is configured correctly
3. Try a different DNS server
4. Check firewall settings (port 53 UDP must be allowed)

### "No Net4CPC found"

- Verify Net4CPC hardware is properly connected
- Check W5100S is at I/O address 0xFD20
- Run NCFG.COM to initialize the hardware

### DNS times out

- Your DNS server may be unreachable
- Try using your local router's IP as DNS server
- Network/firewall may be blocking DNS queries

## How DNS Works in N4CWENTERM

1. You enter a domain name (e.g., `sdf.org:23`)
2. N4CWENTERM detects it's not an IP address
3. Opens UDP socket 1 for DNS query
4. Sends DNS query to configured DNS server (port 53)
5. Receives response with IP address
6. Uses that IP for TCP connection on socket 0
7. Closes DNS socket

The DNS client uses the KCNet DNS protocol implementation (RFC 1034) with UDP transport.

## Storage Location

DNS server IP is stored in W5100S RAM at address 0x0032-0x0035 (PPPoE Destination Hardware Address register, which is repurposed for DNS storage when PPPoE is not in use).

This location persists as long as the W5100S chip is powered on.
