# Islands Dark Theme Bootstrap Installer for Windows
# VS Code one-liner: irm https://raw.githubusercontent.com/bwya77/vscode-dark-islands/main/bootstrap.ps1 | iex
# Cursor one-liner: iex "& { $(irm https://raw.githubusercontent.com/bwya77/vscode-dark-islands/main/bootstrap.ps1) } -Target Cursor"

param(
    [ValidateSet("Auto", "VSCode", "Cursor")]
    [string]$Target = "Auto"
)

$ErrorActionPreference = "Stop"

echo "🏝️  Islands Dark Theme Bootstrap Installer"
echo "=========================================="
echo ""

$RepoUrl = "https://github.com/bwya77/vscode-dark-islands.git"
$Branch = "main"
$InstallDir = "$env:TEMP\islands-dark-temp"

echo "📥 Step 1: Downloading Islands Dark..."
echo "   Repository: $RepoUrl"

# Remove old temp directory if exists
if (Test-Path $InstallDir) {
    Remove-Item -Recurse -Force $InstallDir
}

# Clone repository
try {
    git clone $RepoUrl $InstallDir --quiet --branch $Branch
} catch {
    echo "❌ Failed to download Islands Dark"
    echo "   Make sure Git is installed: https://git-scm.com/download/win"
    exit 1
}

echo "✓ Downloaded successfully"
echo ""

echo "🚀 Step 2: Running installer..."
echo ""

# Run installer
cd $InstallDir
try {
    .\install.ps1 -Target $Target
} catch {
    echo "❌ Installation failed"
    echo $_.Exception.Message
    exit 1
}

# Cleanup
echo ""
echo "🧹 Step 3: Cleaning up..."
$remove = Read-Host "   Remove temporary files? (y/n)"
if ($remove -eq 'y' -or $remove -eq 'Y') {
    Remove-Item -Recurse -Force $InstallDir
    echo "✓ Temporary files removed"
} else {
    echo "   Files kept at: $InstallDir"
}

echo ""
echo "🎉 Done! Enjoy your Islands Dark theme!"
