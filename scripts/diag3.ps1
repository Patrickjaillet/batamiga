$log = 'C:\Users\Patrick\Desktop\Batomiga\scripts\diag3.log'
"===== $(Get-Date -Format o) =====" | Out-File $log
"--- Hyper-V-Compute-Operational (last 15) ---" | Out-File -Append $log
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Hyper-V-Compute-Operational'} -MaxEvents 15 -ErrorAction SilentlyContinue |
  Sort-Object TimeCreated |
  Select-Object TimeCreated, Id, Message | Format-List | Out-File -Append $log
"--- Lxss Manager (last 15) ---" | Out-File -Append $log
Get-WinEvent -LogName "Microsoft-Windows-Lxss-Manager/Operational" -MaxEvents 15 -ErrorAction SilentlyContinue |
  Sort-Object TimeCreated |
  Select-Object TimeCreated, Id, Message | Format-List | Out-File -Append $log
"--- vmcompute service ---" | Out-File -Append $log
Get-Service vmcompute | Out-File -Append $log
"===== FIN =====" | Out-File -Append $log
