$memory = @()

1..15 | ForEach-Object {
    $memory += ,(New-Object byte[] 100MB)
    Start-Sleep -Milliseconds 500
}

Write-Host "Memory Pressure Created"
Start-Sleep -Seconds 600
