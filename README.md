# Meridian Gulf Trading LLC: Hybrid Workplace IT Lab

> One engineer. 80 staff. One Dubai office. A hybrid workforce that expects everything to just work.

**Meridian Gulf Trading LLC** is a fictional trading company based in Dubai, with 80 employees split between the office and remote work. There is no IT department, only one person: me.

This repository documents how I design, build, and run the company's entire IT environment end to end, from the first domain controller to onboarding a new hire, resolving a ticket at 9 AM on a Monday, and proving that a backup actually restores.

---

## Why this project exists

Most IT support portfolios show a single skill in isolation. Real small and mid-sized companies in the UAE need one person who can do all of it:

- Keep staff productive, in the office and at home
- Manage identities, devices, and email securely
- Fix problems quickly and document the fix
- Run a small cloud footprint without a big budget
- Recover when something breaks

This lab is built to show exactly that, and every step is documented so you can follow along or rebuild it yourself.

---

## The company at a glance

| | |
|---|---|
| **Company** | Meridian Gulf Trading LLC (fictional) |
| **Industry** | Trading and distribution |
| **Location** | One office in Dubai, UAE |
| **Staff** | 80 employees, hybrid (office and remote) |
| **IT team** | 1 (me) |
| **Budget** | Lean: free tiers and trial licences wherever possible |

**Departments (simulated):** Management, Sales, Procurement, Logistics, Finance, HR, and Customer Support.

---

## Environment overview

```
                        +----------------------------+
                        |   Microsoft 365 / Entra ID |
                        |   Email, Teams, Intune     |
                        +-------------+--------------+
                                      |
        Remote staff  ----------------+----------------  Office staff
        (managed laptops)             |                  (domain-joined PCs)
                                      |
                        +-------------+--------------+
                        |   On-prem Windows Server   |
                        |   AD DS, DNS, DHCP, GPO    |
                        |   File shares              |
                        +-------------+--------------+
                                      |
                        +-------------+--------------+
                        |   AWS (free tier)          |
                        |   Cloud services, backups, |
                        |   monitoring               |
                        +----------------------------+
```

---

## Lab environment

| | |
|---|---|
| **Host** | Laptop with 16 GB RAM running VMware Workstation |
| **Domain** | `ad.meridiangulf.test` |
| **Lab network** | VMware NAT network `VMnet8` (`10.10.10.0/24`), VMware DHCP turned off so the domain controller can serve DHCP |
| **Domain controller** | `MGT-DC01`, Windows Server 2025, static IP `10.10.10.10` |
| **Clients** | Windows 11 |
| **Current step** | `MGT-DC01` is built and network-tested; next is installing AD DS and DNS and promoting it to a domain controller |

---

## What I build and run

| Area | What it covers |
|---|---|
| **Identity and directory** | Active Directory domain, users, groups, OUs, naming standards, joiner/mover/leaver process |
| **Core network services** | DNS, DHCP, static addressing plan, file shares and permissions |
| **Policy and security** | Group Policy, password and lockout policy, least-privilege access, MFA basics |
| **Microsoft 365** | Tenant setup, licensing, Exchange Online mailboxes, Teams, SharePoint |
| **Device management** | Intune enrolment, compliance and configuration policies, remote device support |
| **Service desk** | Free ticketing system, SLAs, ticket categories, escalation notes |
| **Knowledge base** | Written fixes and how-to guides for common problems |
| **Automation** | PowerShell scripts for onboarding, offboarding, and routine reports |
| **Cloud (AWS)** | Free-tier layer for hosting, backup storage, and monitoring |
| **Backup and recovery** | Scheduled backups and a documented restore test |

---

## Repository structure

```
meridian-gulf-it-lab/
├── README.md
├── 01-planning/          Company profile, network plan, naming standards
├── 02-windows-server/    AD DS, DNS, DHCP, GPO build guides
├── 03-microsoft-365/     Tenant, Entra ID, Exchange Online, Teams
├── 04-intune/            Enrolment, compliance, configuration policies
├── 05-service-desk/      Ticketing setup, SLA, sample tickets
├── 06-knowledge-base/    Troubleshooting articles and how-tos
├── 07-powershell/        Automation scripts with usage notes
├── 08-aws/               Free-tier cloud layer
├── 09-backup-recovery/   Backup design and restore test evidence
├── screenshots/          Evidence for every major step
└── docs/                 Diagrams, runbooks, final project report
```

---

## Build roadmap

Status key: ⬜ not started, 🟨 in progress, ✅ done

| Phase | Focus | Status |
|---|---|---|
| 1 | Company profile, IP plan, naming standards | ✅ |
| 2 | Windows Server: AD DS, DNS, DHCP | 🟨 |
| 3 | Users, groups, OUs, Group Policy, file shares | ⬜ |
| 4 | Microsoft 365 tenant and Entra ID | ⬜ |
| 5 | Intune device enrolment and policies | ⬜ |
| 6 | Service desk and knowledge base | ⬜ |
| 7 | PowerShell automation | ⬜ |
| 8 | AWS free-tier layer | ⬜ |
| 9 | Backup and restore test | ⬜ |
| 10 | Final report and portfolio polish | ⬜ |

---

## Sample scenarios the lab handles

Each of these will be written up as a short case study with steps, screenshots, and the root cause as the lab progresses.

- **New joiner:** a Sales hire starts Monday and needs an account, mailbox, laptop, and access to the right shares.
- **Leaver:** a Finance employee resigns and access must be removed the same day without losing their data.
- **Locked out:** a remote user cannot sign in and has a client meeting in 20 minutes.
- **Slow laptop:** a staff member reports their device is crawling, so I check what is running and what policy applies.
- **Shared folder access:** Procurement cannot open the supplier folder, so I trace the permission chain.
- **Disaster drill:** a file server volume is lost and I restore from backup and document the recovery time.

---

## Skills demonstrated

**Systems:** Windows Server, Active Directory, DNS, DHCP, Group Policy
**Cloud:** Microsoft 365, Entra ID, Intune, AWS (free tier)
**Support:** Ticket handling, SLAs, escalation, user communication, documentation
**Automation:** PowerShell
**Resilience:** Backup design, restore testing, runbooks

---

## How to use this repository

1. Start with `01-planning/` to understand the company and design decisions.
2. Follow the folders in order. Each one has a build guide, the commands used, and screenshots.
3. Read `06-knowledge-base/` and `05-service-desk/` to see how I handle day-to-day support.
4. Check `docs/` for the final report and diagrams.

---

## Notes

- Meridian Gulf Trading LLC is entirely fictional. Any resemblance to a real company is coincidental.
- No real credentials, tenant IDs, or personal data are stored here. Sensitive values are redacted in screenshots and configs.
- The lab is designed to run mostly on free tiers and trial licences.

---

## About me

I'm **Mohamed Faisal**, an IT support and cloud support engineer targeting roles in Dubai and the wider UAE. I built this lab to show how I work: methodically, with clear documentation, and with the whole picture in mind.

My background is in application and cloud support: I worked as an IT & Application Support Engineer on a live mobile marketplace running on AWS (Lambda, API Gateway, DynamoDB, Cognito), troubleshooting through CloudWatch logs, tracking incidents in Jira, and documenting each application flow. This lab extends that into workplace IT: identity, devices, service desk, and recovery.

- GitHub: [mohamedfaisal-dev](https://github.com/mohamedfaisal-dev)
- LinkedIn: [mohamed-faisal-dev](https://linkedin.com/in/mohamed-faisal-dev)
- Email: mohamedfaisal.dev@gmail.com
