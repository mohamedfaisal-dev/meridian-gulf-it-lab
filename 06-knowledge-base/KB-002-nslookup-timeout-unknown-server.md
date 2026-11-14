# KB-002: nslookup times out and shows "Server: UnKnown"

**Category:** DNS
**Environment:** Windows Server 2025 domain controller running its own DNS

---

## Symptom

On the domain controller, `nslookup ad.meridiangulf.test` printed "DNS request timed out", `Server: UnKnown`, and `Address: ::1`, even though the DNS service was running. When pointed at the server directly, the name resolved correctly:

```powershell
nslookup ad.meridiangulf.test 10.10.10.10     # returned 10.10.10.10 after a timeout line
```

## Cause

Two separate things were happening:

1. **DNS client pointed at loopback.** After promotion, Windows set the DC's DNS client to `127.0.0.1` and `::1`. `nslookup` asked the IPv6 address first and got no answer.
2. **No reverse lookup zone.** Before showing an answer, `nslookup` tries to turn the server's IP address into a name. Without a reverse zone and PTR record, that lookup times out and the server name shows as `UnKnown`.

The DNS server itself was healthy.

## Resolution

```powershell
# Fix the client DNS setting
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ResetServerAddresses
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 10.10.10.10
Clear-DnsClientCache
ipconfig /registerdns
Restart-Service Netlogon

# Create the reverse zone and the PTR record for the DC
Add-DnsServerPrimaryZone -NetworkId "10.10.10.0/24" -ReplicationScope Domain
Add-DnsServerResourceRecordPtr -Name "10" -ZoneName "10.10.10.in-addr.arpa" -PtrDomainName "mgt-dc01.ad.meridiangulf.test"
```

## Verification

`nslookup google.com` now showed `Server: mgt-dc01.ad.meridiangulf.test` and `Address: 10.10.10.10` with no timeout, and the domain name resolved.

## Prevention

- Create the reverse lookup zone when building DNS, not afterwards.
- A quick way to separate "server is down" from "client is misconfigured": query the server explicitly (`nslookup name <server-ip>`). If that works, look at the client's DNS settings.

📸 `screenshots/08-dns-nslookup-domain-resolves.png`, `screenshots/09-dns-reverse-zone-nslookup-google.png`
