<#
Batamiga — back up / restore the SHARE partition content (/userdata) of
a booted device over SSH. Games, BIOS, saves, gamelists, media, config.

Backup:
  .\backup-userdata.ps1 -Action backup -Out "D:\Batamiga-backups"
Restore:
  .\backup-userdata.ps1 -Action restore -Archive "D:\Batamiga-backups\userdata-20260910.tar.gz"

The device must be booted and reachable. Default login: root / linux.
Backup pulls a gzip tar of the useful subtrees (not the whole ext4).
Restore streams it back and unpacks in place (existing files overwritten,
nothing deleted).
#>
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('backup', 'restore')]
    [string]$Action,

    [string]$Out,
    [string]$Archive,
    [string]$HostName = 'batocera',
    [string]$User = 'root'
)

$ErrorActionPreference = 'Stop'
# subtrees worth keeping; skip caches / extractions
$paths = @('roms', 'bios', 'saves', 'system/configs', 'system/batocera.conf',
    'system/.emulationstation/collections', 'music', 'screenshots')

if (-not (Test-Connection -ComputerName $HostName -Count 1 -Quiet)) {
    throw "$HostName is not reachable."
}

if ($Action -eq 'backup') {
    if (-not $Out) { throw "-Out <folder> is required for backup" }
    New-Item -ItemType Directory -Force -Path $Out | Out-Null
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $dest = Join-Path $Out "userdata-$stamp.tar.gz"
    $remote = ($paths | ForEach-Object { "'$_'" }) -join ' '
    Write-Host "Pulling backup from $HostName ..." -ForegroundColor Cyan
    & ssh "$User@$HostName" "cd /userdata && tar czf - $remote 2>/dev/null" |
        Set-Content -Path $dest -Encoding Byte
    if ($LASTEXITCODE -ne 0) { throw "ssh/tar failed (exit $LASTEXITCODE)" }
    Write-Host ("Saved {0} ({1:N1} MB)" -f $dest, ((Get-Item $dest).Length / 1MB)) -ForegroundColor Green
}
else {
    if (-not $Archive -or -not (Test-Path $Archive)) { throw "-Archive <file.tar.gz> not found" }
    Write-Host "Restoring $Archive to $HostName:/userdata ..." -ForegroundColor Cyan
    Get-Content -Path $Archive -Encoding Byte -ReadCount 0 |
        & ssh "$User@$HostName" "cd /userdata && tar xzf -"
    if ($LASTEXITCODE -ne 0) { throw "ssh/tar failed (exit $LASTEXITCODE)" }
    Write-Host "Done. Reboot the device (Start -> Restart)." -ForegroundColor Green
}
