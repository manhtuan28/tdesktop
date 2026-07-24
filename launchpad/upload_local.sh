#!/bin/bash
set -e

# Automatically find GPG key
GPG_KEY=$(gpg --list-secret-keys --with-colons | awk -F: '/^sec:/ { print $5 }' | head -n 1)

if [ -z "$GPG_KEY" ]; then
    echo "Lỗi: Không tìm thấy GPG Key bí mật nào trên máy của bạn!"
    exit 1
fi

echo "Sử dụng GPG Key: $GPG_KEY"

# Prepare variables
VERSION="0.0.0-dev-$(date +%Y%m%d)"
BINARY_PATH="../out/Debug/Telegram"

if [ ! -f "$BINARY_PATH" ]; then
    echo "Không tìm thấy file Telegram tại $BINARY_PATH."
    read -p "Vui lòng nhập đường dẫn tới file Telegram đã build/download: " BINARY_PATH
    if [ ! -f "$BINARY_PATH" ]; then
        echo "Vẫn không tìm thấy file. Dừng."
        exit 1
    fi
fi

# Run the CI script but without batch mode (so it prompts for passphrase if needed)
echo "Đang tạo gói Debian source..."
# Temporary remove the batch mode from ppa_upload_ci.sh for local run
cp launchpad/ppa_upload_ci.sh launchpad/ppa_upload_local_temp.sh
sed -i 's/-p"gpg --batch --pinentry-mode loopback"//g' launchpad/ppa_upload_local_temp.sh

chmod +x launchpad/ppa_upload_local_temp.sh
./launchpad/ppa_upload_local_temp.sh "$VERSION" "$BINARY_PATH" "$GPG_KEY"
rm launchpad/ppa_upload_local_temp.sh

CHANGES_FILE=$(ls launchpad_build/*_source.changes | tail -n 1)

if [ -z "$CHANGES_FILE" ]; then
    echo "Không tạo được file .changes!"
    exit 1
fi

echo "Đã tạo thành công: $CHANGES_FILE"
echo "Đang upload lên Launchpad PPA (ppa:tuancute28/telegram)..."

# Configure dput if needed
if ! grep -q "ppa_telegram" ~/.dput.cf 2>/dev/null; then
    echo "[ppa_telegram]" >> ~/.dput.cf
    echo "fqdn = ppa.launchpad.net" >> ~/.dput.cf
    echo "method = ftp" >> ~/.dput.cf
    echo "incoming = ~tuancute28/ubuntu/telegram/" >> ~/.dput.cf
    echo "login = anonymous" >> ~/.dput.cf
    echo "allow_unsigned_uploads = 0" >> ~/.dput.cf
fi

dput ppa_telegram "$CHANGES_FILE"

echo "Upload hoàn tất!"
