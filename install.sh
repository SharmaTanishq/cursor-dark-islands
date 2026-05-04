#!/bin/bash

set -e


echo "🏝️  Islands Dark Theme Installer for macOS/Linux"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TARGET="auto"
case "${1:-}" in
    --cursor)
        TARGET="cursor"
        ;;
    --vscode|--code)
        TARGET="vscode"
        ;;
    "" )
        ;;
    * )
        echo -e "${RED}❌ Unknown option: $1${NC}"
        echo "Usage: ./install.sh [--cursor|--vscode]"
        exit 1
        ;;
esac

HAS_CURSOR=false
HAS_CODE=false
command -v cursor &> /dev/null && HAS_CURSOR=true
command -v code &> /dev/null && HAS_CODE=true

if [[ "$TARGET" == "auto" ]]; then
    if [[ "$HAS_CURSOR" == true && "$HAS_CODE" != true ]]; then
        TARGET="cursor"
    else
        TARGET="vscode"
    fi
fi

if [[ "$TARGET" == "cursor" ]]; then
    APP_NAME="Cursor"
    CLI_CMD="cursor"
    EXT_ROOT="$HOME/.cursor/extensions"
    FIRST_RUN_SUFFIX="cursor"
else
    APP_NAME="VS Code"
    CLI_CMD="code"
    EXT_ROOT="$HOME/.vscode/extensions"
    FIRST_RUN_SUFFIX="vscode"
fi

# Check if the selected editor CLI is available
if ! command -v "$CLI_CMD" &> /dev/null; then
    echo -e "${RED}❌ Error: $APP_NAME CLI ($CLI_CMD) not found!${NC}"
    echo "Please install $APP_NAME and make sure '$CLI_CMD' command is in your PATH."
    echo "You can do this from $APP_NAME's Command Palette:"
    echo "  Shell Command: Install '$CLI_CMD' command in PATH"
    if [[ "$TARGET" == "vscode" && "$HAS_CURSOR" == true ]]; then
        echo "Or run this installer for Cursor with: ./install.sh --cursor"
    fi
    exit 1
fi

echo -e "${GREEN}✓ $APP_NAME CLI found${NC}"

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo ""
echo "📦 Step 1: Installing Islands Dark theme extension..."

# Install by copying to the selected editor's extensions directory
EXT_DIR="$EXT_ROOT/bwya77.islands-dark-1.0.0"
rm -rf "$EXT_DIR"
mkdir -p "$EXT_DIR"
cp "$SCRIPT_DIR/package.json" "$EXT_DIR/"
cp -r "$SCRIPT_DIR/themes" "$EXT_DIR/"

if [ -d "$EXT_DIR/themes" ]; then
    echo -e "${GREEN}✓ Theme extension installed to $EXT_DIR${NC}"
else
    echo -e "${RED}❌ Failed to install theme extension${NC}"
    exit 1
fi

# Remove extensions.json so the selected editor rebuilds it cleanly on next launch
# (previous versions of this script wrote invalid content to this file)
EXT_JSON="$EXT_ROOT/extensions.json"
if [ -f "$EXT_JSON" ]; then
    rm -f "$EXT_JSON"
    echo -e "${GREEN}✓ Cleared extensions.json ($APP_NAME will rebuild it)${NC}"
fi

echo ""
echo "🔧 Step 2: Installing Custom UI Style extension..."
if "$CLI_CMD" --install-extension subframe7536.custom-ui-style --force; then
    echo -e "${GREEN}✓ Custom UI Style extension installed${NC}"
else
    echo -e "${YELLOW}⚠️  Could not install Custom UI Style extension automatically${NC}"
    echo "   Please install it manually from the Extensions marketplace"
fi

echo ""
echo "🔤 Step 3: Installing Bear Sans UI fonts..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    FONT_DIR="$HOME/Library/Fonts"
    echo "   Installing fonts to: $FONT_DIR"
    cp "$SCRIPT_DIR/fonts/"*.otf "$FONT_DIR/" 2>/dev/null || true
    echo -e "${GREEN}✓ Fonts installed to Font Book${NC}"
    echo "   Note: You may need to restart applications to use the new fonts"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    echo "   Installing fonts to: $FONT_DIR"
    cp "$SCRIPT_DIR/fonts/"*.otf "$FONT_DIR/" 2>/dev/null || true
    fc-cache -f 2>/dev/null || true
    echo -e "${GREEN}✓ Fonts installed${NC}"
else
    echo -e "${YELLOW}⚠️  Could not detect OS type for automatic font installation${NC}"
    echo "   Please manually install the fonts from the 'fonts/' folder"
fi

echo ""
echo "⚙️  Step 4: Applying $APP_NAME settings..."
if [[ "$TARGET" == "cursor" ]]; then
    SETTINGS_DIR="$HOME/.config/Cursor/User"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        SETTINGS_DIR="$HOME/Library/Application Support/Cursor/User"
    fi
else
    SETTINGS_DIR="$HOME/.config/Code/User"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
    fi
fi

mkdir -p "$SETTINGS_DIR"
SETTINGS_FILE="$SETTINGS_DIR/settings.json"

# Backup existing settings if they exist
if [ -f "$SETTINGS_FILE" ]; then
    BACKUP_FILE="$SETTINGS_FILE.pre-islands-dark"
    cp "$SETTINGS_FILE" "$BACKUP_FILE"
    echo -e "${YELLOW}⚠️  Existing settings.json backed up to:${NC}"
    echo "   $BACKUP_FILE"
    echo "   You can restore your old settings from this file if needed."
fi

# Copy Islands Dark settings
cp "$SCRIPT_DIR/settings.json" "$SETTINGS_FILE"
echo -e "${GREEN}✓ Islands Dark settings applied${NC}"

echo ""
echo "🚀 Step 5: Enabling Custom UI Style..."
echo "   $APP_NAME will reload after applying changes..."

# Create a flag file to indicate first run
FIRST_RUN_FILE="$SCRIPT_DIR/.islands_dark_first_run_$FIRST_RUN_SUFFIX"
if [ ! -f "$FIRST_RUN_FILE" ]; then
    touch "$FIRST_RUN_FILE"
    echo ""
    echo -e "${YELLOW}📝 Important Notes:${NC}"
    echo "   • IBM Plex Mono and FiraCode Nerd Font Mono need to be installed separately"
    echo "   • After $APP_NAME reloads, you may see a 'corrupt installation' warning"
    echo "   • This is expected - click the gear icon and select 'Don't Show Again'"
    echo ""
    if [ -t 0 ]; then
        read -p "Press Enter to continue and reload $APP_NAME..."
    fi
fi

# Apply custom UI style
echo "   Applying CSS customizations..."

# Reload VS Code to apply changes
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo "🎉 Islands Dark theme has been installed!"
echo "   $APP_NAME will now reload to apply the custom UI style."
echo ""

# Use AppleScript on macOS to show a notification and reload the editor
if [[ "$OSTYPE" == "darwin"* ]]; then
    osascript -e 'display notification "Islands Dark theme installed successfully!" with title "🏝️ Islands Dark"' 2>/dev/null || true
fi

echo "   Reloading $APP_NAME..."
"$CLI_CMD" --reload-window 2>/dev/null || "$CLI_CMD" . 2>/dev/null || true

echo ""
echo -e "${GREEN}Done! 🏝️${NC}"
