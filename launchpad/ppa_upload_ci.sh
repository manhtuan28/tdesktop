#!/bin/bash
set -e

if [ "$#" -lt 2 ] || [ "$#" -gt 5 ]; then
    echo "Usage: $0 <version> <binary_path> [gpg_key_id] [series] [ppa_build]"
    echo "Example: $0 7.0.6 out/Release/Telegram B4E8F7726DAE1918924DF426AB5084E43E672D45 noble"
    echo
    echo "gpg_key_id may be empty or omitted to build an UNSIGNED source package"
    echo "(useful in CI); sign it locally with debsign before dput."
    echo
    echo "ppa_build defaults to a UTC timestamp. Launchpad refuses a version it"
    echo "already holds, so every upload of the same upstream version needs a"
    echo "higher build number - do not pin this unless you know why."
    exit 1
fi

VERSION="$1"
BINARY_PATH="$2"
GPG_KEY="${3:-}"
SERIES="${4:-noble}"
# Monotonic and unique per upload, and identical across the series built in one
# run (exported by the caller) so they stay in lockstep.
PPA_BUILD="${5:-${TUANGRAM_PPA_BUILD:-$(date -u +%Y%m%d%H%M)}}"

PKG_NAME="tuangram"
# The runtime desktop-file name is hardcoded in specific_linux.cpp, so the entry
# and the icons must keep the org.telegram.desktop id even though we rebranded.
DESKTOP_ID="org.telegram.desktop"
DEB_VERSION="${VERSION}-1ppa${PPA_BUILD}~${SERIES}1"
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

# A previous series left its debian/ here. It must not end up inside the orig
# tarball, and it would otherwise be regenerated on top of stale files.
rm -rf "$BUILD_DIR/debian"

# Copy binary
cp "$BINARY_PATH" "$BUILD_DIR/Telegram"
UPDATER_PATH="$(dirname "$BINARY_PATH")/Updater"
if [ -f "$UPDATER_PATH" ]; then
    cp "$UPDATER_PATH" "$BUILD_DIR/Updater"
fi

# Copy resources
cp "lib/xdg/$DESKTOP_ID.desktop" "$BUILD_DIR/$DESKTOP_ID.desktop"
# The shipped entry assumes "Telegram" is on PATH; point it at the real
# install location instead. Keep Icon= untouched (see debian/install).
sed -i \
    -e "s|^TryExec=Telegram$|TryExec=/opt/$PKG_NAME/Telegram|" \
    -e "s|^Exec=Telegram -- %U$|Exec=/opt/$PKG_NAME/Telegram -- %U|" \
    -e "s|^Exec=Telegram -quit$|Exec=/opt/$PKG_NAME/Telegram -quit|" \
    "$BUILD_DIR/$DESKTOP_ID.desktop"
cp Telegram/Resources/art/icon256.png "$BUILD_DIR/$DESKTOP_ID.png"

# Create the orig tarball ONCE per upstream version. Every series must ship the
# byte-identical tarball: the .dsc records its checksum, and Launchpad already
# holds the copy uploaded with the first series. Rebuilding it per series
# silently invalidates the .dsc files written by the earlier ones
# ("Checksum doesn't match for ..._orig.tar.gz" at dput time).
ORIG_TARBALL="${DIR}/${PKG_NAME}_${VERSION}.orig.tar.gz"
if [ -f "$ORIG_TARBALL" ]; then
    echo "Reusing existing $ORIG_TARBALL"
else
    cd "$DIR"
    # Deterministic: fixed owner/order and no gzip timestamp, so rebuilding
    # from the same inputs yields the same bytes.
    tar --sort=name --owner=0 --group=0 --numeric-owner \
        --mtime="@0" -cf - "${PKG_NAME}-${VERSION}" \
        | gzip -n > "${PKG_NAME}_${VERSION}.orig.tar.gz"
    cd ..
fi

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
Depends: \${shlibs:Depends}, \${misc:Depends}, libx11-6, libx11-xcb1, libxcb1, libxcb-icccm4, libxcb-image0, libxcb-keysyms1, libxcb-randr0, libxcb-render-util0, libxcb-shape0, libxcb-shm0, libxcb-sync1, libxcb-xfixes0, libxcb-xkb1, libxkbcommon0, libxkbcommon-x11-0, libwayland-client0, libfontconfig1, libglib2.0-0, libgl1, libpulse0, zlib1g
Conflicts: telegram-desktop
Description: TuanGram - Custom Telegram Desktop Build
 Fast and secure desktop PC app, perfectly synced with your mobile phone.
 .
 This is a custom build with unlocked premium features and removed limits.
EOF

# debian/copyright
cat <<EOF > "$BUILD_DIR/debian/copyright"
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: TuanGram
Source: https://github.com/manhtuan28/tdesktop

Files: *
Copyright: 2014-2026 Telegram FZ-LLC
License: GPL-3.0-or-later
EOF

# debian/changelog
DATE=$(date -R)
cat <<EOF > "$BUILD_DIR/debian/changelog"
$PKG_NAME ($DEB_VERSION) $SERIES; urgency=medium

  * TuanGram custom Telegram Desktop build, renamed so that it installs
    alongside the official telegram-desktop package instead of replacing it.
  * Defaults to Vietnamese on first start.
  * Client-side Premium unlock: raised pin, folder and chat-per-folder limits.
  * Blocks all sponsored messages and ads.
  * Auto-strips EXIF/GPS metadata from photos and images before upload.
  * Ghost mode (no read receipts, no typing status), switchable in
    Settings > Advanced.
  * Content unlocker: copy, save and forward from protected chats.
  * Unlocked article editor and todo lists without Premium.
  * Anti-recall and anti-TTL: keep deleted and self-destructing media visible.
  * Shows peer IDs in profiles.
  * Translate outgoing messages before sending; real-time translation bar
    unlocked for standard accounts.
  * Local deletion for channel and megagroup messages the server refuses to
    delete, instead of an error.
  * Media filters (Media, Links, Files, Music, Voice) in global search.
  * Auto-update is disabled; new versions are published on GitHub Releases.

 -- $AUTHOR <$EMAIL>  $DATE
EOF

# debian/install
# Everything lives under /opt/tuangram, matching the .deb produced by
# linux.yml, so this package can never overwrite a file owned by the official
# telegram-desktop package. /usr/bin/tuangram is a symlink created in
# debian/links. The .desktop and icon basenames must stay org.telegram.desktop
# because specific_linux.cpp hardcodes that application id.
cat <<EOF > "$BUILD_DIR/debian/install"
Telegram opt/$PKG_NAME/
$DESKTOP_ID.desktop usr/share/applications/
$DESKTOP_ID.png usr/share/icons/hicolor/256x256/apps/
EOF
if [ -f "$BUILD_DIR/Updater" ]; then
    echo "Updater opt/$PKG_NAME/" >> "$BUILD_DIR/debian/install"
fi

# debian/links
echo "opt/$PKG_NAME/Telegram usr/bin/$PKG_NAME" > "$BUILD_DIR/debian/links"

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
if [ -n "$GPG_KEY" ]; then
    dpkg-buildpackage -S -sa -d -k"$GPG_KEY" -p"gpg --batch --pinentry-mode loopback"
else
    # Unsigned: Launchpad will reject this until it is signed. Sign it with
    #   debsign -k <KEYID> launchpad_build/*_source.changes
    # and then upload with dput.
    echo "No GPG key given, building an UNSIGNED source package."
    dpkg-buildpackage -S -sa -d -us -uc
fi
cd ../../

echo "=========================================================="
echo " Source package created successfully in $DIR/"
ls -1 "$DIR"/*.dsc "$DIR"/*.changes "$DIR"/*.tar.* 2>/dev/null || true
if [ -z "$GPG_KEY" ]; then
    echo
    echo " UNSIGNED. Before uploading, run:"
    echo "   debsign -k <YOUR_KEY_ID> $DIR/*_source.changes"
    echo "   dput $PPA_URL $DIR/*_source.changes"
fi
echo "=========================================================="
