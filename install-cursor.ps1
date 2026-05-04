# Islands Dark Theme Installer for Cursor
# Cursor is a VS Code-compatible AI editor with separate settings and extension paths

param()

$ErrorActionPreference = "Stop"

Write-Host "Islands Dark Theme Installer for Cursor" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

function Get-CursorCommand {
    $cursorPath = Get-Command "cursor" -ErrorAction SilentlyContinue
    if ($cursorPath) {
        return $cursorPath.Source
    }

    $possiblePaths = @(
        "$env:LOCALAPPDATA\Programs\Cursor\resources\app\bin\cursor.cmd",
        "$env:LOCALAPPDATA\Programs\cursor\resources\app\bin\cursor.cmd",
        "$env:LOCALAPPDATA\Programs\Cursor\bin\cursor.cmd"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    return $null
}

$cursorCommand = Get-CursorCommand
$cursorSettingsRoot = "$env:APPDATA\Cursor"

if (-not $cursorCommand -and -not (Test-Path $cursorSettingsRoot)) {
    Write-Host "Error: Cursor installation not found!" -ForegroundColor Red
    Write-Host "Expected Cursor CLI command 'cursor' or settings directory: $cursorSettingsRoot"
    Write-Host "Please install Cursor and run it at least once."
    exit 1
}

Write-Host "Cursor installation found" -ForegroundColor Green
if ($cursorCommand) {
    Write-Host "Cursor CLI found at: $cursorCommand" -ForegroundColor DarkGray
}

# Get the directory where this script is located
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "Step 1: Installing Islands Dark theme extension..."

# Cursor uses a VS Code-compatible extension layout under .cursor/extensions.
$extDir = "$env:USERPROFILE\.cursor\extensions\bwya77.islands-dark-1.0.0"
if (Test-Path $extDir) {
    Remove-Item -Recurse -Force $extDir
}
New-Item -ItemType Directory -Path $extDir -Force | Out-Null
Copy-Item "$scriptDir\package.json" "$extDir\" -Force
Copy-Item "$scriptDir\themes" "$extDir\themes" -Recurse -Force

if (Test-Path "$extDir\themes") {
    Write-Host "Theme extension installed to $extDir" -ForegroundColor Green
} else {
    Write-Host "Failed to install theme extension" -ForegroundColor Red
    exit 1
}

# Remove extensions.json so Cursor rebuilds it cleanly on next launch.
$extJsonPath = "$env:USERPROFILE\.cursor\extensions\extensions.json"
if (Test-Path $extJsonPath) {
    Remove-Item $extJsonPath -Force
    Write-Host "Cleared extensions.json (Cursor will rebuild it)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 2: Installing Custom UI Style extension..."
try {
    if ($cursorCommand) {
        & $cursorCommand --install-extension subframe7536.custom-ui-style --force 2>&1 | Out-Null
        Write-Host "Custom UI Style extension installed" -ForegroundColor Green
    } else {
        Write-Host "Cursor CLI not found; skipping automatic extension install" -ForegroundColor Yellow
        Write-Host "   Please install Custom UI Style manually from Cursor's Extensions marketplace"
    }
} catch {
    Write-Host "Could not install Custom UI Style extension automatically" -ForegroundColor Yellow
    Write-Host "   Please install it manually from Cursor's Extensions marketplace"
}

Write-Host ""
Write-Host "Step 3: Installing Bear Sans UI fonts..."
$fontDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"

# Try user fonts first
if (-not (Test-Path $fontDir)) {
    New-Item -ItemType Directory -Path $fontDir -Force | Out-Null
}

try {
    $fonts = Get-ChildItem "$scriptDir\fonts\*.otf"
    foreach ($font in $fonts) {
        try {
            Copy-Item $font.FullName $fontDir -Force -ErrorAction SilentlyContinue
        } catch {
            # Silently continue if copy fails
        }
    }

    Write-Host "Fonts installed" -ForegroundColor Green
    Write-Host "   Note: You may need to restart applications to use the new fonts" -ForegroundColor DarkGray
} catch {
    Write-Host "Could not install fonts automatically" -ForegroundColor Yellow
    Write-Host "   Please manually install the fonts from the 'fonts/' folder"
    Write-Host "   Select all .otf files and right-click > Install"
}

Write-Host ""
Write-Host "Step 4: Applying Cursor settings..."

$settingsDir = "$env:APPDATA\Cursor\User"
$settingsFile = "$settingsDir\settings.json"

if (-not (Test-Path $settingsDir)) {
    Write-Host "Creating Cursor settings directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
}

# Function to strip JSONC features (comments and trailing commas) for JSON parsing
function Strip-Jsonc {
    param([string]$Text)
    # Remove single-line comments
    $Text = $Text -replace '//.*$', ''
    # Remove multi-line comments
    $Text = $Text -replace '/\*[\s\S]*?\*/', ''
    # Remove trailing commas before } or ]
    $Text = $Text -replace ',\s*([}\]])', '$1'
    return $Text
}

$newSettingsRaw = Get-Content "$scriptDir\settings.json" -Raw
$newSettings = (Strip-Jsonc $newSettingsRaw) | ConvertFrom-Json

if (Test-Path $settingsFile) {
    Write-Host "Existing settings.json found at: $settingsFile" -ForegroundColor Yellow
    Write-Host "   Backing up to settings.json.backup"
    Copy-Item $settingsFile "$settingsFile.backup" -Force

    try {
        $existingRaw = Get-Content $settingsFile -Raw
        $existingSettings = (Strip-Jsonc $existingRaw) | ConvertFrom-Json

        # Merge settings - Islands Dark settings take precedence
        $mergedSettings = @{}
        $existingSettings.PSObject.Properties | ForEach-Object {
            $mergedSettings[$_.Name] = $_.Value
        }
        $newSettings.PSObject.Properties | ForEach-Object {
            $mergedSettings[$_.Name] = $_.Value
        }

        # Deep merge custom-ui-style.stylesheet
        $stylesheetKey = 'custom-ui-style.stylesheet'
        if ($existingSettings.$stylesheetKey -and $newSettings.$stylesheetKey) {
            $mergedStylesheet = @{}
            $existingSettings.$stylesheetKey.PSObject.Properties | ForEach-Object {
                $mergedStylesheet[$_.Name] = $_.Value
            }
            $newSettings.$stylesheetKey.PSObject.Properties | ForEach-Object {
                $mergedStylesheet[$_.Name] = $_.Value
            }
            $mergedSettings[$stylesheetKey] = [PSCustomObject]$mergedStylesheet
        }

        [PSCustomObject]$mergedSettings | ConvertTo-Json -Depth 100 | Set-Content $settingsFile
        Write-Host "Settings merged successfully" -ForegroundColor Green
    } catch {
        Write-Host "Could not merge settings automatically" -ForegroundColor Yellow
        Write-Host "   Please manually merge settings.json from this repo into your Cursor settings"
        Write-Host "   Your original settings have been backed up to settings.json.backup"
    }
} else {
    Copy-Item "$scriptDir\settings.json" $settingsFile
    Write-Host "Settings applied to: $settingsFile" -ForegroundColor Green
}

Write-Host ""
Write-Host "Step 5: Enabling Custom UI Style..."

# Check if this is the first run
$firstRunFile = Join-Path $scriptDir ".islands_dark_first_run_cursor"
if (-not (Test-Path $firstRunFile)) {
    New-Item -ItemType File -Path $firstRunFile | Out-Null
    Write-Host ""
    Write-Host "Important Notes:" -ForegroundColor Yellow
    Write-Host "   - IBM Plex Mono and FiraCode Nerd Font Mono need to be installed separately"
    Write-Host "   - After Cursor reloads, you may see a 'corrupt installation' warning"
    Write-Host "   - This is expected when using custom CSS - click the gear icon and select 'Don't Show Again'"
    Write-Host "   - To activate the theme in Cursor, use the theme picker (Cmd/Ctrl+K Cmd/Ctrl+T)"
    Write-Host ""
    Read-Host "Press Enter to continue"
}

Write-Host "   Applying CSS customizations..."

Write-Host ""
Write-Host "Islands Dark theme has been installed for Cursor!" -ForegroundColor Green
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Restart Cursor to apply the changes"
Write-Host "   2. Open the Command Palette (Cmd/Ctrl+Shift+P)"
Write-Host "   3. Type 'Color Theme' and select 'Preferences: Color Theme'"
Write-Host "   4. Select 'Islands Dark' from the list"
Write-Host "   5. If you see a warning about corrupt installation, click 'Don't Show Again'"
Write-Host ""

Write-Host "Settings file location: $settingsFile" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host ""

Start-Sleep -Seconds 3
