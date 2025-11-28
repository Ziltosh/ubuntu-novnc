#!/bin/sh

# Configuration variables
mt5file='/home/user/.wine/drive_c/Program Files/MetaTrader 5/terminal64.exe'
WINEPREFIX='/home/user/.wine'
WINEDEBUG='-all'
wine_executable="wine"
mono_url="https://dl.winehq.org/wine/wine-mono/10.3.0/wine-mono-10.3.0-x86.msi"
mt5setup_url="https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe"
mt5tester_url="https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5tester.setup.exe"

# Export Wine environment variables
export WINEPREFIX
export WINEDEBUG
export XDG_RUNTIME_DIR="/tmp/runtime-root"
export DISPLAY=":0"

# Function to display a message
show_message() {
    echo "$1"
}

# Initialize Wine prefix and create necessary directories
show_message "[1/4] Initializing Wine prefix..."
mkdir -p "$XDG_RUNTIME_DIR"
mkdir -p "$WINEPREFIX/drive_c"
# Initialize Wine prefix silently (creates necessary structure)
$wine_executable wineboot --init 2>/dev/null || true
sleep 5

# Install Mono if not present
if [ ! -e "$WINEPREFIX/drive_c/windows/mono" ]; then
    show_message "[2/4] Downloading and installing Mono..."
    curl -o "$WINEPREFIX/drive_c/mono.msi" "$mono_url"
    if [ -f "$WINEPREFIX/drive_c/mono.msi" ]; then
        WINEDLLOVERRIDES=mscoree=d $wine_executable msiexec /i "$WINEPREFIX/drive_c/mono.msi" /qn 2>/dev/null || true
        rm -f "$WINEPREFIX/drive_c/mono.msi"
        show_message "[2/4] Mono installed."
    else
        show_message "[2/4] Failed to download Mono, skipping..."
    fi
else
    show_message "[2/4] Mono is already installed."
fi

# Check if MetaTrader 5 is already installed
if [ -e "$mt5file" ]; then
    show_message "[3/5] MetaTrader 5 is already installed."
else
    show_message "[3/5] Installing MetaTrader 5..."

    # Set Windows 10 mode in Wine
    $wine_executable reg add "HKEY_CURRENT_USER\\Software\\Wine" /v Version /t REG_SZ /d "win10" /f 2>/dev/null || true

    # Download MT5 installer and tester
    curl -o "$WINEPREFIX/drive_c/mt5setup.exe" "$mt5setup_url"
    curl -o "$WINEPREFIX/drive_c/mt5tester.setup.exe" "$mt5tester_url"

    # Run MT5 installer
    $wine_executable "$WINEPREFIX/drive_c/mt5setup.exe" "/auto" 2>/dev/null || true

    # Wait for installation to complete
    sleep 30

    # Run MT5 Tester installer
    show_message "[4/5] Installing MT5 Tester..."
    $wine_executable "$WINEPREFIX/drive_c/mt5tester.setup.exe" "/auto" 2>/dev/null || true

    # Wait for tester installation to complete
    sleep 30

    # Clean up installers
    rm -f "$WINEPREFIX/drive_c/mt5setup.exe"
    rm -f "$WINEPREFIX/drive_c/mt5tester.setup.exe"
fi

# Launch MetaTrader 5
if [ -e "$mt5file" ]; then
    show_message "[5/5] Launching MetaTrader 5..."
    $wine_executable "$mt5file" &
else
    show_message "[5/5] MetaTrader 5 installation failed."
fi
