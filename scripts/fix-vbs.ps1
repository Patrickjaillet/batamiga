# Diagnostic + desactivation VBS/Credential Guard/HVCI pour rendre VT-x a WSL2
# HP Compaq 8200 Elite SFF / i5-2400 / Win11 IoT Enterprise LTSC 2024
$log = 'C:\Users\Patrick\Desktop\Batomiga\scripts\fix-vbs.log'
function L($m){ $m | Tee-Object -FilePath $log -Append }

"===== $(Get-Date -Format o) =====" | Out-File $log
L "--- Avant ---"
L (bcdedit /enum '{current}' | Out-String)
$dg = Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard
L "SecurityServicesConfigured: $($dg.SecurityServicesConfigured -join ',')"
L "SecurityServicesRunning:    $($dg.SecurityServicesRunning -join ',')"
L "VirtualizationBasedSecurityStatus: $($dg.VirtualizationBasedSecurityStatus)"

L "--- Application des changements ---"
# 1. hypervisor lance au boot
bcdedit /set hypervisorlaunchtype auto | Out-Null
L "hypervisorlaunchtype = auto"

# 2. Desactiver VBS
$p1 = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard'
New-Item -Path $p1 -Force | Out-Null
Set-ItemProperty -Path $p1 -Name 'EnableVirtualizationBasedSecurity' -Type DWord -Value 0
Set-ItemProperty -Path $p1 -Name 'RequirePlatformSecurityFeatures' -Type DWord -Value 0
L "DeviceGuard\EnableVirtualizationBasedSecurity = 0"

# 3. Desactiver Credential Guard
$p2 = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\CredentialGuard'
New-Item -Path $p2 -Force | Out-Null
Set-ItemProperty -Path $p2 -Name 'Enabled' -Type DWord -Value 0
L "CredentialGuard\Enabled = 0"

# 4. Desactiver HVCI (integrite du code protegee par l'hyperviseur)
$p3 = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'
New-Item -Path $p3 -Force | Out-Null
Set-ItemProperty -Path $p3 -Name 'Enabled' -Type DWord -Value 0
L "HVCI\Enabled = 0"

# 5. LSA cfg flag (Credential Guard historique)
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' -Name 'LsaCfgFlags' -Type DWord -Value 0 -ErrorAction SilentlyContinue
L "Lsa\LsaCfgFlags = 0"

L "--- Termine. REDEMARRAGE REQUIS. ---"
