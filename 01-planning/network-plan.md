# Meridian Gulf Trading LLC: Network and Directory Plan

**Author:** Mohamed Faisal (IT Engineer)
**Document purpose:** Design decisions made *before* building, so the environment is consistent and easy to support.

---

## 1. Company summary

Meridian Gulf Trading LLC is a trading company with **80 employees**, **one office in Dubai**, and a **hybrid workforce**. IT is run by one engineer. The environment combines on-premises Windows Server services with Microsoft 365 and a small AWS footprint.

---

## 2. Host hardware and VM sizing

The lab runs in VMware Workstation on a single laptop.

| Item | Value |
|---|---|
| Host RAM | **[fill in] GB** |
| Free disk space | **[fill in] GB** |
| Virtualisation software | VMware Workstation |

| VM | Role | vCPU | RAM | Disk |
|---|---|---|---|---|
| MGT-DC01 | Domain controller: Active Directory, DNS, DHCP | 2 | 4 GB | 60 GB (thin) |
| MGT-PC-001 | Windows 11 office client | 2 | 4 GB | 60 GB (thin) |
| MGT-FS01 | File server (added later, if RAM allows) | 2 | 2-4 GB | 60 GB (thin) |

---

## 3. Domain and naming standard

| Item | Decision | Reason |
|---|---|---|
| AD domain | `ad.meridiangulf.test` | `.test` is reserved for testing and cannot clash with the internet |
| NetBIOS name | `MERIDIAN` | Short name used at login |
| Avoided | `.local` | Conflicts with mDNS and causes DNS problems |

| Object | Format | Example |
|---|---|---|
| Servers | `MGT-<role><nn>` | `MGT-DC01`, `MGT-FS01` |
| Office PCs | `MGT-PC-<nnn>` | `MGT-PC-001` |
| Laptops | `MGT-LT-<nnn>` | `MGT-LT-001` |
| Standard users | `first.last` | `sara.khan` |
| Admin accounts | `adm.<name>` | `adm.faisal` |

**Admin account rule:** administrators use a separate `adm.` account for admin tasks and a normal account for email and browsing. This limits the damage if a normal account is compromised.

---

## 4. IP addressing

**Network:** `10.10.10.0/24` (mask `255.255.255.0`)

| Address | Used for | Type |
|---|---|---|
| 10.10.10.1 | VMware host adapter | Reserved |
| 10.10.10.2 | VMware NAT gateway (internet access) | Reserved |
| 10.10.10.10 | MGT-DC01 | Static |
| 10.10.10.11 | MGT-FS01 | Static |
| 10.10.10.12 - .49 | Future servers | Static range |
| 10.10.10.100 - .199 | Client PCs | DHCP scope |
| 10.10.10.254 | Spare | Reserved |

**Rules:**
- Servers use static IP addresses. Clients use DHCP.
- Clients use the domain controller as their DNS server.
- The domain controller forwards external DNS queries to a public resolver (1.1.1.1).

---

## 5. DHCP and DNS design

| Setting | Value |
|---|---|
| DHCP server | MGT-DC01 |
| Scope name | Meridian Office |
| Range | 10.10.10.100 - 10.10.10.199 |
| Subnet mask | 255.255.255.0 |
| Default gateway | 10.10.10.2 |
| DNS server given to clients | 10.10.10.10 |
| DNS domain given to clients | ad.meridiangulf.test |
| Lease duration | 8 days |
| DNS forwarder | 1.1.1.1 |

---

## 6. VMware network settings

| Setting | Value |
|---|---|
| Network type | NAT (VMnet8) |
| Subnet | 10.10.10.0 / 255.255.255.0 |
| Gateway | 10.10.10.2 |
| VMware built-in DHCP | **Disabled** (Windows Server provides DHCP) |

**Why NAT:** VMs can reach the internet for Windows Update and Microsoft 365 while staying isolated from the home network.
**Why disable VMware DHCP:** two DHCP servers on one network cause clients to receive wrong settings.

---

## 7. Staff and directory structure

| Department | Users |
|---|---|
| Management | 5 |
| Sales | 20 |
| Procurement | 10 |
| Logistics | 17 |
| Finance | 8 |
| HR | 4 |
| Customer Support | 15 |
| IT | 1 |
| **Total** | **80** |

### Organisational Unit (OU) layout

```
ad.meridiangulf.test
└── Meridian Gulf
    ├── Users
    │   ├── Management
    │   ├── Sales
    │   ├── Procurement
    │   ├── Logistics
    │   ├── Finance
    │   ├── HR
    │   ├── Customer Support
    │   └── IT
    ├── Computers
    │   ├── Workstations
    │   ├── Laptops
    │   └── Servers
    ├── Groups
    └── Admin Accounts
```

### Security groups

One global security group per department, named `GG-<Department>` (for example `GG-Sales`, `GG-Finance`).
Permissions on shared folders are granted to **groups**, never to individual users. When someone changes department, only their group membership changes.

---

## 8. Network diagram

![Network diagram](../docs/network-diagram.png)

---

## 9. Build order

1. Configure the VMware network (NAT, DHCP off)
2. Build MGT-DC01 and set its static IP
3. Install Active Directory and DNS, create the domain
4. Configure DHCP
5. Create OUs, groups, and users
6. Join MGT-PC-001 to the domain
7. Apply Group Policy and create file shares
