#!/bin/bash
set -e

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <version> <binary_path> <gpg_key_id>"
    echo "Example: $0 7.0.4 out/Release/Telegram B4E8F7726DAE1918924DF426AB5084E43E672D45"
    exit 1
fi

VERSION="$1"
BINARY_PATH="$2"
GPG_KEY="$3"

PKG_NAME="telegram-desktop"
DEB_VERSION="${VERSION}-1ppa2"
PPA_URL="ppa:tuancute28/telegram"
EMAIL="buimanhtuan2k4@gmail.com"
AUTHOR="Manh Tuan"

DIR="launchpad_build"
BUILD_DIR="${DIR}/${PKG_NAME}-${VERSION}"

if [ ! -f "$BINARY_PATH" ]; then
    echo "Error: Binary $BINARY_PATH not found."
    exit 1
fi

mkdir -p "$BUILD_DIR"

# Copy binary
cp "$BINARY_PATH" "$BUILD_DIR/Telegram"

# Copy resources
cp lib/xdg/org.telegram.desktop.desktop "$BUILD_DIR/org.telegram.desktop.desktop"
cp Telegram/Resources/art/icon256.png "$BUILD_DIR/telegram.png"

# Create orig tarball
cd "$DIR"
tar -czf "${PKG_NAME}_${VERSION}.orig.tar.gz" "${PKG_NAME}-${VERSION}"
cd ..

# Create debian directory
mkdir -p "$BUILD_DIR/debian"
mkdir -p "$BUILD_DIR/debian/source"

# debian/source/format
echo "3.0 (quilt)" > "$BUILD_DIR/debian/source/format"


# debian/control
cat <<EOF > "$BUILD_DIR/debian/control"
Source: $PKG_NAME
Section: net
Priority: optional
Maintainer: $AUTHOR <$EMAIL>
Build-Depends: debhelper-compat (= 13)
Standards-Version: 4.6.0
Homepage: https://github.com/manhtuan28/tdesktop

Package: $PKG_NAME
Architecture: amd64
Depends: \${shlibs:Depends}, \${misc:Depends}, libx11-xcb1, libxcb1, libgl1, libgl1-mesa-glx | libgl1-mesa-dri, libpulse0, libxkbcommon0
Description: Telegram Desktop Custom Build
 Fast and secure desktop PC app, perfectly synced with your mobile phone.
 .
 This is a custom build with unlocked premium features and removed limits.
EOF

# debian/copyright
cat <<EOF > "$BUILD_DIR/debian/copyright"
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: Telegram Desktop
Source: https://github.com/manhtuan28/tdesktop

Files: *
Copyright: 2014-2026 Telegram FZ-LLC
License: GPL-3.0-or-later
EOF

# debian/changelog
DATE=$(date -R)
cat <<EOF > "$BUILD_DIR/debian/changelog"
$PKG_NAME ($DEB_VERSION) noble; urgency=medium

  * Release for PPA via CI.
  * Unlocked Premium features.
  * Bypassed Stars fee.
  * Ads blocked.
  * Max limits increased to 99999.

 -- $AUTHOR <$EMAIL>  $DATE
EOF

# debian/install
cat <<EOF > "$BUILD_DIR/debian/install"
Telegram usr/bin/
org.telegram.desktop.desktop usr/share/applications/
telegram.png usr/share/icons/hicolor/256x256/apps/
EOF

# debian/rules
cat <<EOF > "$BUILD_DIR/debian/rules"
#!/usr/bin/make -f
export DH_VERBOSE = 1

%:
	dh \$@

# Override build and configure to do nothing (we use prebuilt binary)
override_dh_auto_configure:
	# Do nothing

override_dh_auto_build:
	# Do nothing

override_dh_auto_test:
	# Do nothing

override_dh_strip:
	# Do nothing (binary is already stripped/prebuilt)

override_dh_shlibdeps:
	# Do nothing (binary statically links most things)
EOF
chmod +x "$BUILD_DIR/debian/rules"

# Build source package
cd "$BUILD_DIR"
dpkg-buildpackage -S -sa -d -k"$GPG_KEY" -p"gpg --batch --pinentry-mode loopback"
cd ../../

echo "=========================================================="
echo " Source package created successfully in $DIR/"
echo "=========================================================="
