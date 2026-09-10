<#
Flash l'image Batocera Amiga500-only sur une cle USB.
A lancer en PowerShell ADMIN.

  .\flash-usb.ps1 -DiskNumber 3

Accepte une image brute (.img) ou compressee (.img.gz) via -ImagePath.
DiskNumber : le numero du disque cible (voir "Get-Disk"). DESTRUCTIF —
tout le contenu du disque est efface.
#>
param(
    [Parameter(Mandatory = $true)]
    [int]$DiskNumber,

    [string]$ImagePath = "$PSScriptRoot\..\image\batocera-x86_64-44-20260910.img",

    # Passe la confirmation interactive (pour lancement automatise)
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'

# --- Verifications ---
if (-not (Test-Path $ImagePath)) {
    # fallback : essayer la variante .gz si l'utilisateur a passe le .img
    if (Test-Path "$ImagePath.gz") { $ImagePath = "$ImagePath.gz" }
    else { throw "Image introuvable : $ImagePath" }
}
$ImagePath = (Resolve-Path $ImagePath).Path
$isGz = $ImagePath.ToLower().EndsWith('.gz')

$disk = Get-Disk -Number $DiskNumber
Write-Host ""
Write-Host "=== Disque cible ===" -ForegroundColor Yellow
Write-Host ("  Numero    : {0}" -f $disk.Number)
Write-Host ("  Modele    : {0}" -f $disk.FriendlyName)
Write-Host ("  Bus       : {0}" -f $disk.BusType)
Write-Host ("  Taille    : {0} Go" -f [math]::Round($disk.Size / 1GB, 1))
Write-Host ("  Image     : {0}{1}" -f (Split-Path $ImagePath -Leaf), $(if ($isGz) { ' (gzip)' } else { ' (brute)' }))
Write-Host ""

if ($disk.BusType -ne 'USB') {
    Write-Warning "Ce disque n'est PAS en USB. Verifie bien le numero."
}

if (-not $Yes) {
    $confirm = Read-Host "Ecraser COMPLETEMENT ce disque ? Tape OUI en majuscules"
    if ($confirm -ne 'OUI') { Write-Host "Annule."; return }
}

# --- Nettoyage du disque (retire les partitions / verrous de volume) ---
Write-Host "Nettoyage du disque..." -ForegroundColor Cyan
$dp = @"
select disk $DiskNumber
clean
"@
$dp | diskpart | Out-Null
Start-Sleep -Seconds 2

# --- Ecriture brute (avec decompression gzip a la volee si besoin) ---
Write-Host "Ecriture de l'image..." -ForegroundColor Cyan
$in = [System.IO.File]::OpenRead($ImagePath)
if ($isGz) {
    Add-Type -AssemblyName System.IO.Compression
    $src = New-Object System.IO.Compression.GZipStream($in, [System.IO.Compression.CompressionMode]::Decompress)
} else {
    $src = $in
}
$out = New-Object System.IO.FileStream("\\.\PhysicalDrive$DiskNumber", [System.IO.FileMode]::Open, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)

$SECTOR = 512
$CHUNK  = 4MB
$buf    = New-Object byte[] $CHUNK
$carry  = New-Object byte[] 0
$total  = [int64]0
$sw     = [System.Diagnostics.Stopwatch]::StartNew()

try {
    while ($true) {
        $n = $src.Read($buf, 0, $CHUNK)
        if ($n -le 0) { break }

        # concatener le reliquat precedent + les n octets lus
        $data = New-Object byte[] ($carry.Length + $n)
        [Array]::Copy($carry, 0, $data, 0, $carry.Length)
        [Array]::Copy($buf, 0, $data, $carry.Length, $n)

        # n'ecrire qu'un multiple entier de secteurs, garder le reste
        $aligned = [math]::Floor($data.Length / $SECTOR) * $SECTOR
        if ($aligned -gt 0) {
            $out.Write($data, 0, $aligned)
            $total += $aligned
        }
        $rem = $data.Length - $aligned
        $carry = New-Object byte[] $rem
        if ($rem -gt 0) { [Array]::Copy($data, $aligned, $carry, 0, $rem) }

        if ($sw.Elapsed.TotalSeconds -ge 5) {
            try { [Console]::Error.WriteLine("  {0} Mo ecrits..." -f [math]::Round($total / 1MB)) } catch {}
            $sw.Restart()
        }
    }

    # dernier reliquat : completer au secteur avec des zeros
    if ($carry.Length -gt 0) {
        $pad = New-Object byte[] $SECTOR
        [Array]::Copy($carry, 0, $pad, 0, $carry.Length)
        $out.Write($pad, 0, $SECTOR)
        $total += $SECTOR
    }

    $out.Flush()
}
finally {
    $out.Dispose()
    if ($isGz) { $src.Dispose() }
    $in.Dispose()
}

Write-Host ""
Write-Host ("Termine : {0} Mo ecrits sur le disque {1}." -f [math]::Round($total / 1MB), $DiskNumber) -ForegroundColor Green
Write-Host "Ejecte la cle proprement avant de la retirer." -ForegroundColor Yellow
