# KB-001: dcdiag reports errors after domain controller promotion

**Category:** Active Directory
**Environment:** Windows Server 2025, single DC (`MGT-DC01`), VMware Workstation

---

## Symptom

Right after promoting a server to a domain controller, `dcdiag /q` failed two tests: `DFSREvent` and `SystemLog`. The event log showed these errors:

| Event ID | Message (summary) |
|---|---|
| 0x704 | Secure Boot update failed, because Secure Boot is not enabled |
| 0x168E | Dynamic registration of the `_ldap._tcp` DNS record failed |
| 0x4102 | Account-identifier allocator unable to assign a new identifier |

## Cause

`DFSREvent` and `SystemLog` fail on **any** error event in the last 24 hours, so they report noise as well as real faults. Each event was classified separately:

- **0x704:** Windows tried to update Secure Boot certificates, but Secure Boot is off in this VM. Harmless.
- **0x168E:** in the first minutes after promotion the DC's DNS client pointed at `::1`, so it could not register its service records. A timing problem, not a permanent fault.
- **0x4102:** the RID pool, which allocates unique IDs to new accounts, was not ready immediately after promotion. A first-boot condition.

## Resolution

1. Corrected the DC's DNS client address to `10.10.10.10`.
2. Re-published the DC's DNS records:
   ```powershell
   nltest /dsregdns
   ```
3. Restarted the server and waited about five minutes.

## Verification

```powershell
nslookup -type=SRV _ldap._tcp.ad.meridiangulf.test      # resolves to mgt-dc01, port 389
net share                                               # SYSVOL and NETLOGON present
netdom query fsmo                                       # all five roles on MGT-DC01
dcdiag /test:ridmanager /test:advertising /test:services /test:knowsofroleholders   # all passed
New-ADUser -Name "Test User" -SamAccountName "test.user" ...   # created successfully (RID pool works)
Get-WinEvent -FilterHashtable @{LogName='System','Directory Service'; Level=2; StartTime=(Get-Date).AddMinutes(-30)}   # no new errors
```

Old events remain in the log for 24 hours, so `SystemLog` may keep reporting them. What matters is that nothing **new** appears after the restart.

## Prevention

- Set the DC's static IP and DNS before promotion, and confirm DNS after the first restart.
- Run the targeted `dcdiag` tests and a record lookup instead of relying on the full `dcdiag /q` result immediately after promotion.

📸 `screenshots/10-dc01-dcdiag-results.png`, `screenshots/14-dcdiag-targeted-tests-passed.png`, `screenshots/16-no-new-errors-after-restart.png`
