# 03: DHCP on MGT-DC01

**Goal:** give every office PC and laptop its network settings automatically, using the addressing plan in `01-planning/network-plan.md`.
**Result:** DHCP authorized in Active Directory, one active scope for client PCs, and gateway, DNS, and domain handed to every client.

---

## 1. Why DHCP runs on the domain controller

For an 80-person company with one IT engineer, running DHCP on the DC is a normal and acceptable choice. In a larger company I would move it to a separate server (or a pair for redundancy). I recorded this as a deliberate decision.

## 2. Install and authorize

```powershell
Install-WindowsFeature DHCP -IncludeManagementTools
Add-DhcpServerInDC -DnsName "mgt-dc01.ad.meridiangulf.test" -IPAddress 10.10.10.10
```

In a domain, a DHCP server will not hand out addresses until it is **authorized** in Active Directory. Authorization is an object in the forest's Configuration partition, so only an Enterprise Admin can create it. This stops a rogue DHCP server (for example, a laptop someone plugs in) from sending staff a fake gateway or DNS server.

## 3. Create the scope

```powershell
Add-DhcpServerv4Scope -Name "Meridian Office" -StartRange 10.10.10.100 -EndRange 10.10.10.199 -SubnetMask 255.255.255.0 -LeaseDuration 8.00:00:00 -State Active
```

The scope covers `10.10.10.100` to `10.10.10.199`. Servers use static addresses outside this range (`.10`, `.11`, and the reserved block up to `.49`), so no exclusions are needed.

## 4. Set the options clients receive

```powershell
Set-DhcpServerv4OptionValue -ScopeId 10.10.10.0 -Router 10.10.10.2 -DnsServer 10.10.10.10 -DnsDomain "ad.meridiangulf.test"
```

The DNS server option matters most: clients must use the domain controller for DNS, or domain sign-in cannot find the domain.

## 5. Verification

```powershell
Get-DhcpServerInDC
Get-DhcpServerv4Scope | Select-Object Name, State, StartRange, EndRange
Get-DhcpServerv4OptionValue -ScopeId 10.10.10.0 | Select-Object Name, Value
```

| Check | Result |
|---|---|
| Authorized server | `mgt-dc01.ad.meridiangulf.test` (10.10.10.10) |
| Scope | Meridian Office, Active, 10.10.10.100 - 10.10.10.199 |
| Router | 10.10.10.2 |
| DNS server | 10.10.10.10 |
| DNS domain | ad.meridiangulf.test |
| Lease | 691200 seconds (8 days) |

📸 `screenshots/19-dhcp-server-authorized.png`, `screenshots/20-dhcp-scope-meridian-office.png`, `screenshots/21-dhcp-scope-options.png`, `screenshots/22-dhcp-console-scope-active.png`

## 6. Settings summary

| Setting | Value | Why |
|---|---|---|
| Scope range | .100 - .199 | 100 addresses for 80 staff, with room for phones and guests |
| Gateway | 10.10.10.2 | VMware NAT gateway, the route to the internet |
| DNS | 10.10.10.10 | The DC, so AD logins work |
| Lease | 8 days | Suits an office where devices stay put; guest Wi-Fi would use hours |

## 7. Still to prove

The configuration is verified, but DHCP is only proven when a client receives a lease. That test happens when the Windows 11 VM (`MGT-PC-001`) is built and shows an address in `10.10.10.100 - 10.10.10.199` with the DC as its DNS server.

---

## Snapshot

`DC01 DHCP configured`
