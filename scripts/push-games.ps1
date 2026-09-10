<#
Batamiga — push a local folder of Amiga games to the running device over
the network (SSH/SCP), into the right roms folder on the SHARE partition.

  .\push-games.ps1 -System amiga500 -Source "D:\Amiga\A500 games"
  .\push-games.ps1 -System amigacd32 -Source "D:\Amiga\CD32" -Host 192.168.1.42

Requires OpenSSH client (built into Windows 10/11). The device must be
booted and reachable. Default login: root / linux.
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('amiga500', 'amiga1200', 'amigacd32')]
    [string]$System,

    [Parameter(Mandatory = $true)]
    [string]$Source,

    [string]$HostName = 'batocera',

    [string]$User = 'root'
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $Source)) { throw "Source folder not found: $Source" }
$Source = (Resolve-Path $Source).Path
$dest = "/userdata/roms/$System/"

Write-Host ("Target : {0}@{1}:{2}" -f $User, $HostName, $dest) -ForegroundColor Yellow
Write-Host ("Source : {0}" -f $Source)

# reachability check
if (-not (Test-Connection -ComputerName $HostName -Count 1 -Quiet)) {
    throw "$HostName is not reachable. Check the device is booted and on the network."
}

$files = Get-ChildItem -Path $Source -File -Recurse
if ($files.Count -eq 0) { throw "No files under $Source" }
Write-Host ("{0} file(s), {1:N1} MB total" -f $files.Count, (($files | Measure-Object Length -Sum).Sum / 1MB))

# ensure the folder exists on the device
& ssh "$User@$HostName" "mkdir -p $dest"

# copy (scp keeps it simple and dependency-free; -p preserves timestamps)
& scp -p -r "$Source\*" "${User}@${HostName}:$dest"
if ($LASTEXITCODE -ne 0) { throw "scp failed (exit $LASTEXITCODE)" }

Write-Host ""
Write-Host "Done. On the device: Start -> Update gamelists (or reboot)." -ForegroundColor Green
Write-Host "Then scrape: Start -> Scraper." -ForegroundColor Green
