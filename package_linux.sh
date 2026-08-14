#!/bin/bash
set -euo pipefail

ScriptDir=$(cd "$(dirname "$0")" && pwd)

VERSION=$(awk '/^AppVersionStr /{print $2}' "$ScriptDir/Telegram/build/version")
if [ -z "$VERSION" ]; then VERSION="0.0.0"; fi
if [[ "${GITHUB_REF:-}" == refs/tags/v* ]]; then
  VERSION="${GITHUB_REF#refs/tags/v}"
fi

PackageName="tuangram"
DesktopId="org.telegram.desktop"

# Auto-detect binary directory (Release preferred, then Debug)
BIN_DIR=""
for candidate in "$ScriptDir/out/Release" "$ScriptDir/out/Debug"; do
  if [ -f "$candidate/Telegram" ]; then
    BIN_DIR="$candidate"
    break
  fi
done

if [ -z "$BIN_DIR" ]; then
  echo "Error: Cannot find Telegram binary in out/Release or out/Debug" >&2
  exit 1
fi

echo "Packaging from: $BIN_DIR (version: $VERSION)"

ARTIFACT="$ScriptDir/artifact"
mkdir -p "$ARTIFACT"

# Create .tar.xz portable bundle
tar -cJf "$ARTIFACT/${PackageName}-${VERSION}-linux-x64.tar.xz" -C "$BIN_DIR" Telegram

# Create Debian package (.deb)
PKGDIR="$ScriptDir/deb-pkg"
rm -rf "$PKGDIR"
mkdir -p "$PKGDIR/DEBIAN"
mkdir -p "$PKGDIR/opt/$PackageName"
mkdir -p "$PKGDIR/usr/bin"
mkdir -p "$PKGDIR/usr/share/applications"
mkdir -p "$PKGDIR/usr/share/icons/hicolor/256x256/apps"

install -m 755 "$BIN_DIR/Telegram" "$PKGDIR/opt/$PackageName/Telegram"
ln -s "/opt/$PackageName/Telegram" "$PKGDIR/usr/bin/$PackageName"

install -m 644 "$ScriptDir/Telegram/Resources/art/icon256.png" \
  "$PKGDIR/usr/share/icons/hicolor/256x256/apps/$DesktopId.png"

sed -e "s|^TryExec=.*|TryExec=/opt/$PackageName/Telegram|" \
    -e "s|^Exec=Telegram -- %U|Exec=/opt/$PackageName/Telegram -- %U|" \
    -e "s|^Exec=Telegram -quit|Exec=/opt/$PackageName/Telegram -quit|" \
    "$ScriptDir/lib/xdg/$DesktopId.desktop" \
    > "$PKGDIR/usr/share/applications/$DesktopId.desktop"
chmod 644 "$PKGDIR/usr/share/applications/$DesktopId.desktop"

cat <<CONTROL > "$PKGDIR/DEBIAN/control"
Package: $PackageName
Version: $VERSION
Section: net
Priority: optional
Architecture: amd64
Depends: libc6, libstdc++6, libx11-6, libxcb1, libxcb-icccm4, libxcb-image0, libxcb-keysyms1, libxcb-randr0, libxcb-render-util0, libxcb-shape0, libxcb-shm0, libxcb-sync1, libxcb-xfixes0, libxcb-xkb1, libxkbcommon0, libxkbcommon-x11-0, libwayland-client0, libfontconfig1, libglib2.0-0, libgl1, zlib1g
Conflicts: telegram-desktop
Maintainer: Manh Tuan <buimanhtuan2k4@gmail.com>
Description: TuanGram - modded Telegram Desktop
 Fast and secure desktop PC app.
CONTROL

dpkg-deb --root-owner-group --build "$PKGDIR" "$ARTIFACT/${PackageName}_${VERSION}_amd64.deb"
rm -rf "$PKGDIR"

echo "Packages generated in $ARTIFACT/:"
ls -lh "$ARTIFACT"

