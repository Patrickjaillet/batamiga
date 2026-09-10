# Verifie que le disque physique correspond a l'image. ADMIN.
param([int]$DiskNumber = 3,
      [string]$ImagePath = "$PSScriptRoot\..\image\batocera-x86_64-44-20260910.img")
$ErrorActionPreference = 'Stop'
$log = "$PSScriptRoot\verify-only.log"
"START $(Get-Date -Format o)" | Set-Content $log
try {
    $ImagePath = (Resolve-Path $ImagePath).Path
    $imgLen = (Get-Item $ImagePath).Length
    "image: $ImagePath ($imgLen octets)" | Add-Content $log

    $src = [System.Security.Cryptography.SHA256]::Create()
    $fs = [System.IO.File]::OpenRead($ImagePath)
    $srcHash = ([BitConverter]::ToString($src.ComputeHash($fs)) -replace '-').ToLower()
    $fs.Dispose()
    "source SHA256: $srcHash" | Add-Content $log

    $CHUNK = 4MB
    $buf = New-Object byte[] $CHUNK
    $rd = New-Object System.IO.FileStream("\\.\PhysicalDrive$DiskNumber",
          [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $remaining = $imgLen
    while ($remaining -gt 0) {
        $want = [int][math]::Min($CHUNK, [math]::Ceiling($remaining/512)*512)
        $r = $rd.Read($buf, 0, $want)
        if ($r -le 0) { "READ SHORT at remaining=$remaining" | Add-Content $log; break }
        $use = [int][math]::Min($r, $remaining)
        $sha.TransformBlock($buf, 0, $use, $null, 0) | Out-Null
        $remaining -= $use
    }
    $sha.TransformFinalBlock([byte[]]::new(0), 0, 0) | Out-Null
    $rd.Dispose()
    $dstHash = ([BitConverter]::ToString($sha.Hash) -replace '-').ToLower()
    "disk   SHA256: $dstHash" | Add-Content $log
    if ($srcHash -eq $dstHash) { "RESULT: MATCH" | Add-Content $log }
    else { "RESULT: MISMATCH" | Add-Content $log }
} catch {
    "ERROR: $_" | Add-Content $log
    "$($_.ScriptStackTrace)" | Add-Content $log
}
"END $(Get-Date -Format o)" | Add-Content $log
