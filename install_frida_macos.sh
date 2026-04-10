#!/bin/bash

# ==============================================================================
# Frida installation script for macOS
# This script uses pipx to safely install frida-tools globally without breaking
# macOS system Python packages (PEP 668 compliant).
# ==============================================================================

set -e

echo "[*] Bắt đầu quá trình cài đặt Frida cho macOS..."

# Kiểm tra Homebrew
if ! command -v brew &> /dev/null; then
    echo "[!] Không tìm thấy Homebrew. Đang tiến hành cài đặt Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "[✓] Homebrew đã được cài đặt."
fi

# Cài đặt pipx nếu chưa có
if ! command -v pipx &> /dev/null; then
    echo "[*] Đang cài đặt pipx qua Homebrew..."
    brew install pipx
    pipx ensurepath
else
    echo "[✓] pipx đã được cài đặt."
fi

# Cài đặt frida-tools
VERSION="$1"
if [ -z "$VERSION" ]; then
    echo "[*] Đang cài đặt frida-tools (phiên bản mới nhất) qua pipx..."
    pipx install frida-tools
else
    echo "[*] Đang cài đặt frida-tools và ép phiên bản Frida core thành: $VERSION"
    pipx install frida-tools
    # Dùng runpip để ghi đè phiên bản frida core bên trong môi trường ảo của pipx
    pipx runpip frida-tools install "frida==$VERSION"
fi

echo ""
echo "[✓] Cài đặt hoàn tất!"
echo "[i] Vui lòng KHỞI ĐỘNG LẠI TERMINAL (hoặc chạy lệnh: source ~/.zshrc) để các lệnh có hiệu lực."
echo "[i] Sau đó, bạn có thể kiểm tra bằng lệnh: frida --version"
