# 04: OU structure, security groups, and 80 users from CSV

**Goal:** build the directory structure for Meridian Gulf Trading LLC (80 staff, 8 departments) and create every user account with one repeatable script.
**Result:** 16 OUs under `Meridian Gulf`, 8 department security groups, and 80 enabled user accounts, each in the right OU and group.

---

## 1. OU structure

```powershell
$domain = "DC=ad,DC=meridiangulf,DC=test"
New-ADOrganizationalUnit -Name "Meridian Gulf" -Path $domain
$root = "OU=Meridian Gulf,$domain"
"Users","Computers","Groups","Admin Accounts" | ForEach-Object { New-ADOrganizationalUnit -Name $_ -Path $root }

$depts = "Management","Sales","Procurement","Logistics","Finance","HR","Customer Support","IT"
$depts | ForEach-Object { New-ADOrganizationalUnit -Name $_ -Path "OU=Users,$root" }
"Workstations","Laptops","Servers" | ForEach-Object { New-ADOrganizationalUnit -Name $_ -Path "OU=Computers,$root" }
```

OUs exist so I can **delegate control** (for example, HR help-desk rights over HR users only) and **apply Group Policy** per department.

📸 `screenshots/23-ad-ou-structure-powershell.png`, `screenshots/24-ad-ou-tree-in-console.png`

## 2. Department security groups

```powershell
$depts | ForEach-Object { New-ADGroup -Name ("GG-" + ($_ -replace ' ','-')) -GroupScope Global -GroupCategory Security -Path "OU=Groups,$root" -Description "$_ department staff" }
```

Permissions are given to groups, never to individuals. When someone changes department, only their group membership changes.

📸 `screenshots/25-ad-security-groups.png`

## 3. Bulk user creation

Script: `07-powershell/create-users-from-csv.ps1` (v1.1). Data: `07-powershell/users.csv` (80 rows: FirstName, LastName, Department, Title).

What the script does:

- Builds the username as `first.last` in lower case (hyphens removed) and rejects names over 20 characters
- Checks that the department OU exists
- Skips accounts that already exist, so it is safe to re-run
- Creates the account with department, title, company, and office filled in, forces a password change at first sign-in, and adds the user to `GG-<Department>`
- Asks for the initial password at run time, so no password is stored in the script, the CSV, or the repository
- Writes a timestamped log to `C:\LabScripts\logs`
- Supports `-WhatIf` for a dry run

| Step | Command | Result |
|---|---|---|
| Check the data | `Import-Csv users.csv \| Group-Object Department` | 8 departments, counts match the plan |
| Dry run | `.\create-users-from-csv.ps1 -CsvPath ... -WhatIf` | 80 "would create" lines, nothing changed |
| First real run | `.\create-users-from-csv.ps1 -CsvPath ...` | 78 created, 2 failed (see below) |
| Fixed run | same command, safer password | 2 created, 78 skipped |

📸 `screenshots/26-users-csv-department-counts.png`, `screenshots/27-users-dry-run-whatif.png`, `screenshots/28-users-created-with-2-password-failures.png`, `screenshots/28b-users-rerun-after-orphan-cleanup.png`

## 4. Issue encountered: two users failed, and a re-run hid the damage

Two accounts failed with "The password does not meet the length, complexity, or history requirement of the domain". Full write-up: `06-knowledge-base/KB-003-bulk-user-creation-password-rejected.md`.

In short: the shared initial password contained part of the name "Faisal", which AD's complexity rule rejects. The failed creations left **disabled, half-built accounts**, and my first re-run skipped them as "already existing" and reported zero failures. A verification query found them. I removed them, updated the script to v1.1 (clean-up after failure, warning on disabled accounts), and recreated them.

## 5. Verification

```powershell
$base = "OU=Users,OU=Meridian Gulf,DC=ad,DC=meridiangulf,DC=test"
(Get-ADUser -Filter * -SearchBase $base).Count
Get-ADUser -Filter * -SearchBase $base -Properties Department | Group-Object Department | Sort-Object Name | Select-Object Name, Count
Get-ADGroup -Filter "Name -like 'GG-*'" | ForEach-Object { [pscustomobject]@{ Group = $_.Name; Members = @(Get-ADGroupMember $_).Count } } | Format-Table -AutoSize
```

| Department | Users | Group members |
|---|---|---|
| Customer Support | 15 | 15 |
| Finance | 8 | 8 |
| HR | 4 | 4 |
| IT | 1 | 1 |
| Logistics | 17 | 17 |
| Management | 5 | 5 |
| Procurement | 10 | 10 |
| Sales | 20 | 20 |
| **Total** | **80** | **80** |

A final re-run reports every account as skipped with zero warnings and zero failures.

📸 `screenshots/29-users-verification-counts.png`, `screenshots/30-ad-sales-ou-users.png`, `screenshots/31-users-rerun-all-skipped.png`

---

## Snapshot

`DC01 users and groups populated`
