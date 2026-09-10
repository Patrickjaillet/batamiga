# Diagnostic complet WSL2 / hyperviseur. Lancer en PowerShell ADMIN.
$log = 'C:\Users\Patrick\Desktop\Batomiga\scripts\diag-wsl.log'
function L($m){ $m | Out-String | Tee-Object -FilePath $log -Append }

"===== DIAG WSL $(Get-Date -Format o) =====" | Out-File $log

L "### 1. Features Windows"
L (Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform, Microsoft-Windows-Subsystem-Linux, HypervisorPlatform, Microsoft-Hyper-V-All | Select-Object FeatureName, State | Format-Table -Auto)

L "### 2. BCD (via copie be.exe pour contourner WDAC)"
Copy-Item C:\Windows\System32\bcdedit.exe "$env:TEMP\be.exe" -Force
L (& "$env:TEMP\be.exe" /enum '{current}')
L "--- hypervisorsettings ---"
L (& "$env:TEMP\be.exe" /enum '{hypervisorsettings}')

L "### 3. DeviceGuard / VBS"
$dg = Get-CimInstance Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard
L ($dg | Select-Object VirtualizationBasedSecurityStatus, `
    @{n='SecServicesConfigured';e={$_.SecurityServicesConfigured -join ','}}, `
    @{n='SecServicesRunning';e={$_.SecurityServicesRunning -join ','}}, `
    CodeIntegrityPolicyEnforcementStatus, UsermodeCodeIntegrityPolicyEnforcementStatus | Format-List)

L "### 4. CPU"
$c = Get-WmiObject Win32_Processor
L ($c | Select-Object Name, VirtualizationFirmwareEnabled, VMMonitorModeExtensions, SecondLevelAddressTranslationExtensions | Format-List)

L "### 5. Services"
L (Get-Service vmcompute, hns, WslService, LxssManager -ErrorAction SilentlyContinue | Select-Object Name, Status, StartType | Format-Table -Auto)

L "### 6. Journal Hyper-V Hypervisor (10 derniers)"
L (Get-WinEvent -LogName 'Microsoft-Windows-Hyper-V-Hypervisor-Operational' -MaxEvents 10 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, Message | Format-List)

L "### 7. Journal Hyper-V Worker / Compute (10 derniers)"
L (Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Hyper-V-Compute-Operational'} -MaxEvents 10 -ErrorAction SilentlyContinue | Select-Object TimeCreated, Id, Message | Format-List)

L "### 8. hvciscan / systeminfo hyperviseur"
L (systeminfo | Select-String 'Hyper-V','hyperviseur','virtualisation','virtualization')

L "===== FIN — copie ce fichier: $log ====="
Write-Host "`nTermine. Log: $log" -ForegroundColor Green
