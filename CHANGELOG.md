# Changelog

All notable changes to KDE Codex Usage are documented here.

## [0.8.4] - 2026-06-21

### Fixed

- Prevent duplicate notifications from overlapping refreshes by keeping an immediate in-memory state cache.
- Only detect resets after the previous reset boundary has passed, avoiding false resets from moving timestamps.
- Keep warning notifications deduplicated until a genuine reset or restored availability.

## [0.8.3] - 2026-06-21

### Added

- Configurable low-capacity warnings for the five-hour and weekly limits.
- Notifications when a limit resets or exhausted usage becomes available again.
- Persistent notification deduplication across refreshes and Plasma restarts.

## [0.8.2] - 2026-06-21

### Changed

- Register the bundled product icon in the user icon theme so Plasma's widget picker displays it.

## [0.8.1] - 2026-06-21

### Added

- Custom application icon in the runtime plasmoid and panel details header.

## [0.8.0] - 2026-06-21

### Added

- Plasma 6 desktop and panel representations.
- Five-hour and weekly Codex usage gauges.
- Detailed reset and update information in the panel popup.
- Configurable refresh interval, panel content, gauge colors, and label color.
- Context-aware settings for desktop and panel instances.
- Release packaging and validation tooling.

### Notes

- Requires an authenticated Codex CLI session.
- Uses the Codex app-server `account/rateLimits/read` method.
- Displays ChatGPT/Codex plan limits, not OpenAI API billing usage.

[0.8.0]: https://github.com/jfsanchez91/kde-codex-usage/releases/tag/v0.8.0
[0.8.1]: https://github.com/jfsanchez91/kde-codex-usage/releases/tag/v0.8.1
[0.8.2]: https://github.com/jfsanchez91/kde-codex-usage/releases/tag/v0.8.2
[0.8.3]: https://github.com/jfsanchez91/kde-codex-usage/releases/tag/v0.8.3
[0.8.4]: https://github.com/jfsanchez91/kde-codex-usage/releases/tag/v0.8.4
