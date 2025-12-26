# True automatic clipboard monitor using Windows events
param(
    [string]$SaveDirectory = "/tmp",
    [string]$WslDistro = "auto"
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Convert Unix-style paths to WSL UNC format
if ($SaveDirectory -match "^/") {
    # Try to auto-detect WSL distribution if auto mode is used
    if ($WslDistro -eq "auto") {
        $WslDistros = @(wsl.exe -l -q | Where-Object { 
            $_ -and $_.Trim() -ne "" -and $_ -notlike "*docker*" 
        } | ForEach-Object { 
            $_.Trim() -replace '\s+', '' -replace '\x00', ''
        })
        if ($WslDistros.Count -gt 0) {
            $WslDistro = $WslDistros[0]
            Write-Host "Auto-detected WSL distribution: $WslDistro"
        } else {
            Write-Error "No WSL distribution found. Please install WSL or specify -WslDistro parameter."
            exit 1
        }
    }

    # Convert Unix path to UNC path (remove leading slash, replace / with \)
    $UnixPath = $SaveDirectory.TrimStart('/')
    $SaveDirectory = "\\wsl.localhost\$WslDistro\$UnixPath"

    if (!(Test-Path "\\wsl.localhost\$WslDistro")) {
        Write-Error "Cannot access WSL distribution '$WslDistro'. Make sure WSL is running."
        exit 1
    }
}

if (!(Test-Path $SaveDirectory)) {
    New-Item -ItemType Directory -Path $SaveDirectory -Force | Out-Null
}

Write-Host "WINDOWS-TO-WSL2 SCREENSHOT AUTOMATION STARTED"
Write-Host "Auto-saving images to: $SaveDirectory"
Write-Host "Press Ctrl+C to stop"



Write-Host "Monitoring clipboard events and directory changes..."
$previousHash = $null
$lastFileTime = Get-Date

while ($true) {
    try {
        Start-Sleep -Milliseconds 500
        
        if ([System.Windows.Forms.Clipboard]::ContainsImage()) {
            $image = [System.Windows.Forms.Clipboard]::GetImage()
            if ($image) {
                $ms = New-Object System.IO.MemoryStream
                $image.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
                $imageBytes = $ms.ToArray()
                $ms.Dispose()
                $currentHash = [System.BitConverter]::ToString([System.Security.Cryptography.SHA256]::Create().ComputeHash($imageBytes))
                
                if ($currentHash -ne $previousHash) {
                    $latestPath = Join-Path $SaveDirectory "latest.png"
                    $image.Save($latestPath, [System.Drawing.Imaging.ImageFormat]::Png)
                    Write-Host "AUTO-SAVED: latest.png"
                    $previousHash = $currentHash
                }
                $image.Dispose()
            }
        }
        
        # Also check for new files in the directory (for drag-drop screenshots)
        $currentTime = Get-Date
        $newFiles = Get-ChildItem $SaveDirectory -Filter "*.png" | Where-Object { 
            $_.LastWriteTime -gt $lastFileTime -and $_.Name -ne "latest.png" 
        }
        
        if ($newFiles) {
            $latestFile = $newFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            Copy-Item $latestFile.FullName (Join-Path $SaveDirectory "latest.png") -Force
            Write-Host "NEW FILE DETECTED - copied to latest.png"
            $lastFileTime = $currentTime
        }
        
    } catch {
        Write-Warning "Error in main loop: $_"
        Start-Sleep -Milliseconds 1000
    }
}
