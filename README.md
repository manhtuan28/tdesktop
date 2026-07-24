# Tuancute Telegram Desktop – Custom Build

This is a **custom modified version** of the official [Telegram][telegram] messenger desktop client, created by **Manh Tuan (tuancute)**. It is based on the [Telegram API][telegram_api] and the [MTProto][telegram_proto] secure protocol, but enhanced with exclusive features.

## 🔥 Exclusive Features in this Build

* **Telegram Premium Unlocked**: Access to premium features natively without server-side validation limits where possible.
* **Bypass Stars Fee**: Restrictions and costs for certain premium reactions or actions have been bypassed.
* **Ad-Blocker**: Complete blocking of all sponsored messages and in-app advertisements.
* **Maximum Limits**: Limits for pins, folders, and chats have been significantly increased (up to 99999).
* **Vietnamese Default**: Out-of-the-box support for the Vietnamese language natively applied on first startup.
* **Product-Optimized**: Compiled as a fully optimized Release build for blazing-fast performance.
* **Auto Metadata Stripper**: Automatically removes EXIF, GPS, and camera metadata from photos before uploading to protect your privacy.
* **Ghost Mode**: Read messages without sending read receipts (no double ticks). Typing, recording, and uploading indicators are completely hidden from other users.
* **Content Unlocker**: Bypass all content protection restrictions set by admins — freely forward, save, copy, download, and screenshot any message, photo, video, or story.
* **Rich Messages & Todo Lists**: Create articles (bài viết) and todo/task lists (danh sách) in chats without needing Telegram Premium.

---

The source code is published under GPLv3 with OpenSSL exception, the license is
available [here][license].

## Supported systems

The latest version is available for

* [Windows 7 and above (64 bit)](https://telegram.org/dl/desktop/win64) ([portable](https://telegram.org/dl/desktop/win64_portable))
* [Windows 7 and above (32 bit)](https://telegram.org/dl/desktop/win) ([portable](https://telegram.org/dl/desktop/win_portable))
* [macOS 10.13 and above](https://telegram.org/dl/desktop/mac)
* [Linux static build for 64 bit](https://telegram.org/dl/desktop/linux)
* [Snap](https://snapcraft.io/telegram-desktop)
* [Flatpak](https://flathub.org/apps/details/org.telegram.desktop)

## Old system versions

Version **4.9.9** was the last that supports older systems

* [macOS 10.12](https://updates.tdesktop.com/tmac/tsetup.4.9.9.dmg)
* [Linux with glibc < 2.28 static build](https://updates.tdesktop.com/tlinux/tsetup.4.9.9.tar.xz)

Version **2.4.4** was the last that supports older systems

* [OS X 10.10 and 10.11](https://updates.tdesktop.com/tosx/tsetup-osx.2.4.4.dmg)
* [Linux static build for 32 bit](https://updates.tdesktop.com/tlinux32/tsetup32.2.4.4.tar.xz)

Version **1.8.15** was the last that supports older systems

* [Windows XP and Vista](https://updates.tdesktop.com/tsetup/tsetup.1.8.15.exe) ([portable](https://updates.tdesktop.com/tsetup/tportable.1.8.15.zip))
* [OS X 10.8 and 10.9](https://updates.tdesktop.com/tmac/tsetup.1.8.15.dmg)
* [OS X 10.6 and 10.7](https://updates.tdesktop.com/tmac32/tsetup32.1.8.15.dmg)

## Third-party

* Qt 6 ([LGPL](http://doc.qt.io/qt-6/lgpl.html)) and Qt 5.15 ([LGPL](http://doc.qt.io/qt-5/lgpl.html)) slightly patched
* OpenSSL 3.2.1 ([Apache License 2.0](https://openssl-library.org/source/license/apache-license-2.0.txt))
* WebRTC ([New BSD License](https://github.com/desktop-app/tg_owt/blob/master/LICENSE))
* zlib ([zlib License](http://www.zlib.net/zlib_license.html))
* LZMA SDK 9.20 ([public domain](http://www.7-zip.org/sdk.html))
* liblzma ([public domain](http://tukaani.org/xz/))
* Google Breakpad ([License](https://chromium.googlesource.com/breakpad/breakpad/+/master/LICENSE))
* Google Crashpad ([Apache License 2.0](https://chromium.googlesource.com/crashpad/crashpad/+/master/LICENSE))
* GYP ([BSD License](https://github.com/bnoordhuis/gyp/blob/master/LICENSE))
* Ninja ([Apache License 2.0](https://github.com/ninja-build/ninja/blob/master/COPYING))
* OpenAL Soft ([LGPL](https://github.com/kcat/openal-soft/blob/master/COPYING))
* Opus codec ([BSD License](http://www.opus-codec.org/license/))
* FFmpeg ([LGPL](https://www.ffmpeg.org/legal.html))
* Guideline Support Library ([MIT License](https://github.com/Microsoft/GSL/blob/master/LICENSE))
* Range-v3 ([Boost License](https://github.com/ericniebler/range-v3/blob/master/LICENSE.txt))
* Open Sans font ([Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0.html))
* Vazirmatn font ([SIL Open Font License 1.1](https://github.com/rastikerdar/vazirmatn/blob/master/OFL.txt))
* Emoji alpha codes ([MIT License](https://github.com/emojione/emojione/blob/master/extras/alpha-codes/LICENSE.md))
* xxHash ([BSD License](https://github.com/Cyan4973/xxHash/blob/dev/LICENSE))
* QR Code generator ([MIT License](https://github.com/nayuki/QR-Code-generator#license))
* CMake ([New BSD License](https://github.com/Kitware/CMake/blob/master/Copyright.txt))
* Hunspell ([LGPL](https://github.com/hunspell/hunspell/blob/master/COPYING.LESSER))
* Ada ([Apache License 2.0](https://github.com/ada-url/ada/blob/main/LICENSE-APACHE))

## Build instructions

* [Windows (32-bit and 64-bit)][win]
* [macOS][mac]
* [GNU/Linux using Docker][linux]

[//]: # (LINKS)
[telegram]: https://telegram.org
[telegram_desktop]: https://desktop.telegram.org
[telegram_api]: https://core.telegram.org
[telegram_proto]: https://core.telegram.org/mtproto
[license]: LICENSE
[win]: docs/building-win.md
[mac]: docs/building-mac.md
[linux]: docs/building-linux.md
[preview_image]: https://github.com/telegramdesktop/tdesktop/blob/dev/docs/assets/preview.png "Preview of Telegram Desktop"
[preview_image_url]: https://raw.githubusercontent.com/telegramdesktop/tdesktop/dev/docs/assets/preview.png

## Thanks to

<a href="https://depot.dev">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://depot.dev/assets/brand/1693758816/depot-logo-horizontal-on-dark.svg">
    <source media="(prefers-color-scheme: light)" srcset="https://depot.dev/assets/brand/1693758816/depot-logo-horizontal-on-light.svg">
    <img alt="Depot" src="https://depot.dev/assets/brand/1693758816/depot-logo-horizontal-on-light.svg" width="150">
  </picture>
</a>

CI infrastructure sponsored by [Depot](https://depot.dev) — fast GitHub Actions runners.

