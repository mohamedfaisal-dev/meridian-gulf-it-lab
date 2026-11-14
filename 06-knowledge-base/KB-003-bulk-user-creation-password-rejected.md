# KB-003: Bulk user creation fails for some users with "password does not meet requirements"

**Category:** Active Directory, PowerShell automation
**Environment:** Windows Server 2025 domain controller, `create-users-from-csv.ps1`

---

## Symptom

A script that creates 80 users with one shared initial password succeeded for 78 and failed for two:

```
[ERROR] FAILED for 'Faisal Qureshi' (faisal.qureshi): The password does not meet the length,
        complexity, or history requirement of the domain.
[ERROR] FAILED for 'Mohamed Faisal' (mohamed.faisal): The password does not meet the length,
        complexity, or history requirement of the domain.
```

The same password worked for every other user.

A second symptom made it worse: re-running the script reported **Skipped: 80, Failed: 0**, which looked like success.

## Cause

**1. The password rule that depends on the user.** Active Directory's complexity rule rejects a password that contains the user's account name, or three or more consecutive characters of any part of their display name. The two failing users both had "Faisal" in their name, and the shared password contained a piece of it. It was valid for everyone else.

**2. A failed creation leaves a half-built account.** When AD rejects the password, the account object has already been created. It stays in the OU as a **disabled** account with no password, and the script never reached the step that adds it to its group.

**3. The re-run hid it.** The script treated "account exists" as "account is correct", so the next run skipped both users and reported no failures.

## Diagnosis

```powershell
"faisal.qureshi","mohamed.faisal" | ForEach-Object { Get-ADUser -Identity $_ -Properties Enabled, PasswordLastSet, MemberOf } |
    Select-Object Name, Enabled, PasswordLastSet, @{n='Groups';e={$_.MemberOf.Count}} | Format-Table -AutoSize
```

Both accounts showed `Enabled : False`, no password set, and zero group memberships. The department user counts were still correct, because the broken accounts sat in the right OUs, so the total of 80 did not reveal the problem. Group member counts did.

## Resolution

1. Removed the two incomplete accounts:
   ```powershell
   Remove-ADUser -Identity faisal.qureshi -Confirm:$false
   Remove-ADUser -Identity mohamed.faisal -Confirm:$false
   ```
2. Updated the script to **v1.1**:
   - removes a half-created account when a creation fails
   - logs a warning for existing accounts that are disabled, instead of counting them as fine
   - prints a hint when the error is about the password
3. Re-ran the script with an initial password that contains no part of either name. It created the two users and skipped the other 78.

## Verification

- Both users show `Enabled : True`
- 80 users under `OU=Users,OU=Meridian Gulf`
- Group member counts match the CSV (Sales 20, IT 1, and so on). Use `@(Get-ADGroupMember $_).Count`: a group with exactly one member returns a single object, and `.Count` on that object does not return 1.
- A final run shows `Skipped: 80 | Warnings: 0 | Failed: 0`

## Prevention

- For real onboarding, generate a **unique random temporary password per user**, deliver it securely, and force a change at first sign-in. A single shared password is only acceptable in a lab.
- Verify the **state** after a bulk run (enabled accounts, group membership), not just the script's summary.
- Make "already exists" checks look at whether the existing account is actually complete.
