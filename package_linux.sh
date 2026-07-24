#!/bin/bash
set -e

VERSION="7.0.4"
if [[ "$GITHUB_REF" == refs/tags/v* ]]; then
  VERSION="${GITHUB_REF#refs/tags/v}"
fi

mkdir -p artifact
cd out/Debug

# Create .tar.xz
tar -cJf ../../artifact/telegram-desktop-linux-x64.tar.xz Telegram Updater

# Create .deb
mkdir -p deb-pkg/usr/bin
mkdir -p deb-pkg/usr/share/applications
mkdir -p deb-pkg/usr/share/icons/hicolor/256x256/apps
mkdir -p deb-pkg/DEBIAN

cp Telegram deb-pkg/usr/bin/
cp Updater deb-pkg/usr/bin/
cp ../../lib/xdg/telegramdesktop.desktop deb-pkg/usr/share/applications/
cp ../../Telegram/Resources/art/icon256.png deb-pkg/usr/share/icons/hicolor/256x256/apps/telegram.png

cat <<CONTROL > deb-pkg/DEBIAN/control
Package: telegram-desktop
Version: $VERSION
Section: net
Priority: optional
Architecture: amd64
Depends: libxcb1, libgl1, libxkbcommon0
Maintainer: Manh Tuan <buimanhtuan2k4@gmail.com>
Description: Telegram Desktop Custom Build
 Fast and secure desktop PC app.
CONTROL

dpkg-deb --build deb-pkg ../../artifact/telegram-desktop_${VERSION}_amd64.deb
