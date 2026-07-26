/*
This file is part of Telegram Desktop,
the official desktop application for the Telegram messaging service.

For license and copyright information please follow this link:
https://github.com/telegramdesktop/tdesktop/blob/master/LEGAL
*/
#pragma once

#include "base/const_string.h"

#define TDESKTOP_REQUESTED_ALPHA_VERSION (0ULL)

#ifdef TDESKTOP_ALLOW_CLOSED_ALPHA
#define TDESKTOP_ALPHA_VERSION TDESKTOP_REQUESTED_ALPHA_VERSION
#else // TDESKTOP_ALLOW_CLOSED_ALPHA
#define TDESKTOP_ALPHA_VERSION (0ULL)
#endif // TDESKTOP_ALLOW_CLOSED_ALPHA

// used in Updater.cpp and Setup.iss for Windows
//
// TuanGram uses its own identity, distinct from official Telegram Desktop:
// a different AppId keeps the installer from hijacking the official app's
// uninstall entry, and a different AppName keeps the working directory
// (%APPDATA%/TuanGram) separate so the two installs never share a tdata.
// AppNameOld is deliberately NOT set to "Telegram Desktop" — MoveOldDataFiles()
// deletes the source files after copying, which would destroy the session of a
// user who also has official Telegram Desktop installed.
constexpr auto AppId = "{71A49D72-8B44-412B-83B0-1D42C73C3359}"_cs;
constexpr auto AppNameOld = "Telegram Win (Unofficial)"_cs;
constexpr auto AppName = "TuanGram"_cs;
constexpr auto AppFile = "Telegram"_cs;
constexpr auto AppVersion = 7000006;
constexpr auto AppVersionStr = "7.0.6";
constexpr auto AppBetaVersion = false;
constexpr auto AppAlphaVersion = TDESKTOP_ALPHA_VERSION;
