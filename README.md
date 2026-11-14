# Meridian Gulf Hybrid Workplace IT Lab

> One engineer. 80 staff. One Dubai office. A hybrid workforce that expects everything to just work.

![Status](https://img.shields.io/badge/status-in%20progress-orange)
![Platform](https://img.shields.io/badge/platform-VMware%20%7C%20GNS3%20%7C%20AWS-blue)
![Cost](https://img.shields.io/badge/cost-mostly%20free-green)
![Focus](https://img.shields.io/badge/focus-IT%20Support%20%7C%20Sysadmin%20%7C%20Network%20%7C%20Cloud-lightgrey)

---

## 1. The Scenario

**Meridian Gulf Trading LLC** is a fictional trading company based in Dubai, UAE.

| | |
|---|---|
| **Staff** | 80 employees |
| **Location** | One Dubai head office |
| **Workforce** | Hybrid (office + remote) |
| **IT team** | One person (me) |
| **Mission of IT** | Keep 80 people productive, secure, and supported |

I own the full IT stack: user accounts, laptops, the office network, cloud services, tickets, backups, and documentation. Every task in this repository is something a real IT team in a Gulf company would handle, and every step is documented so someone else could repeat it.

> **Note:** Meridian Gulf Trading LLC is fictional. The domain `ad.meridiangulf.test` uses the reserved `.test` TLD and is not a real domain.

---

## 2. Why This Project Exists

Job descriptions for IT roles in the UAE ask for a mix of skills: Active Directory, Microsoft 365, Intune, networking basics, ticketing, cloud familiarity, and clear documentation. This lab is built to practice and prove all of them in one connected environment, instead of as isolated tutorials.

**What this lab demonstrates:**

- Building and managing a Windows Server domain from scratch
- Managing users, groups, policies, and devices at the scale of an 80-person company
- Designing and troubleshooting a segmented office network
- Running IT support with tickets, SLAs, and a knowledge base
- Using cloud services (Microsoft 365, Entra ID, Intune, AWS) in a hybrid setup
- Automating repetitive work with PowerShell
- Proving that backups actually restore
- Writing documentation that other people can follow

---

## 3. Architecture

### 3.1 Current Build (flat lab network)

```
Host laptop (VMware Workstation)
|
VMnet8 (NAT)  10.10.10.0/24   VMware DHCP: disabled
|
+---------------+----------------+
|                                |
MGT-DC01                    Win11 client(s)
Windows Server 2025          (planned)
10.10.10.10 (static)
AD DS + DNS (+ DHCP planned)
```

### 3.2 Target Design (with the GNS3 network layer)

```
Internet
|
[ NAT / VMnet8 ]
|
[ Router / Firewall ]   <-- OPNsense or VyOS (GNS3)
|
trunk
[ Virtual switch (VLANs) ]  <-- GNS3
|
+-----------+-------+--------+------------+
|           |       |        |
VLAN 10   VLAN 20  VLAN 30  VLAN 99
Servers    Staff   Guest    Management
10.10.10.0/24  10.10.20.0/24  10.10.30.0/24  10.10.99.0/24
MGT-DC01   Win11   Isolated    Network
10.10.10.10 clients  devices   device admin
```

> The VLAN plan is a draft design. `MGT-DC01` stays at `10.10.10.10` inside the Servers VLAN, so the domain controller never needs to be rebuilt when the network layer is added.

### 3.3 Draft Addressing Plan

| VLAN | Name | Subnet | Purpose | DHCP |
|------|------|--------|---------|------|
| 10 | Servers | `10.10.10.0/24` | Domain controller and future servers | Static |
| 20 | Staff | `10.10.20.0/24` | Employee workstations | MGT-DC01 via relay |
| 30 | Guest | `10.10.30.0/24` | Visitor devices, internet only | Router or MGT-DC01 via relay |
| 99 | Management | `10.10.99.0/24` | Network device administration | Static |

---

## 4. Technology Stack

| Area | Tools |
|------|-------|
| Virtualization | VMware Workstation |
| Server OS | Windows Server 2025 |
| Client OS | Windows 11 |
| Identity | Active Directory Domain Services, DNS, DHCP, Group Policy |
| Cloud identity and devices | Microsoft 365, Entra ID, Intune |
| Network emulation | GNS3 (with VMware integration) |
| Router / firewall | OPNsense or VyOS (free, lightweight) |
| Cloud | AWS Free Tier |
| Support process | Free ticketing system + knowledge base |
| Automation | PowerShell |
| Documentation | Markdown, diagrams, screenshots in this repository |

---

## 5. Lab Environment

| Item | Detail |
|------|--------|
| Host | Laptop with 16 GB RAM, ~261 GB free disk at project start |
| Hypervisor | VMware Workstation |
| Budget | Mostly free: free-tier cloud, free software, evaluation ISOs |
| Constraint | 16 GB RAM means only the VMs needed for the current phase run at once |

---

## 6. Project Phases and Status

**Legend:** ✅ Done | 🔄 In progress | ⏳ Planned

| # | Phase | Status |
|---|-------|--------|
| 0 | Planning: company profile, scope, network planning | ✅ |
| 1 | VMware environment and MGT-DC01 build | ✅ |
| 2 | Active Directory DS + DNS | 🟨 |
| 3 | Directory structure: OUs, users, groups, naming standard | 🔄 |
| 4 | DHCP, Group Policy, file shares and permissions | 🔄 |
| 5 | Windows 11 client build and domain join | ⏳ |
| 6 | GNS3 network layer: VLANs, routing, firewall, DHCP relay | ⏳ |
| 7 | Microsoft 365, Entra ID, hybrid identity, Intune | ⏳ |
| 8 | Ticketing system and knowledge base | ⏳ |
| 9 | PowerShell automation | ⏳ |
| 10 | AWS cloud layer | ⏳ |
| 11 | Backup and restore test | ⏳ |
| 12 | Final documentation, diagrams, and portfolio polish | ⏳ |

---

### Phase Details

<details>
<summary><strong>Phase 0: Planning ✅</strong></summary>

- [x] Company profile and scope defined
- [x] Network planning completed
- [x] Hardware limits identified

</details>

<details>
<summary><strong>Phase 1: VMware Environment and MGT-DC01 ✅</strong></summary>

- [x] VMware Workstation installed
- [x] Windows Server 2025 and Windows 11 ISOs downloaded
- [x] Virtualization enabled on host
- [x] VMware DHCP disabled on VMnet8 (`10.10.10.0/24`)
- [x] MGT-DC01 built, renamed, static IP `10.10.10.10`
- [x] Connectivity to gateway and internet verified
- [x] Snapshot baseline taken

</details>

<details>
<summary><strong>Phase 2: Active Directory DS + DNS 🟨</strong></summary>

- [x] AD DS role installed
- [x] MGT-DC01 promoted to a domain controller for `ad.meridiangulf.test`
- [x] Health verified (`dcdiag`, SYSVOL/NETLOGON shares, DNS zones)
- [x] DNS forwarders and reverse lookup zone configured
- [x] Healthy-state snapshot and evidence captured

</details>

<details>
<summary><strong>Phase 3: Directory Structure 🔄</strong></summary>

- [x] OU structure designed around departments
- [ ] ~80 user accounts created (bulk import via PowerShell)
- [x] Security groups and role-based access model
- [ ] Naming standards documented

</details>

<details>
<summary><strong>Phase 4: DHCP, Group Policy, File Shares 🔄</strong></summary>

- [x] DHCP scopes and options
- [ ] Baseline GPOs (password policy, desktop settings, drive mapping)
- [ ] Departmental file shares with NTFS permissions

</details>

<details>
<summary><strong>Phase 5: Windows 11 Client ⏳</strong></summary>

- [ ] Client built and joined to the domain
- [ ] GPO application verified with `gpresult`
- [ ] User logon and profile tested

</details>

<details>
<summary><strong>Phase 6: GNS3 Network Layer ⏳</strong></summary>

See [Section 7](#7-gns3-network-layer) for the full scope and evidence plan.

</details>

<details>
<summary><strong>Phase 7: Microsoft 365, Entra ID, Intune ⏳</strong></summary>

- [ ] Tenant set up with licensed users
- [ ] Identity synchronisation with on-premises AD
- [ ] Intune enrolment, compliance, and configuration policies
- [ ] MFA and conditional access basics

</details>

<details>
<summary><strong>Phase 8: Ticketing and Knowledge Base ⏳</strong></summary>

- [ ] Free ITSM tool deployed
- [ ] Ticket categories, priorities, and SLA targets
- [ ] Sample incident, request, and change tickets worked end to end
- [ ] Knowledge base articles and user guides

</details>

<details>
<summary><strong>Phase 9: PowerShell Automation ⏳</strong></summary>

- [ ] User onboarding and offboarding scripts
- [ ] Bulk operations and reporting scripts
- [ ] Scripts stored with comments and usage notes

</details>

<details>
<summary><strong>Phase 10: AWS Cloud Layer ⏳</strong></summary>

- [ ] Account security baseline (root protection, MFA, IAM user/roles)
- [ ] Basic compute, storage, and monitoring on the free tier
- [ ] Cost control and billing alerts

</details>

<details>
<summary><strong>Phase 11: Backup and Restore Test ⏳</strong></summary>

- [ ] Backup of the domain controller and shared data
- [ ] Simulated failure
- [ ] Documented, successful restore

</details>

<details>
<summary><strong>Phase 12: Final Polish ⏳</strong></summary>

- [ ] Complete diagrams and consistent documentation
- [ ] Troubleshooting log cleaned and indexed
- [ ] Short project walkthrough

</details>

---

## 7. GNS3 Network Layer

**Why GNS3:** Real offices are segmented. Staff, servers, and guests do not share one flat network. GNS3 emulates real network operating systems, so I can build and troubleshoot a realistic office network on one laptop.

**What gets built:**

1. Design the VLAN and IP plan, and draw the topology
2. Install GNS3 and integrate it with VMware so existing VMs (`MGT-DC01`, Windows 11 client) become part of the topology
3. Add a router/firewall (OPNsense or VyOS) and a virtual switch
4. Configure VLANs and inter-VLAN routing
5. Configure DHCP relay so the domain controller serves addresses to every VLAN
6. Enforce guest isolation with firewall rules and prove it with tests
7. *(Stretch goal)* Add a branch site connected to head office with a site-to-site VPN
8. Document configs, diagrams, and a log of real problems found and fixed

**Evidence to capture:**

| Evidence | Description |
|----------|-------------|
| Topology diagram | Exported GNS3 project file and annotated diagram |
| Device configs | Router/firewall and switch configurations |
| Test: DHCP relay | A staff PC gets an address from DC01 across VLANs |
| Test: guest isolation | A guest PC cannot reach the Servers VLAN |
| Test: DNS | DNS resolves correctly across VLANs |
| Troubleshooting log | An entry for every failure encountered and fixed |

**Design decisions:**

- Free, lightweight appliances only (no licensed vendor images) to respect licensing and the 16 GB RAM constraint
- Only the devices needed for the current test are powered on at once

---

## 8. Skills Demonstrated

| Skill Area | Where in This Lab |
|------------|-------------------|
| Windows Server administration | Phases 1–4 |
| Active Directory, DNS, DHCP, Group Policy | Phases 2–4 |
| Endpoint management | Phases 5 and 7 |
| Networking: VLANs, routing, firewall, VPN | Phase 6 |
| Microsoft 365, Entra ID, Intune | Phase 7 |
| Service desk and ITSM process | Phase 8 |
| Scripting and automation | Phase 9 |
| Cloud fundamentals (AWS) | Phase 10 |
| Backup, recovery, operational discipline | Phase 11 |
| Technical documentation | All phases |

---

## 9. Repository Structure

```
meridian-gulf-it-lab/
├── README.md
├── docs/
│   ├── 00-company-profile.md
│   ├── 01-network-design.md
│   ├── 02-active-directory.md
│   ├── 03-group-policy.md
│   ├── 04-gns3-network-layer.md
│   ├── 05-microsoft-365-intune.md
│   ├── 06-ticketing-and-kb.md
│   ├── 07-aws-layer.md
│   └── 08-backup-restore.md
├── diagrams/            # Network and architecture diagrams
├── gns3/                # Project export, device configs, test results
├── scripts/
│   └── powershell/      # Automation scripts
├── kb/                  # Knowledge base articles and user guides
├── runbooks/            # Step-by-step procedures
├── screenshots/         # Evidence, organised by phase
└── troubleshooting-log.md
```

---

## 10. Documentation Standards

- Every phase has a write-up: goal, steps, verification, and result
- Every claim has evidence (screenshot, command output, or test result)
- Every real problem goes in the troubleshooting log as **Symptom → Cause → Fix → Lesson**
- Commands are shown in code blocks so steps can be repeated
- No credentials, tenant IDs, or keys are committed to the repository

---

## 11. Cost

The project is designed to be mostly free:

- VMware Workstation, evaluation Windows ISOs, GNS3, OPNsense/VyOS — free to use
- AWS usage stays inside the free tier, with billing alerts enabled
- Microsoft 365 uses a trial/developer-type tenant

---

## 12. About the Author

**Mohamed Faisal** — IT Support & Application Support Engineer | Windows Server | Networking | AWS

I build and operate IT environments hands-on. I have supported a live mobile marketplace in production on AWS (Lambda, API Gateway, DynamoDB, Cognito), triaging incidents with CloudWatch and Jira and documenting every application flow for the team. This lab extends that experience into the infrastructure side of IT: identity, endpoints, networking, cloud services, and recovery.

| | |
|---|---|
| **Target roles** | IT Support, System Administrator, Network Support, Cloud Support |
| **Background** | IT & Application Support Engineer, Akhlaq Ventures Ltd. (Xenbite) |
| **Education** | B.Sc. Computer Science, Pondicherry University |
| **Languages** | English (professional), Tamil (native) |
| **Location** | Relocating to Dubai, UAE |
| **Availability** | Immediate joiner |

**Connect:**

- 🐙 GitHub: [github.com/mohamedfaisal-dev](https://github.com/mohamedfaisal-dev)
- 💼 LinkedIn: [linkedin.com/in/mohamed-faisal-dev](https://www.linkedin.com/in/mohamed-faisal-dev)
- 📧 Email: [mohamedfaisal.dev@gmail.com](mailto:mohamedfaisal.dev@gmail.com)

---

*Feedback and suggestions on this lab are welcome — open an issue or send me a message.*

*This README is updated as each phase is completed. Statuses above reflect the current state of the build.*
