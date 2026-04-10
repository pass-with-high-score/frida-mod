#!/bin/bash

# ==============================================================================
# iOS Reverse Engineering Toolkit - macOS Setup
#
# Installs all tools needed for Frida-based analysis, Dobby hooking,
# IPA dumping/injection, and Theos tweak development.
#
# Usage:
#   bash install_frida_macos.sh              # Install everything (latest frida)
#   bash install_frida_macos.sh 16.7.19      # Install with specific frida version
# ==============================================================================

set -e

echo "=============================================="
echo " iOS RE Toolkit - macOS Installer"
echo "=============================================="
echo ""

# ==============================================================================
# 1. Homebrew
# ==============================================================================
echo "[1/8] Homebrew..."
if ! command -v brew &> /dev/null; then
    echo "  -> Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "  -> OK ($(brew --version | head -1))"
fi

# ==============================================================================
# 2. Python + pipx + frida-tools
# ==============================================================================
echo "[2/8] Frida tools (frida, frida-ps, frida-trace, frida-ls-devices)..."
if ! command -v pipx &> /dev/null; then
    echo "  -> Installing pipx..."
    brew install pipx
    pipx ensurepath
fi

FRIDA_VERSION="$1"
if ! command -v frida &> /dev/null; then
    if [ -z "$FRIDA_VERSION" ]; then
        echo "  -> Installing frida-tools (latest)..."
        pipx install frida-tools
    else
        echo "  -> Installing frida-tools (frida core $FRIDA_VERSION)..."
        pipx install frida-tools
        pipx runpip frida-tools install "frida==$FRIDA_VERSION"
    fi
else
    echo "  -> OK ($(frida --version 2>/dev/null || echo 'installed'))"
fi

# ==============================================================================
# 3. Node.js + npm (for bagbak IPA dumper)
# ==============================================================================
echo "[3/8] Node.js + npm..."
if ! command -v node &> /dev/null; then
    echo "  -> Installing Node.js..."
    brew install node
else
    echo "  -> OK (node $(node --version))"
fi

# ==============================================================================
# 4. bagbak (IPA dumper using Frida)
# ==============================================================================
echo "[4/8] bagbak (IPA dumper)..."
if ! npm list -g bagbak &> /dev/null; then
    echo "  -> Installing bagbak..."
    npm install -g bagbak
else
    echo "  -> OK"
fi

# ==============================================================================
# 5. cmake (for building Dobby from source)
# ==============================================================================
echo "[5/8] cmake..."
if ! command -v cmake &> /dev/null; then
    echo "  -> Installing cmake..."
    brew install cmake
else
    echo "  -> OK ($(cmake --version | head -1))"
fi

# ==============================================================================
# 6. iproxy (USB SSH tunnel to iOS device)
# ==============================================================================
echo "[6/8] iproxy (USB SSH tunnel)..."
if ! command -v iproxy &> /dev/null; then
    echo "  -> Installing libusbmuxd..."
    brew install libusbmuxd
else
    echo "  -> OK"
fi

# ==============================================================================
# 7. insert_dylib (inject LC_LOAD_DYLIB into Mach-O binaries)
# ==============================================================================
echo "[7/8] insert_dylib..."
if ! command -v insert_dylib &> /dev/null && [ ! -f "$HOME/bin/insert_dylib" ]; then
    echo "  -> Building from source..."
    TMPDIR_INSERT=$(mktemp -d)
    git clone https://github.com/tyilo/insert_dylib.git "$TMPDIR_INSERT/insert_dylib" 2>/dev/null
    cd "$TMPDIR_INSERT/insert_dylib"
    xcodebuild -project insert_dylib.xcodeproj -scheme insert_dylib \
        -configuration Release SYMROOT=build 2>&1 | tail -3
    mkdir -p "$HOME/bin"
    cp build/Release/insert_dylib "$HOME/bin/"
    cd - > /dev/null
    rm -rf "$TMPDIR_INSERT"

    # Add ~/bin to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
        echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
        echo "  -> Added ~/bin to PATH in ~/.zshrc"
    fi
    echo "  -> Installed to ~/bin/insert_dylib"
else
    echo "  -> OK"
fi

# ==============================================================================
# 8. Dobby (build iOS arm64 static library)
# ==============================================================================
echo "[8/8] Dobby (iOS arm64 hooking framework)..."
DOBBY_OUT="$HOME/ios-re-libs/dobby"
if [ ! -f "$DOBBY_OUT/libdobby.a" ]; then
    echo "  -> Cloning and building Dobby..."
    TMPDIR_DOBBY=$(mktemp -d)
    git clone https://github.com/jmpews/Dobby.git "$TMPDIR_DOBBY/Dobby" 2>/dev/null
    mkdir -p "$TMPDIR_DOBBY/Dobby/build_ios"
    cd "$TMPDIR_DOBBY/Dobby/build_ios"
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_SYSTEM_NAME=iOS \
        -DCMAKE_OSX_ARCHITECTURES=arm64 \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=15.0 \
        -DCMAKE_SYSTEM_PROCESSOR=arm64 \
        2>&1 | tail -3
    make -j$(sysctl -n hw.ncpu) 2>&1 | tail -3
    mkdir -p "$DOBBY_OUT"
    cp libdobby.a "$DOBBY_OUT/"
    cp ../include/dobby.h "$DOBBY_OUT/"
    cd - > /dev/null
    rm -rf "$TMPDIR_DOBBY"
    echo "  -> Installed to $DOBBY_OUT/"
else
    echo "  -> OK ($DOBBY_OUT/libdobby.a)"
fi

# ==============================================================================
# Summary
# ==============================================================================
echo ""
echo "=============================================="
echo " Installation Complete"
echo "=============================================="
echo ""
echo " Tools installed:"
echo "   frida, frida-ps, frida-trace, frida-ls-devices"
echo "   bagbak (IPA dumper)"
echo "   cmake"
echo "   iproxy (USB SSH)"
echo "   insert_dylib (Mach-O injector)"
echo "   Dobby (iOS arm64 hooking lib at $DOBBY_OUT/)"
echo ""
echo " Usage examples:"
echo "   frida-ps -U                          # List processes on USB device"
echo "   frida -U -p <PID> -l hook.js         # Attach and load script"
echo "   bagbak -U -o ./ipa <bundle-id>       # Dump decrypted IPA"
echo "   iproxy 2222 22                        # SSH tunnel over USB"
echo "   ssh -p 2222 mobile@localhost          # SSH into device"
echo ""
echo " Restart terminal or run: source ~/.zshrc"
echo ""
