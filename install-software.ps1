#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Silently installs Google Chrome, Zoom, and Adobe Reader
.DESCRIPTION
    Downloads and installs the latest versions of Google Chrome, Zoom, and Adobe Acrobat Reader silently
.NOTES
    Must be run as Administrator
#>

Write-Host "Starting silent installation of Google Chrome, Zoom, and Adobe Reader..." -ForegroundColor Cyan

# Create temp directory for downloads
$tempDir = "$env:TEMP\SoftwareInstall"
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

# Function to download files
function Download-File {
    param (
        [string]$Url,
        [string]$Output
    )
    try {
        Write-Host "Downloading from $Url..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $Url -OutFile $Output -UseBasicParsing -ErrorAction Stop
        Write-Host "Downloaded to $Output" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Failed to download from $Url : $_" -ForegroundColor Red
        return $false
    }
}

# Function to install software
function Install-Software {
    param (
        [string]$InstallerPath,
        [string]$Arguments,
        [string]$SoftwareName
    )
    try {
        Write-Host "Installing $SoftwareName..." -ForegroundColor Yellow
        $process = Start-Process -FilePath $InstallerPath -ArgumentList $Arguments -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -eq 0) {
            Write-Host "$SoftwareName installed successfully!" -ForegroundColor Green
            return $true
        }
        else {
            Write-Host "$SoftwareName installation completed with exit code: $($process.ExitCode)" -ForegroundColor Yellow
            return $true
        }
    }
    catch {
        Write-Host "Failed to install $SoftwareName : $_" -ForegroundColor Red
        return $false
    }
}

# Google Chrome
Write-Host "`n=== Installing Google Chrome ===" -ForegroundColor Cyan
$chromeInstaller = "$tempDir\chrome_installer.exe"
$chromeUrl = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
if (Download-File -Url $chromeUrl -Output $chromeInstaller) {
    Install-Software -InstallerPath $chromeInstaller -Arguments "/silent /install" -SoftwareName "Google Chrome"
}

# Zoom
Write-Host "`n=== Installing Zoom ===" -ForegroundColor Cyan
$zoomInstaller = "$tempDir\ZoomInstaller.msi"
$zoomUrl = "https://zoom.us/client/latest/ZoomInstallerFull.msi"
if (Download-File -Url $zoomUrl -Output $zoomInstaller) {
    Install-Software -InstallerPath "msiexec.exe" -Arguments "/i `"$zoomInstaller`" /quiet /norestart" -SoftwareName "Zoom"
}

# Adobe Acrobat Reader
Write-Host "`n=== Installing Adobe Acrobat Reader ===" -ForegroundColor Cyan
$adobeInstaller = "$tempDir\AcroRdrDC.exe"
# Adobe Reader DC latest version download URL
$adobeUrl = "https://ardownload2.adobe.com/pub/adobe/reader/win/AcrobatDC/2300820555/AcroRdrDC2300820555_en_US.exe"
if (Download-File -Url $adobeUrl -Output $adobeInstaller) {
    Install-Software -InstallerPath $adobeInstaller -Arguments "/sAll /rs /msi EULA_ACCEPT=YES" -SoftwareName "Adobe Acrobat Reader"
}

# Cleanup
Write-Host "`n=== Cleaning up temporary files ===" -ForegroundColor Cyan
try {
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cleanup completed!" -ForegroundColor Green
}
catch {
    Write-Host "Could not remove temp directory: $_" -ForegroundColor Yellow
}

Write-Host "`nAll installations completed!" -ForegroundColor Green
Write-Host "You may need to restart your computer for changes to take full effect." -ForegroundColor Yellow
