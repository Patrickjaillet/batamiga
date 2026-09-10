<#
Flash + verification byte-a-byte de l'image Batocera sur une cle USB.
A lancer en PowerShell ADMIN.

  .\flash-verify.ps1 -DiskNumber 3

Met le disque hors ligne (evite la course avec l'automontage Windows),
ecrit l'image brute, relit et compare le SHA256, puis laisse le disque
hors ligne (Windows le remet en ligne au rebranchement).
#>
param(
    [Parameter(Mandatory = $true)]
    [int]$DiskNumber,
    [string]$ImagePath = "$PSScriptRoot\..\image\batocera-x86_64-44-20260910.img",
    [switch]$Yes
)

$ErrorActionPreference = 'Stop'
if (-not (Test-Path $ImagePath)) { throw "Image introuvable : $ImagePath" }
$ImagePath = (Resolve-Path $ImagePath).Path
$imgLen = (Get-Item $ImagePath).Length

$disk = Get-Disk -Number $DiskNumber
Write-Host ""
Write-Host "=== Disque cible ===" -ForegroundColor Yellow
Write-Host ("  {0} | {1} | {2} Go | offline={3}" -f $disk.Number, $disk.FriendlyName, [math]::Round($disk.Size/1GB,1), $disk.IsOffline)
Write-Host ("  Image : {0} ({1} Mo)" -f (Split-Path $ImagePath -Leaf), [math]::Round($imgLen/1MB))
if ($disk.Size -lt $imgLen) { throw "Le disque est plus petit que l'image." }
Write-Host ""
if (-not $Yes) {
    if ((Read-Host "Ecraser le disque $DiskNumber ? Tape OUI") -ne 'OUI') { return }
}

# --- disque hors ligne + nettoyage ---
Write-Host "Mise hors ligne + nettoyage..." -ForegroundColor Cyan
"select disk $DiskNumber`r`noffline disk`r`nattributes disk clear readonly`r`nclean" | diskpart | Out-Null
Start-Sleep 2

function Open-Drive([string]$path, [System.IO.FileAccess]$access) {
    for ($i=0; $i -lt 10; $i++) {
        try { return New-Object System.IO.FileStream($path, [System.IO.FileMode]::Open, $access, [System.IO.FileShare]::None) }
        catch { Start-Sleep 1 }
    }
    throw "Impossible d'ouvrir $path"
}

$SECTOR = 512
$CHUNK  = 4MB

# --- ecriture ---
Write-Host "Ecriture..." -ForegroundColor Cyan
$in  = [System.IO.File]::OpenRead($ImagePath)
$out = Open-Drive "\\.\PhysicalDrive$DiskNumber" ([System.IO.FileAccess]::Write)
$buf = New-Object byte[] $CHUNK
$total = [int64]0
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    while (($n = $in.Read($buf, 0, $CHUNK)) -gt 0) {
        $w = [int]([math]::Ceiling($n / $SECTOR) * $SECTOR)   # arrondi secteur (l'image est deja alignee)
        if ($w -ne $n) { for ($k=$n; $k -lt $w; $k++) { $buf[$k] = 0 } }
        $out.Write($buf, 0, $w)
        $total += $w
        if ($sw.Elapsed.TotalSeconds -ge 5) {
            try { [Console]::Error.WriteLine("  ecrit {0} Mo" -f [math]::Round($total/1MB)) } catch {}
            $sw.Restart()
        }
    }
    $out.Flush($true)
} finally { $out.Dispose(); $in.Dispose() }
Write-Host ("Ecrit : {0} Mo" -f [math]::Round($total/1MB)) -ForegroundColor Green

# --- verification : SHA256 des imgLen premiers octets relus ---
Write-Host "Verification (relecture)..." -ForegroundColor Cyan
$srcHash = (Get-FileHash $ImagePath -Algorithm SHA256).Hash.ToLower()

$rd = Open-Drive "\\.\PhysicalDrive$DiskNumber" ([System.IO.FileAccess]::Read)
$sha = [System.Security.Cryptography.SHA256]::Create()
$remaining = $imgLen
$sw.Restart()
try {
    while ($remaining -gt 0) {
        $toRead = [int][math]::Min($CHUNK, [math]::Ceiling($remaining / $SECTOR) * $SECTOR)
        $r = $rd.Read($buf, 0, $toRead)
        if ($r -le 0) { break }
        $use = [int][math]::Min($r, $remaining)
        $sha.TransformBlock($buf, 0, $use, $null, 0) | Out-Null
        $remaining -= $use
        if ($sw.Elapsed.TotalSeconds -ge 5) {
            try { [Console]::Error.WriteLine("  relu {0} Mo" -f [math]::Round(($imgLen-$remaining)/1MB)) } catch {}
            $sw.Restart()
        }
    }
    $sha.TransformFinalBlock([byte[]]::new(0), 0, 0) | Out-Null
} finally { $rd.Dispose() }
$dstHash = -join ($sha.Hash | ForEach-Object { $_.ToString('x2') })

Write-Host ""
Write-Host ("source : {0}" -f $srcHash)
Write-Host ("cle    : {0}" -f $dstHash)
if ($srcHash -eq $dstHash) {
    Write-Host "OK - la cle est identique a l'image." -ForegroundColor Green
    Write-Host "Rebranche la cle (Windows la remettra en ligne), ou boote directement dessus."
} else {
    Write-Host "ECHEC - la cle ne correspond pas a l'image (cle defectueuse ?)." -ForegroundColor Red
    exit 2
}
