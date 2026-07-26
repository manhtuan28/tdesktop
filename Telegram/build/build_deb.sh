#!/bin/bash
set -e

FullExecPath=$PWD
pushd "$(dirname "$0")" > /dev/null
FullScriptPath=$(pwd)
popd > /dev/null

while IFS='' read -r line || [[ -n "$line" ]]; do
  set $line
  eval $1="$2"
done < "$FullScriptPath/version"

BinaryPath="${1:-}"
OutputDir="${2:-$FullExecPath}"
PackageName="tuangram"
# The runtime desktop-file name is hardcoded in specific_linux.cpp, so the entry
# and the icons must keep the org.telegram.desktop id even though we rebranded.
DesktopId="org.telegram.desktop"
Architecture="amd64"
Version="$AppVersionStr"
DebFile="${PackageName}_${Version}_${Architecture}.deb"

if [ -z "$BinaryPath" ]; then
  if [ -f "$FullScriptPath/../../out/Release/Telegram" ]; then
    BinaryPath="$FullScriptPath/../../out/Release/Telegram"
  elif [ -f "$FullScriptPath/../../out/Debug/Telegram" ]; then
    BinaryPath="$FullScriptPath/../../out/Debug/Telegram"
  else
    echo ""
    echo "Usage: ./build_deb.sh /path/to/built/Telegram [output_dir]"
    echo ""
    echo "  /path/to/built/Telegram  - Path to the compiled TuanGram binary"
    echo "  output_dir               - Where to place the .deb file (default: current directory)"
    echo ""
    echo "If no path is given, the script looks for out/Release/Telegram or out/Debug/Telegram"
    echo ""
    exit 1
  fi
fi

if [ ! -f "$BinaryPath" ]; then
  echo "Error: Binary not found at $BinaryPath"
  exit 1
fi

BinaryPath=$(realpath "$BinaryPath")
OutputDir=$(realpath "$OutputDir")

echo "Building $DebFile from $BinaryPath ..."

TmpDir=$(mktemp -d)
trap "rm -rf $TmpDir" EXIT

PkgRoot="$TmpDir/$PackageName"

mkdir -p "$PkgRoot/DEBIAN"
mkdir -p "$PkgRoot/usr/bin"
mkdir -p "$PkgRoot/usr/share/applications"
mkdir -p "$PkgRoot/usr/share/icons/hicolor/256x256/apps"
mkdir -p "$PkgRoot/usr/share/metainfo"

InstalledSize=$(du -sk "$BinaryPath" | cut -f1)

cat > "$PkgRoot/DEBIAN/control" << EOF
Package: $PackageName
Version: $Version
Section: net
Priority: optional
Architecture: $Architecture
Installed-Size: $InstalledSize
Depends: libqt6widgets6 (>= 6.2) | libqt5widgets5 (>= 5.15), libc6 (>= 2.31), libstdc++6 (>= 11), libx11-6, libxcb1, zlib1g
Conflicts: telegram-desktop
Replaces: telegram-desktop
Maintainer: manhtuan28 <manhtuan28@github.com>
Homepage: https://github.com/manhtuan28/tdesktop
Description: TuanGram - Custom Telegram Desktop Build
 Fast and secure desktop messaging app, fully synced with
 your mobile phone. Custom build with premium features unlocked
 and increased limits.
EOF

install -m 755 "$BinaryPath" "$PkgRoot/usr/bin/tuangram"

cat > "$PkgRoot/usr/share/applications/$DesktopId.desktop" << EOF
[Desktop Entry]
Version=1.0
Name=TuanGram
Comment=Fast and secure desktop messaging
TryExec=tuangram
Exec=tuangram -- %u
Icon=$DesktopId
Terminal=false
StartupWMClass=TelegramDesktop
Type=Application
Categories=Chat;Network;InstantMessaging;Qt;
MimeType=x-scheme-handler/tg;x-scheme-handler/tonsite;
Keywords=tg;chat;im;messaging;messenger;sms;tuangram;
Actions=quit;

[Desktop Action quit]
Name=Quit TuanGram
Exec=tuangram -quit
Icon=$DesktopId
EOF

IconSource="$FullScriptPath/../Resources/art/icon256.png"
if [ -f "$IconSource" ]; then
  install -m 644 "$IconSource" "$PkgRoot/usr/share/icons/hicolor/256x256/apps/$DesktopId.png"
else
  echo "Warning: Icon not found at $IconSource, .deb will have no icon"
fi

Icon512="$FullScriptPath/../Resources/art/icon512.png"
if [ -f "$Icon512" ]; then
  mkdir -p "$PkgRoot/usr/share/icons/hicolor/512x512/apps"
  install -m 644 "$Icon512" "$PkgRoot/usr/share/icons/hicolor/512x512/apps/$DesktopId.png"
fi

cat > "$PkgRoot/usr/share/metainfo/$DesktopId.metainfo.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<component type="desktop-application">
  <id>$DesktopId</id>
  <name>TuanGram</name>
  <summary>Fast and secure desktop messaging</summary>
  <metadata_license>CC0-1.0</metadata_license>
  <project_license>GPL-3.0</project_license>
  <url type="homepage">https://github.com/manhtuan28/tdesktop</url>
  <releases>
    <release version="$Version" />
  </releases>
  <launchable type="desktop-id">$DesktopId.desktop</launchable>
</component>
EOF

cat > "$PkgRoot/DEBIAN/postinst" << 'EOF'
#!/bin/bash
update-desktop-database /usr/share/applications 2>/dev/null || true
gtk-update-icon-cache /usr/share/icons/hicolor 2>/dev/null || true
EOF
chmod 755 "$PkgRoot/DEBIAN/postinst"

cat > "$PkgRoot/DEBIAN/postrm" << 'EOF'
#!/bin/bash
update-desktop-database /usr/share/applications 2>/dev/null || true
gtk-update-icon-cache /usr/share/icons/hicolor 2>/dev/null || true
EOF
chmod 755 "$PkgRoot/DEBIAN/postrm"

dpkg-deb --build --root-owner-group "$PkgRoot" "$OutputDir/$DebFile"

echo ""
echo "Successfully built: $OutputDir/$DebFile"
echo ""
echo "Install with:  sudo dpkg -i $DebFile"
echo "Remove with:   sudo apt remove $PackageName"
echo ""
