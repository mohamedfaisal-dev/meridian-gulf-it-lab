# 01: VMware lab network and MGT-DC01 build

**Goal:** build the isolated lab network from the plan in `01-planning/network-plan.md` and install the first server, MGT-DC01.
**Result:** a Windows Server 2025 VM named `MGT-DC01` with the static address `10.10.10.10`, internet access through NAT, and VMware's own DHCP turned off.

---

## 1. VMware network (VMnet8, NAT)

| Setting | Value |
|---|---|
| Subnet | 10.10.10.0 / 255.255.255.0 |
| Gateway (NAT) | 10.10.10.2 |
| VMware local DHCP | **Disabled** |

I disabled VMware's DHCP because the domain controller will provide DHCP for the lab. Two DHCP servers on one network hand clients conflicting settings.

📸 `screenshots/01-vmware-network-editor-vmnet8-dhcp-off.png`

## 2. Virtual machine

| Setting | Value |
|---|---|
| Name | MGT-DC01 |
| OS | Windows Server 2025 Standard Evaluation (Desktop Experience) |
| CPU / RAM | 2 vCPU / 4 GB |
| Disk | 60 GB, thin provisioned |
| Network | NAT |
| Firmware | UEFI |

📸 `screenshots/02-dc01-vm-summary.png`, `screenshots/03-server-manager-first-login.png`

I installed VMware Tools and took a snapshot (`Clean Server 2025 install`) before changing anything.

## 3. Proving VMware DHCP is off

After disabling DHCP, the VM showed a `169.254.x.x` address. That is correct: the VM asked for an address and nobody answered.

📸 `screenshots/04-dc01-dhcp-off-apipa-169-254.png`

## 4. Rename, static IP, time zone

```powershell
Rename-Computer -NewName "MGT-DC01" -Restart

Set-NetIPInterface -InterfaceAlias "Ethernet0" -Dhcp Disabled
New-NetIPAddress -InterfaceAlias "Ethernet0" -IPAddress 10.10.10.10 -PrefixLength 24 -DefaultGateway 10.10.10.2
Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 10.10.10.10
Set-TimeZone -Id "Arabian Standard Time"
```

Servers use static addresses, and a domain controller uses its own address as DNS. Time zone is set to Dubai because Kerberos fails if clocks drift more than five minutes.

## 5. Verification

- `ipconfig /all`: host `MGT-DC01`, IPv4 `10.10.10.10`, mask `255.255.255.0`, gateway `10.10.10.2`, DNS `10.10.10.10`, DHCP disabled
- `ping 10.10.10.2`: 0% loss
- `ping 1.1.1.1`: 0% loss (internet reachable through NAT)

📸 `screenshots/05-dc01-static-ip-config.png`

## 6. Issue encountered: VMware DHCP still active

**Symptom:** the VM received `10.10.10.128` with the DNS suffix `localdomain`.
**Cause:** the "Use local DHCP service" option in the Virtual Network Editor was still enabled.
**Fix:** unticked the option, applied, then released and renewed the lease. `ipconfig /renew` failed with "unable to contact your DHCP server", which confirmed the fix.

---

## Snapshot

`DC01 named and static IP`
