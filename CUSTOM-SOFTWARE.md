# Custom Software Guide

This guide explains how to add your own custom software to the installer using Cloudflare R2.

## Setup Cloudflare R2 (Private + Authenticated)

### Step 1: Create Private R2 Bucket

1. **Create R2 Bucket:**
   - Go to https://dash.cloudflare.com
   - Click **R2** → **Create bucket**
   - Name it: `software`
   - Click **Create bucket**

2. **Keep it PRIVATE:**
   - **DO NOT enable public access** ✅
   - Files will only be accessible via authenticated Worker

### Step 2: Deploy Password-Protected Worker

1. **Create Worker:**
   - Go to **Workers & Pages** → **Create Worker**
   - Name it: `downloads` or `software-auth`
   - Click **Deploy**

2. **Add Worker Code:**
   - Click **Edit Code**
   - Delete default code
   - Paste code from `r2-auth-worker.js`
   - **Line 8:** Change password to something secure
     ```javascript
     const PASSWORD = "YourSecurePassword123!";
     ```
   - Click **Save and Deploy**

3. **Bind R2 Bucket:**
   - Go to Worker **Settings** → **Variables**
   - Scroll to **R2 Bucket Bindings**
   - Click **Add binding**
     - Variable name: `R2_BUCKET`
     - R2 bucket: `software`
   - Click **Save**

4. **Get Worker URL:**
   - Copy your Worker URL (e.g., `https://downloads.YOUR-ACCOUNT.workers.dev`)

### Step 3: Update setup.ps1

Edit `setup.ps1` lines 50-51:

```powershell
$R2_BASE_URL = "https://downloads.YOUR-ACCOUNT.workers.dev"
$R2_AUTH_KEY = "YourSecurePassword123!"
```

**Important:** The password is embedded in the script. Keep your GitHub repo **private** if you use sensitive passwords, or use a less sensitive password for internal tools.

## Adding Custom Software

### Step 1: Upload Your Installer to R2

1. Go to your R2 bucket in Cloudflare Dashboard
2. Click **Upload**
3. Upload your `.exe`, `.msi`, or `.ps1` files
4. Note the file name (e.g., `myapp-installer.exe`)

### Step 2: Add to Software Catalog

Edit `setup.ps1` around line 54-58 in the "Custom Software" section:

```powershell
"Custom Software" = @(
    @{
        Name = "My Custom App";
        ID = "CUSTOM_MYAPP";
        URL = "$R2_BASE_URL/myapp-installer.exe?key=$R2_AUTH_KEY";
        Silent = $true;
        SilentArgs = "/S"
    }
    @{
        Name = "Another App";
        ID = "CUSTOM_ANOTHERAPP";
        URL = "$R2_BASE_URL/anotherapp-setup.msi?key=$R2_AUTH_KEY";
        Silent = $true;
        SilentArgs = "/quiet /norestart"
    }
)
```

**Note:** The `?key=$R2_AUTH_KEY` automatically adds authentication to each download URL.

## Software Entry Format

Each software entry needs these fields:

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `Name` | Yes | Display name in menu | `"My Custom App"` |
| `ID` | Yes | Unique ID (must start with `CUSTOM_`) | `"CUSTOM_MYAPP"` |
| `URL` | Yes | Full download URL | `"$R2_BASE_URL/installer.exe"` |
| `Silent` | Yes | Install silently or show UI? | `$true` or `$false` |
| `SilentArgs` | Yes | Silent install arguments | `"/S"` or `"/quiet"` |

## Common Silent Install Arguments

| Installer Type | Silent Args | Example |
|---------------|-------------|---------|
| NSIS (Nullsoft) | `/S` | Most .exe installers |
| Inno Setup | `/VERYSILENT /NORESTART` | Many .exe installers |
| MSI | `/quiet /norestart` | .msi packages |
| InstallShield | `/s /v"/qn"` | Enterprise software |

## File Types Supported

- **`.exe`** - Executable installers (can be silent or interactive)
- **`.msi`** - Windows Installer packages
- **`.ps1`** - PowerShell scripts (always executed directly)

## Examples

### Example 1: Silent EXE Installer
```powershell
@{
    Name = "7-Zip Custom Build";
    ID = "CUSTOM_7ZIP";
    URL = "$R2_BASE_URL/7zip-custom.exe";
    Silent = $true;
    SilentArgs = "/S"
}
```

### Example 2: Interactive MSI
```powershell
@{
    Name = "Company Internal Tool";
    ID = "CUSTOM_INTERNALTOOL";
    URL = "$R2_BASE_URL/internal-tool.msi";
    Silent = $false;
    SilentArgs = ""
}
```

### Example 3: PowerShell Script
```powershell
@{
    Name = "Configuration Script";
    ID = "CUSTOM_CONFIG";
    URL = "$R2_BASE_URL/configure-system.ps1";
    Silent = $false;
    SilentArgs = ""
}
```

### Example 4: From Custom Domain
```powershell
@{
    Name = "My App";
    ID = "CUSTOM_MYAPP";
    URL = "https://files.longbranchit.org/myapp-v2.1.exe";
    Silent = $true;
    SilentArgs = "/VERYSILENT /NORESTART"
}
```

## Testing Your Custom Software

1. **Test the download URL:**
   ```powershell
   Invoke-WebRequest -Uri "YOUR_R2_URL/installer.exe" -OutFile "$env:TEMP\test.exe"
   ```

2. **Test silent install arguments:**
   ```powershell
   Start-Process "$env:TEMP\test.exe" -ArgumentList "/S" -Wait
   ```

3. **Add to script and test:**
   - Edit `setup.ps1`
   - Commit and push to GitHub
   - Wait 30 seconds for Cloudflare Pages to deploy
   - Run: `iwr -useb https://setup.longbranchit.org/setup.ps1 | iex`

## Removing Example Entries

Once you've added your real software, remove the example entries:

```powershell
"Custom Software" = @(
    # Remove these example entries:
    # @{ Name = "Example App 1"; ID = "CUSTOM_APP1"; URL = "$R2_BASE_URL/app1-installer.exe"; Silent = $true; SilentArgs = "/S" }

    # Add your real software here
    @{ Name = "My Real App"; ID = "CUSTOM_REALAPP"; URL = "$R2_BASE_URL/realapp.exe"; Silent = $true; SilentArgs = "/S" }
)
```

## Security Notes

- R2 public buckets are **publicly accessible** - don't upload sensitive software
- Consider adding authentication if needed
- Use versioned filenames for updates (e.g., `myapp-v1.2.exe`)
- Keep installers up to date

## Troubleshooting

**Download fails:**
- Check R2 bucket has public access enabled
- Verify the file exists in R2
- Test URL in browser

**Silent install doesn't work:**
- Try running installer manually with silent args
- Check installer documentation for correct flags
- Set `Silent = $false` to see what happens

**Script execution fails:**
- Ensure PowerShell execution policy allows scripts
- Check script syntax with `Get-Content script.ps1`
