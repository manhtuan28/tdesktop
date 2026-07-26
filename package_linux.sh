#!/bin/bash
set -e

ScriptDir=$(cd "$(dirname "$0")" && pwd)

VERSION=$(grep "^AppVersionStr " "$ScriptDir/Telegram/build/version" | awk '{print $2}')
if [ -z "$VERSION" ]; then VERSION="0.0.0"; fi
if [[ "$GITHUB_REF" == refs/tags/v* ]]; then
  VERSION="${GITHUB_REF#refs/tags/v}"
fi

PackageName="tuangram"
# The runtime desktop-file name is hardcoded in specific_linux.cpp, so the entry
# and the icons must keep the org.telegram.desktop id even though we rebranded.
DesktopId="org.telegram.desktop"

mkdir -p artifact
cd out/Debug

# Create .tar.xz
tar -cJf "../../artifact/${PackageName}-linux-x64.tar.xz" Telegram Updater

# Create .deb
mkdir -p deb-pkg/usr/bin
mkdir -p deb-pkg/usr/share/applications
mkdir -p deb-pkg/usr/share/icons/hicolor/256x256/apps
mkdir -p deb-pkg/DEBIAN

cp Telegram deb-pkg/usr/bin/
cp Updater deb-pkg/usr/bin/
cp "../../lib/xdg/$DesktopId.desktop" "deb-pkg/usr/share/applications/$DesktopId.desktop"
cp ../../Telegram/Resources/art/icon256.png "deb-pkg/usr/share/icons/hicolor/256x256/apps/$DesktopId.png"

cat <<CONTROL > deb-pkg/DEBIAN/control
Package: $PackageName
Version: $VERSION
Section: net
Priority: optional
Architecture: amd64
Depends: libxcb1, libgl1, libxkbcommon0
Conflicts: telegram-desktop
Replaces: telegram-desktop
Maintainer: Manh Tuan <buimanhtuan2k4@gmail.com>
Description: TuanGram - Custom Telegram Desktop Build
 Fast and secure desktop PC app.
CONTROL

dpkg-deb --build deb-pkg "../../artifact/${PackageName}_${VERSION}_amd64.deb"
