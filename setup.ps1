#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Interactive software installer using Windows Package Manager (Winget)
.DESCRIPTION
    Presents an interactive menu to select and install popular software packages
.NOTES
    Must be run as Administrator
    Requires Windows Package Manager (winget)
#>

# Check if winget is installed
function Test-WingetInstalled {
    try {
        $null = winget --version
        return $true
    }
    catch {
        return $false
    }
}

# Install winget if not present
function Install-Winget {
    Write-Host "Windows Package Manager (winget) is not installed." -ForegroundColor Yellow
    Write-Host "Installing winget..." -ForegroundColor Cyan

    try {
        # Install App Installer from Microsoft Store (contains winget)
        $progressPreference = 'silentlyContinue'
        Write-Host "Downloading App Installer..." -ForegroundColor Yellow

        # Try to install via PowerShell
        Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe

        Write-Host "Winget installed successfully!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Failed to install winget automatically." -ForegroundColor Red
        Write-Host "Please install 'App Installer' from the Microsoft Store and run this script again." -ForegroundColor Yellow
        Write-Host "Press any key to exit..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        exit 1
    }
}

# Cloudflare Worker URL for authenticated custom software downloads
$R2_BASE_URL = "https://downloads.YOUR-ACCOUNT.workers.dev"  # Replace with your Worker URL
$R2_AUTH_KEY = "your-secure-password-here"  # Replace with your password from Worker

# Software catalog with winget package IDs
$softwareCatalog = @{
    "Custom Software" = @(
        @{ Name = "Example App 1"; ID = "CUSTOM_APP1"; URL = "$R2_BASE_URL/app1-installer.exe?key=$R2_AUTH_KEY"; Silent = $true; SilentArgs = "/S" }
        @{ Name = "Example App 2"; ID = "CUSTOM_APP2"; URL = "$R2_BASE_URL/app2-setup.msi?key=$R2_AUTH_KEY"; Silent = $true; SilentArgs = "/quiet /norestart" }
        @{ Name = "Example Script"; ID = "CUSTOM_SCRIPT1"; URL = "$R2_BASE_URL/script.ps1?key=$R2_AUTH_KEY"; Silent = $false; SilentArgs = "" }
    )
    "Browsers" = @(
        @{ Name = "Google Chrome"; ID = "Google.Chrome" }
        @{ Name = "Mozilla Firefox"; ID = "Mozilla.Firefox" }
        @{ Name = "Brave Browser"; ID = "Brave.Brave" }
    )
    "Communication" = @(
        @{ Name = "Zoom"; ID = "Zoom.Zoom" }
        @{ Name = "Microsoft Teams"; ID = "Microsoft.Teams" }
        @{ Name = "Slack"; ID = "SlackTechnologies.Slack" }
        @{ Name = "Discord"; ID = "Discord.Discord" }
    )
    "Productivity" = @(
        @{ Name = "Adobe Acrobat Reader"; ID = "Adobe.Acrobat.Reader.64-bit" }
        @{ Name = "LibreOffice"; ID = "TheDocumentFoundation.LibreOffice" }
        @{ Name = "Notion"; ID = "Notion.Notion" }
        @{ Name = "Obsidian"; ID = "Obsidian.Obsidian" }
    )
    "Development" = @(
        @{ Name = "Visual Studio Code"; ID = "Microsoft.VisualStudioCode" }
        @{ Name = "Git"; ID = "Git.Git" }
        @{ Name = "GitHub Desktop"; ID = "GitHub.GitHubDesktop" }
        @{ Name = "Python 3"; ID = "Python.Python.3.12" }
        @{ Name = "Node.js LTS"; ID = "OpenJS.NodeJS.LTS" }
        @{ Name = "Notepad++"; ID = "Notepad++.Notepad++" }
        @{ Name = "Windows Terminal"; ID = "Microsoft.WindowsTerminal" }
    )
    "Utilities" = @(
        @{ Name = "7-Zip"; ID = "7zip.7zip" }
        @{ Name = "WinRAR"; ID = "RARLab.WinRAR" }
        @{ Name = "PowerToys"; ID = "Microsoft.PowerToys" }
        @{ Name = "Everything (File Search)"; ID = "voidtools.Everything" }
        @{ Name = "TreeSize Free"; ID = "JAM-Software.TreeSize.Free" }
    )
    "Media" = @(
        @{ Name = "VLC Media Player"; ID = "VideoLAN.VLC" }
        @{ Name = "Spotify"; ID = "Spotify.Spotify" }
        @{ Name = "OBS Studio"; ID = "OBSProject.OBSStudio" }
    )
    "Remote Access" = @(
        @{ Name = "TeamViewer"; ID = "TeamViewer.TeamViewer" }
        @{ Name = "TeamViewer (Long Branch)"; ID = "TEAMVIEWER_LONGBRANCH_CUSTOM" }
        @{ Name = "AnyDesk"; ID = "AnyDeskSoftwareGmbH.AnyDesk" }
    )
}

# Display header
function Show-Header {
    Clear-Host
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "   Interactive Software Installer (Winget)  " -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host ""
}

# Display menu and get selections
function Get-SoftwareSelections {
    $selections = @()
    $allPackages = @()
    $index = 1

    Show-Header

    Write-Host "Select software to install (enter numbers separated by commas)" -ForegroundColor Yellow
    Write-Host "Example: 1,3,5,7 or type 'all' to install everything" -ForegroundColor Gray
    Write-Host ""

    # Display all software organized by category
    foreach ($category in $softwareCatalog.Keys | Sort-Object) {
        Write-Host "--- $category ---" -ForegroundColor Green
        foreach ($software in $softwareCatalog[$category]) {
            Write-Host ("{0,3}. {1}" -f $index, $software.Name) -ForegroundColor White
            $allPackages += $software
            $index++
        }
        Write-Host ""
    }

    Write-Host "  0. Install ALL software" -ForegroundColor Magenta
    Write-Host ""
    Write-Host -NoNewline "Your selection: " -ForegroundColor Cyan
    $input = Read-Host

    # Process input
    if ($input.Trim() -eq "0" -or $input.Trim().ToLower() -eq "all") {
        return $allPackages
    }

    $selectedIndices = $input -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ }

    foreach ($idx in $selectedIndices) {
        if ($idx -gt 0 -and $idx -le $allPackages.Count) {
            $selections += $allPackages[$idx - 1]
        }
    }

    return $selections
}

# Install selected software
function Install-SelectedSoftware {
    param (
        [array]$Packages
    )

    if ($Packages.Count -eq 0) {
        Write-Host "No software selected. Exiting." -ForegroundColor Yellow
        return
    }

    Write-Host "`nStarting installation of $($Packages.Count) package(s)..." -ForegroundColor Cyan
    Write-Host ""

    $successCount = 0
    $failCount = 0
    $results = @()

    foreach ($package in $Packages) {
        Write-Host "Installing: $($package.Name)..." -ForegroundColor Yellow

        try {
            # Handle custom software from R2 bucket
            if ($package.ID -match '^CUSTOM_') {
                $installed = Install-CustomSoftware -Name $package.Name -URL $package.URL -Silent $package.Silent -SilentArgs $package.SilentArgs
                if ($installed) {
                    $successCount++
                    $results += [PSCustomObject]@{
                        Name = $package.Name
                        Status = "Success"
                    }
                }
                else {
                    $failCount++
                    $results += [PSCustomObject]@{
                        Name = $package.Name
                        Status = "Failed"
                    }
                }
            }
            # Handle custom TeamViewer Long Branch installer
            elseif ($package.ID -eq "TEAMVIEWER_LONGBRANCH_CUSTOM") {
                $installed = Install-TeamViewerDirect
                if ($installed) {
                    $successCount++
                    $results += [PSCustomObject]@{
                        Name = $package.Name
                        Status = "Success"
                    }
                }
                else {
                    $failCount++
                    $results += [PSCustomObject]@{
                        Name = $package.Name
                        Status = "Failed"
                    }
                }
            }
            else {
                # Standard winget installation
                $process = Start-Process -FilePath "winget" -ArgumentList "install --id $($package.ID) --silent --accept-package-agreements --accept-source-agreements" -Wait -PassThru -NoNewWindow

                if ($process.ExitCode -eq 0) {
                    Write-Host "  SUCCESS: $($package.Name)" -ForegroundColor Green
                    $successCount++
                    $results += [PSCustomObject]@{
                        Name = $package.Name
                        Status = "Success"
                    }
                }
                else {
                    Write-Host "  FAILED: $($package.Name) (Exit Code: $($process.ExitCode))" -ForegroundColor Red
                    $failCount++
                    $results += [PSCustomObject]@{
                        Name = $package.Name
                        Status = "Failed (Exit Code: $($process.ExitCode))"
                    }
                }
            }
        }
        catch {
            Write-Host "  ERROR: $($package.Name) - $_" -ForegroundColor Red
            $failCount++
            $results += [PSCustomObject]@{
                Name = $package.Name
                Status = "Error: $_"
            }
        }

        Write-Host ""
    }

    # Summary
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "Installation Summary" -ForegroundColor Cyan
    Write-Host "=============================================" -ForegroundColor Cyan
    Write-Host "Total Packages: $($Packages.Count)" -ForegroundColor White
    Write-Host "Successful: $successCount" -ForegroundColor Green
    Write-Host "Failed: $failCount" -ForegroundColor Red
    Write-Host ""

    # Detailed results
    $results | Format-Table -AutoSize

    Write-Host "`nInstallation completed!" -ForegroundColor Green

    return $results
}

# Set Chrome as default browser
function Set-ChromeAsDefaultBrowser {
    Write-Host "`nSetting Google Chrome as default browser..." -ForegroundColor Cyan

    try {
        # Get Chrome path
        $chromePath = "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe"

        if (-not (Test-Path $chromePath)) {
            $chromePath = "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe"
        }

        if (-not (Test-Path $chromePath)) {
            Write-Host "  Chrome installation not found. Skipping default browser setup." -ForegroundColor Yellow
            return $false
        }

        # Set Chrome as default for common protocols and file types
        $associations = @{
            ".htm" = "ChromeHTML"
            ".html" = "ChromeHTML"
            "http" = "ChromeHTML"
            "https" = "ChromeHTML"
        }

        foreach ($ext in $associations.Keys) {
            try {
                $progId = $associations[$ext]

                # Try using built-in command (Windows 10+)
                if ($ext.StartsWith(".")) {
                    # File extension
                    cmd /c "assoc $ext=$progId" 2>$null
                } else {
                    # Protocol
                    $regPath = "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\$ext\UserChoice"
                    if (Test-Path $regPath) {
                        Remove-Item $regPath -Force -ErrorAction SilentlyContinue
                    }
                }
            }
            catch {
                # Continue on error
            }
        }

        Write-Host "  Chrome browser associations updated." -ForegroundColor Green
        Write-Host "  NOTE: You may need to manually confirm Chrome as default in Windows Settings." -ForegroundColor Yellow

        # Open Windows default apps settings
        Write-Host -NoNewline "`n  Open Windows Settings to confirm? (Y/N): " -ForegroundColor Cyan
        $openSettings = Read-Host

        if ($openSettings -eq 'Y' -or $openSettings -eq 'y') {
            Start-Process "ms-settings:defaultapps"
            Write-Host "  Opened Windows Settings > Default Apps" -ForegroundColor Green
        }

        return $true
    }
    catch {
        Write-Host "  Failed to set Chrome as default: $_" -ForegroundColor Red
        return $false
    }
}

# Install custom software from R2 bucket
function Install-CustomSoftware {
    param (
        [string]$Name,
        [string]$URL,
        [bool]$Silent = $true,
        [string]$SilentArgs = "/S"
    )

    Write-Host "`nDownloading $Name..." -ForegroundColor Cyan

    try {
        # Create temp directory
        $tempDir = "$env:TEMP\CustomSoftwareInstall"
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }

        # Get file extension from URL
        $fileName = [System.IO.Path]::GetFileName($URL)
        if (-not $fileName -or $fileName -notmatch '\.\w+$') {
            $fileName = "installer.exe"
        }
        $installerPath = "$tempDir\$fileName"

        # Download file
        Write-Host "  Downloading from $URL..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $URL -OutFile $installerPath -UseBasicParsing -ErrorAction Stop
        Write-Host "  Download completed!" -ForegroundColor Green

        # Check if it's a PowerShell script
        if ($fileName -match '\.ps1$') {
            Write-Host "  Executing PowerShell script..." -ForegroundColor Yellow
            & $installerPath
            Write-Host "  Script executed!" -ForegroundColor Green
        }
        else {
            # Run installer
            if ($Silent) {
                Write-Host "  Installing $Name silently..." -ForegroundColor Yellow
                $process = Start-Process -FilePath $installerPath -ArgumentList $SilentArgs -Wait -PassThru -NoNewWindow -ErrorAction Stop

                if ($process.ExitCode -eq 0) {
                    Write-Host "  $Name installed successfully!" -ForegroundColor Green
                }
                else {
                    Write-Host "  $Name installation completed with exit code: $($process.ExitCode)" -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "  Launching $Name installer..." -ForegroundColor Yellow
                Write-Host "  Please complete the installation in the window that opens." -ForegroundColor Cyan
                Start-Process -FilePath $installerPath
                Write-Host "  Installer launched!" -ForegroundColor Green
            }
        }

        # Cleanup (only if silent install)
        if ($Silent -and $fileName -notmatch '\.ps1$') {
            Start-Sleep -Seconds 2
            Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "  Cleanup completed." -ForegroundColor Green
        }

        return $true
    }
    catch {
        Write-Host "  Failed to install $Name : $_" -ForegroundColor Red
        Write-Host "  You can download manually from: $URL" -ForegroundColor Yellow
        return $false
    }
}

# Install TeamViewer from direct download link
function Install-TeamViewerDirect {
    Write-Host "`nDownloading TeamViewer (Longbranch)..." -ForegroundColor Cyan

    try {
        # Create temp directory
        $tempDir = "$env:TEMP\TeamViewerInstall"
        if (-not (Test-Path $tempDir)) {
            New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        }

        $installerPath = "$tempDir\TeamViewerSetup.exe"
        $downloadUrl = "https://get.teamviewer.com/longbranch"

        # Download installer
        Write-Host "  Downloading from $downloadUrl..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing -ErrorAction Stop
        Write-Host "  Download completed!" -ForegroundColor Green

        # Launch installer (not silent - let user click through)
        Write-Host "  Launching TeamViewer installer..." -ForegroundColor Yellow
        Write-Host "  Please complete the installation in the window that opens." -ForegroundColor Cyan
        Start-Process -FilePath $installerPath

        Write-Host "  TeamViewer installer launched!" -ForegroundColor Green
        Write-Host "  Note: Temp file will remain until you restart or manually delete: $installerPath" -ForegroundColor Gray

        return $true
    }
    catch {
        Write-Host "  Failed to download TeamViewer: $_" -ForegroundColor Red
        Write-Host "  You can download manually from: $downloadUrl" -ForegroundColor Yellow
        return $false
    }
}

# Set Adobe Reader as default PDF reader
function Set-AdobeAsDefaultPDF {
    Write-Host "`nSetting Adobe Acrobat Reader as default PDF viewer..." -ForegroundColor Cyan

    try {
        # Find Adobe Reader installation
        $adobePaths = @(
            "${env:ProgramFiles}\Adobe\Acrobat DC\Acrobat\Acrobat.exe",
            "${env:ProgramFiles(x86)}\Adobe\Acrobat DC\Acrobat\Acrobat.exe",
            "${env:ProgramFiles}\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe",
            "${env:ProgramFiles(x86)}\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe"
        )

        $adobePath = $null
        foreach ($path in $adobePaths) {
            if (Test-Path $path) {
                $adobePath = $path
                break
            }
        }

        if (-not $adobePath) {
            Write-Host "  Adobe Reader installation not found. Skipping default PDF setup." -ForegroundColor Yellow
            return $false
        }

        # Set .pdf file association
        try {
            # Use ftype and assoc commands
            cmd /c 'assoc .pdf=AcroExch.Document.DC' 2>$null
            cmd /c "ftype AcroExch.Document.DC=`"$adobePath`" `"%1`"" 2>$null

            Write-Host "  Adobe Reader set as default for PDF files." -ForegroundColor Green

            # Also set via registry for current user
            $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice"
            if (Test-Path $regPath) {
                Remove-Item $regPath -Force -ErrorAction SilentlyContinue
            }

            # Set default program association
            $regPath2 = "HKCU:\Software\Classes\.pdf"
            if (-not (Test-Path $regPath2)) {
                New-Item -Path $regPath2 -Force | Out-Null
            }
            Set-ItemProperty -Path $regPath2 -Name "(Default)" -Value "AcroExch.Document.DC" -Force

            Write-Host "  PDF file associations updated successfully." -ForegroundColor Green
            return $true
        }
        catch {
            Write-Host "  Partial success - some associations may require manual confirmation." -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "  Failed to set Adobe Reader as default: $_" -ForegroundColor Red
        return $false
    }
}

# Main execution
try {
    Show-Header

    # Check for winget
    if (-not (Test-WingetInstalled)) {
        Install-Winget
    }
    else {
        Write-Host "Windows Package Manager (winget) is installed." -ForegroundColor Green
        Write-Host ""
    }

    # Get user selections
    $selectedPackages = Get-SoftwareSelections

    # Confirm installation
    if ($selectedPackages.Count -gt 0) {
        Show-Header
        Write-Host "You selected the following software:" -ForegroundColor Cyan
        Write-Host ""
        foreach ($pkg in $selectedPackages) {
            Write-Host "  - $($pkg.Name)" -ForegroundColor White
        }
        Write-Host ""
        Write-Host -NoNewline "Proceed with installation? (Y/N): " -ForegroundColor Yellow
        $confirm = Read-Host

        if ($confirm -eq 'Y' -or $confirm -eq 'y') {
            Show-Header
            $installResults = Install-SelectedSoftware -Packages $selectedPackages

            # Check if Chrome or Adobe Reader were installed and offer to set as default
            $installedNames = $installResults | Where-Object { $_.Status -eq "Success" } | Select-Object -ExpandProperty Name

            # Set Chrome as default browser if installed
            if ($installedNames -contains "Google Chrome") {
                Write-Host ""
                Write-Host -NoNewline "Set Chrome as default browser? (Y/N): " -ForegroundColor Cyan
                $setChromeDefault = Read-Host
                if ($setChromeDefault -eq 'Y' -or $setChromeDefault -eq 'y') {
                    Set-ChromeAsDefaultBrowser
                }
            }

            # Set Adobe Reader as default PDF viewer if installed
            if ($installedNames -contains "Adobe Acrobat Reader") {
                Write-Host ""
                Write-Host -NoNewline "Set Adobe Reader as default PDF viewer? (Y/N): " -ForegroundColor Cyan
                $setAdobeDefault = Read-Host
                if ($setAdobeDefault -eq 'Y' -or $setAdobeDefault -eq 'y') {
                    Set-AdobeAsDefaultPDF
                }
            }
        }
        else {
            Write-Host "Installation cancelled." -ForegroundColor Yellow
        }
    }
}
catch {
    Write-Host "An error occurred: $_" -ForegroundColor Red
}

Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
