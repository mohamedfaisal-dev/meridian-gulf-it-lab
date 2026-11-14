<#
.SYNOPSIS
    Creates Meridian Gulf Trading LLC user accounts in Active Directory from a CSV file.

.DESCRIPTION
    For every row in the CSV the script:
      1. builds the username (first.last, lower case) and UPN
      2. checks the department OU exists
      3. skips the user if the account already exists (safe to re-run)
      4. creates the account in OU=<Department>,OU=Users,OU=Meridian Gulf
      5. adds the user to the matching department group (GG-<Department>)
    Everything is written to a log file. The initial password is asked for when the
    script starts, so it is never stored in the script, the CSV, or GitHub.
    New users must change the password at first sign-in.

.PARAMETER CsvPath
    Path to the CSV. Required columns: FirstName, LastName, Department, Title

.PARAMETER LogFolder
    Folder for the log file. Default: C:\LabScripts\logs

.EXAMPLE
    .\create-users-from-csv.ps1 -CsvPath C:\LabScripts\users.csv -WhatIf
    Dry run: shows what would be created, changes nothing.

.EXAMPLE
    .\create-users-from-csv.ps1 -CsvPath C:\LabScripts\users.csv
    Creates the users for real.

.NOTES
    v1.1: removes half-created accounts after a failure, and warns about existing
    accounts that are disabled instead of counting them as fine.
    Run on the domain controller in an elevated PowerShell as a domain admin.
    Requires the ActiveDirectory module (installed with AD DS).
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Parameter(Mandatory = $true)]
    [string]$CsvPath,

    [string]$LogFolder = "C:\LabScripts\logs"
)

Import-Module ActiveDirectory -ErrorAction Stop

# --- Settings taken from the domain, not typed by hand ---------------------
$domain     = Get-ADDomain
$domainDN   = $domain.DistinguishedName          # DC=ad,DC=meridiangulf,DC=test
$upnSuffix  = $domain.DNSRoot                    # ad.meridiangulf.test
$usersRoot  = "OU=Users,OU=Meridian Gulf,$domainDN"
$company    = "Meridian Gulf Trading LLC"
$office     = "Dubai HQ"

# --- Checks before touching anything --------------------------------------
if (-not (Test-Path -Path $CsvPath)) {
    throw "CSV file not found: $CsvPath"
}

$rows = @(Import-Csv -Path $CsvPath -Encoding UTF8)
$requiredColumns = "FirstName", "LastName", "Department", "Title"
foreach ($column in $requiredColumns) {
    if ($rows.Count -eq 0 -or -not ($rows[0].PSObject.Properties.Name -contains $column)) {
        throw "The CSV must contain a '$column' column."
    }
}

# --- Log file --------------------------------------------------------------
New-Item -ItemType Directory -Path $LogFolder -Force | Out-Null
$logFile = Join-Path $LogFolder ("create-users-{0:yyyyMMdd-HHmmss}.log" -f (Get-Date))

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $line = "{0:yyyy-MM-dd HH:mm:ss} [{1}] {2}" -f (Get-Date), $Level, $Message
    Add-Content -Path $logFile -Value $line
    switch ($Level) {
        "ERROR" { Write-Host $line -ForegroundColor Red }
        "SKIP"  { Write-Host $line -ForegroundColor Yellow }
        "WARN"  { Write-Host $line -ForegroundColor Magenta }
        "OK"    { Write-Host $line -ForegroundColor Green }
        default { Write-Host $line }
    }
}

# --- Initial password (typed once, hidden, never saved) -------------------
$initialPassword = Read-Host -AsSecureString "Initial password for all new users"

Write-Log "Start. CSV: $CsvPath | Rows: $($rows.Count) | WhatIf: $($WhatIfPreference)"

$created = 0
$skipped = 0
$warned  = 0
$failed  = 0

foreach ($row in $rows) {

    $first = $row.FirstName.Trim()
    $last  = $row.LastName.Trim()
    $dept  = $row.Department.Trim()
    $title = $row.Title.Trim()

    # first.last in lower case; remove anything that is not a-z, 0-9 or a dot (e.g. hyphens)
    $sam = ("{0}.{1}" -f $first, $last).ToLower() -replace '[^a-z0-9.]', ''
    $displayName = "{0} {1}" -f $first, $last
    $ouPath      = "OU=$dept,$usersRoot"
    $groupName   = "GG-" + ($dept -replace ' ', '-')
    $createAttempted = $false

    try {
        # 1. Username length limit in AD is 20 characters
        if ($sam.Length -gt 20) {
            throw "Username '$sam' is longer than 20 characters."
        }

        # 2. Does the department OU exist?
        $null = Get-ADOrganizationalUnit -Identity $ouPath -ErrorAction Stop

        # 3. Already there? Then skip. This makes the script safe to run twice.
        $existing = Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue
        if ($existing) {
            if ($existing.Enabled) {
                Write-Log "$sam already exists, skipped." "SKIP"
                $skipped++
            }
            else {
                Write-Log "$sam already exists but is DISABLED. It may be an incomplete account. Check it." "WARN"
                $warned++
            }
            continue
        }

        # 4. Create the account
        if ($PSCmdlet.ShouldProcess($sam, "Create user in $dept and add to $groupName")) {

            $newUser = @{
                Name                  = $displayName
                GivenName             = $first
                Surname               = $last
                DisplayName           = $displayName
                SamAccountName        = $sam
                UserPrincipalName     = "$sam@$upnSuffix"
                Path                  = $ouPath
                Department            = $dept
                Title                 = $title
                Company               = $company
                Office                = $office
                AccountPassword       = $initialPassword
                Enabled               = $true
                ChangePasswordAtLogon = $true
            }
            $createAttempted = $true
            New-ADUser @newUser -ErrorAction Stop

            # 5. Add to the department group
            Add-ADGroupMember -Identity $groupName -Members $sam -ErrorAction Stop

            Write-Log "Created $sam ($title, $dept) and added to $groupName." "OK"
            $created++
        }
        else {
            Write-Log "WhatIf: would create $sam ($title, $dept) and add to $groupName."
        }
    }
    catch {
        $errorMessage = $_.Exception.Message
        Write-Log "FAILED for '$displayName' ($sam): $errorMessage" "ERROR"

        # If the password is rejected, AD can still leave a disabled account behind.
        # Remove it so a re-run starts clean (only if this run tried to create it).
        if ($createAttempted) {
            $orphan = Get-ADUser -Filter "SamAccountName -eq '$sam'" -ErrorAction SilentlyContinue
            if ($orphan) {
                Remove-ADUser -Identity $orphan -Confirm:$false -ErrorAction SilentlyContinue
                Write-Log "Removed the incomplete account for $sam so it can be created again." "WARN"
            }
        }
        if ($errorMessage -match "password") {
            Write-Log "Hint: AD rejects passwords containing the user's name (3+ characters in a row). Use a password that does not contain any part of '$displayName'." "WARN"
        }
        $failed++
    }
}

Write-Log "Finished. Created: $created | Skipped (already existed): $skipped | Warnings: $warned | Failed: $failed"
Write-Host ""
Write-Host "Log file: $logFile"
