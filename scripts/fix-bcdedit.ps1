# Complement de fix-vbs.ps1 : applique hypervisorlaunchtype via chemin absolu
$bcdedit = "$env:SystemRoot\System32\bcdedit.exe"
$log = 'C:\Users\Patrick\Desktop\Batomiga\scripts\fix-vbs.log'
function L($m){ $m | Tee-Object -FilePath $log -Append }

L "===== fix-bcdedit $(Get-Date -Format o) ====="
L (& $bcdedit /set hypervisorlaunchtype auto | Out-String)
L "--- etat hypervisor ---"
L (& $bcdedit /enum '{current}' | Select-String 'hypervisor' | Out-String)
L "--- DeviceGuard ---"
$dg = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard
L "Running: $($dg.SecurityServicesRunning -join ',')  VBSStatus: $($dg.VirtualizationBasedSecurityStatus)"
L "--- REDEMARRAGE REQUIS ---"
