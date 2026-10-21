$computer = Get-CimInstance Win32_ComputerSystem

$totalGB = $computer.TotalPhysicalMemory / 1GB
$targetPct = 90

$targetBytes = $computer.TotalPhysicalMemory * ($targetPct / 100)

$memory = New-Object System.Collections.ArrayList

while ((Get-Process -Id $PID).WorkingSet64 -lt $targetBytes)
{
    $null = $memory.Add((New-Object byte[] 100MB))
    Start-Sleep -Milliseconds 500
}

Write-Host "Reached $targetPct% Memory Utilization"

while ($true)
{
    Start-Sleep -Seconds 60
}
