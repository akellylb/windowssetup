# Windows Setup Script

Interactive software installer using Windows Package Manager (Winget).

## Quick Install

Run this command in PowerShell (as Administrator):

```powershell
iwr -useb https://setup.longbranchit.org/setup.ps1 | iex
```

## Features

- **Interactive Menu** - Choose which applications to install
- **30+ Popular Apps** - Browsers, productivity tools, dev tools, and more
- **Auto-Configure** - Set Chrome as default browser, Adobe as default PDF viewer
- **Silent Installation** - All installs run without prompts
- **TeamViewer Support** - Direct download from get.teamviewer.com/longbranch

## Available Software

### Browsers
- Google Chrome
- Mozilla Firefox
- Brave Browser

### Communication
- Zoom
- Microsoft Teams
- Slack
- Discord

### Productivity
- Adobe Acrobat Reader
- LibreOffice
- Notion
- Obsidian

### Development
- Visual Studio Code
- Git
- GitHub Desktop
- Python 3
- Node.js LTS
- Notepad++
- Windows Terminal

### Utilities
- 7-Zip
- WinRAR
- PowerToys
- Everything (File Search)
- TreeSize Free

### Media
- VLC Media Player
- Spotify
- OBS Studio

### Remote Access
- TeamViewer
- AnyDesk

## Manual Usage

1. Download `setup.ps1`
2. Right-click PowerShell → Run as Administrator
3. Navigate to the download folder
4. Run: `.\setup.ps1`

## Requirements

- Windows 10/11
- PowerShell
- Administrator privileges
- Windows Package Manager (winget) - auto-installed if missing

## License

Free to use and modify.
