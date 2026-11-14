# 02: Active Directory and DNS on MGT-DC01

**Goal:** promote MGT-DC01 to the first domain controller of `ad.meridiangulf.test` and make DNS work for the domain and the internet.
**Result:** a healthy single-DC domain, DNS with forward and reverse zones, and a forwarder to 1.1.1.1.

---

## 1. Install the AD DS role

```powershell
Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
```

## 2. Prerequisite I had to fix: local Administrator password

The first promotion attempt failed because the local Administrator password was blank. The local Administrator becomes the domain Administrator, and Windows refuses to create a domain with an empty password.

```powershell
Set-LocalUser -Name "Administrator" -Password (Read-Host -AsSecureString "New Administrator password")
```

## 3. Promote to domain controller

```powershell
Install-ADDSForest -DomainName "ad.meridiangulf.test" -DomainNetbiosName "MERIDIAN" -InstallDns
```

| Setting | Value |
|---|---|
| Domain | ad.meridiangulf.test |
| NetBIOS name | MERIDIAN |
| Domain mode | Windows2025Domain |
| DNS | Installed on the DC |

The server restarted automatically. Expected warnings (DNS delegation cannot be created, because `.test` has no parent zone) were reviewed and are harmless in a lab.

📸 `screenshots/06-ad-domain-created-get-addomain.png`, `screenshots/07-ad-services-running.png`

## 4. DNS fixes after promotion

Windows pointed the DC's DNS client at `127.0.0.1` and `::1`. I reset it to the planned address, added a reverse zone with a PTR record, and added a forwarder.

```powershell
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ResetServerAddresses
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 10.10.10.10
Clear-DnsClientCache
ipconfig /registerdns
Restart-Service Netlogon

Add-DnsServerPrimaryZone -NetworkId "10.10.10.0/24" -ReplicationScope Domain
Add-DnsServerResourceRecordPtr -Name "10" -ZoneName "10.10.10.in-addr.arpa" -PtrDomainName "mgt-dc01.ad.meridiangulf.test"

Add-DnsServerForwarder -IPAddress 1.1.1.1
```

📸 `screenshots/08-dns-nslookup-domain-resolves.png`, `screenshots/09-dns-reverse-zone-nslookup-google.png`, `screenshots/17-dns-manager-zones.png`

## 5. Health verification

| Check | Command | Result |
|---|---|---|
| Services | `Get-Service NTDS, DNS, Netlogon, KDC` | All Running |
| SRV record | `nslookup -type=SRV _ldap._tcp.ad.meridiangulf.test` | Resolves to mgt-dc01, port 389 |
| Shares | `net share` | SYSVOL and NETLOGON present |
| FSMO roles | `netdom query fsmo` | All five on MGT-DC01 |
| Targeted tests | `dcdiag /test:ridmanager /test:advertising /test:services /test:knowsofroleholders` | All passed |
| RID pool | Created and deleted a test user | Succeeded |
| Internet DNS | `nslookup google.com`, `ping google.com` | Resolves and replies |

📸 `screenshots/10-dc01-dcdiag-results.png`, `screenshots/11-dns-srv-record-ldap.png`, `screenshots/12-sysvol-netlogon-shares.png`, `screenshots/13-fsmo-roles-dc01.png`, `screenshots/14-dcdiag-targeted-tests-passed.png`, `screenshots/15-ad-test-user-created.png`, `screenshots/16-no-new-errors-after-restart.png`, `screenshots/18-ad-users-and-computers-dc01.png`

## 6. Issues encountered

Full write-ups are in the knowledge base:

- `06-knowledge-base/KB-001-dcdiag-errors-after-promotion.md`
- `06-knowledge-base/KB-002-nslookup-timeout-unknown-server.md`

---

## Snapshot

`DC01 AD DS and DNS ready`
