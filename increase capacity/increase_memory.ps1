$targetPct = 90
$memory = New-Object System.Collections.ArrayList

while ($true)
{
    $os = Get-CimInstance Win32_OperatingSystem

    $totalMB = [math]::Round($os.TotalVisibleMemorySize / 1024, 2)
    $freeMB  = [math]::Round($os.FreePhysicalMemory / 1024, 2)

    $usedPct = [math]::Round((($totalMB - $freeMB) / $totalMB) * 100, 2)

    Write-Host "Current Memory Usage: $usedPct%"

    if ($usedPct -ge $targetPct)
    {
        break
    }

    $null = $memory.Add((New-Object byte[] 100MB))

    Start-Sleep -Milliseconds 500
}

Write-Host "Reached $targetPct% Memory Utilization"

while ($true)
{
    Start-Sleep -Seconds 60
}
