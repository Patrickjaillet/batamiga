$log = 'C:\Users\Patrick\Desktop\Batomiga\scripts\diag2.log'
"===== $(Get-Date -Format o) =====" | Out-File $log
Copy-Item C:\Windows\System32\bcdedit.exe "$env:TEMP\be.exe" -Force
& "$env:TEMP\be.exe" /enum "{current}" *>> $log
"--- DeviceGuard ---" | Out-File -Append $log
Get-CimInstance Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard |
  Select-Object VirtualizationBasedSecurityStatus, @{n='Running';e={$_.SecurityServicesRunning -join ','}} |
  Out-File -Append $log
"--- Hyper-V-Hypervisor-Operational (5) ---" | Out-File -Append $log
Get-WinEvent -LogName "Microsoft-Windows-Hyper-V-Hypervisor-Operational" -MaxEvents 5 -ErrorAction SilentlyContinue |
  Select-Object TimeCreated, Id, Message | Format-List | Out-File -Append $log
"--- Hyper-V-Compute-Operational (10) ---" | Out-File -Append $log
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Hyper-V-Compute-Operational'} -MaxEvents 10 -ErrorAction SilentlyContinue |
  Select-Object TimeCreated, Id, Message | Format-List | Out-File -Append $log
"--- Lxss Manager (10) ---" | Out-File -Append $log
Get-WinEvent -LogName "Microsoft-Windows-Lxss-Manager/Operational" -MaxEvents 10 -ErrorAction SilentlyContinue |
  Select-Object TimeCreated, Id, Message | Format-List | Out-File -Append $log
"===== FIN =====" | Out-File -Append $log
