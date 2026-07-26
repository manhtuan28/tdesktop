/*
This file is part of Telegram Desktop,
the official desktop application for the Telegram messaging service.

For license and copyright information please follow this link:
https://github.com/telegramdesktop/tdesktop/blob/master/LEGAL
*/
#pragma once

#include "api/api_common.h"
#include "menu/menu_send_details.h"

namespace style {
struct ComposeIcons;
struct PopupMenu;
} // namespace style

namespace ChatHelpers {
class Show;
} // namespace ChatHelpers

namespace Ui {
class PopupMenu;
class RpWidget;
class Show;
} // namespace Ui

namespace Data {
class Thread;
} // namespace Data

namespace Main {
class Session;
} // namespace Main

namespace SendMenu {

enum class FillMenuResult : uchar {
	Prepared,
	Skipped,
	Failed,
};

enum class ActionType : uchar {
	Send,
	Schedule,
	SpoilerOn,
	SpoilerOff,
	CaptionUp,
	CaptionDown,
	PhotoQualityOn,
	PhotoQualityOff,
	ChangePrice,
	TranslateOutgoing,
};
struct Action {
	using Type = ActionType;

	Api::SendOptions options;
	Type type = Type::Send;
};
[[nodiscard]] Fn<void(Action, Details)> DefaultCallback(
	std::shared_ptr<ChatHelpers::Show> show,
	Fn<void(Api::SendOptions)> send);

// Translates `text` to the language chosen for outgoing translation and
// reports the result asynchronously, returning the request id so that the
// caller can track it as in-flight and cancel it.
//
// `done` receives an empty result when the server answered with nothing
// usable, so the caller must keep the text the user typed in that case.
// Neither callback is guarded here: the caller owns the lifetime and has to
// wrap them in crl::guard and re-check its own state before using them.
mtpRequestId RequestOutgoingTranslation(
	not_null<Main::Session*> session,
	TextWithTags text,
	Fn<void(TextWithTags)> done,
	Fn<void(QString)> fail);

// `translateOutgoing` is opt-in: only composers that own a text field and
// actually handle ActionType::TranslateOutgoing may enable it. Panels with
// no text field (stickers, GIFs, share box, poll box, caption editor) stay
// opt-out by simply not passing it.
FillMenuResult FillSendMenu(
	not_null<Ui::PopupMenu*> menu,
	std::shared_ptr<ChatHelpers::Show> maybeShow,
	Details details,
	Fn<void(Action, Details)> action,
	const style::ComposeIcons *iconsOverride = nullptr,
	std::optional<QPoint> desiredPositionOverride = std::nullopt,
	bool translateOutgoing = false);

FillMenuResult AttachSendMenuEffect(
	not_null<Ui::PopupMenu*> menu,
	std::shared_ptr<ChatHelpers::Show> show,
	Details details,
	Fn<void(Action, Details)> action,
	std::optional<QPoint> desiredPositionOverride = std::nullopt);

void SetupMenuAndShortcuts(
	not_null<Ui::RpWidget*> button,
	std::shared_ptr<ChatHelpers::Show> maybeShow,
	Fn<Details()> details,
	Fn<void(Action, Details)> action,
	const style::PopupMenu *stOverride = nullptr,
	const style::ComposeIcons *iconsOverride = nullptr,
	// Queried every time the menu is filled, so a composer can hide the
	// item while translating would be wrong (message edit, rich draft, ...)
	// instead of leaving a menu entry that does nothing when clicked.
	Fn<bool()> translateOutgoing = nullptr);

void SetupUnreadMentionsMenu(
	not_null<Ui::RpWidget*> button,
	Fn<Data::Thread*()> currentThread);

void SetupUnreadReactionsMenu(
	not_null<Ui::RpWidget*> button,
	Fn<Data::Thread*()> currentThread);

void SetupUnreadPollVotesMenu(
	not_null<Ui::RpWidget*> button,
	Fn<Data::Thread*()> currentThread);

} // namespace SendMenu
