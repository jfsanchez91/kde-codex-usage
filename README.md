# KDE Codex Usage

A Plasma 6 widget for the desktop and panel that displays the rolling Codex
usage windows associated with the current ChatGPT/Codex account.

> [!NOTE]
> This is an unofficial community project and is not affiliated with or
> endorsed by OpenAI.

The widget talks to the local Codex CLI app server using
`account/rateLimits/read`. It reuses the existing Codex login and never reads,
stores, or transmits an API key itself.

## Requirements

- KDE Plasma 6
- Python 3.10 or newer
- A recent `codex` CLI available in the Plasma session's `PATH`
- An authenticated Codex session (`codex login`)

## Install

### KDE Store

After the first store release, install **Codex Usage** from Plasma's
**Get New Widgets** dialog.

### Manual installation

```bash
chmod +x install.sh contents/code/fetch_limits.py
./install.sh
```

Open Plasma's widget picker, search for **Codex Usage**, then place it on the
desktop or a panel. The compact panel view shows status and remaining capacity;
opening it shows both rolling windows as concentric 270-degree circular arcs on
a transparent background. The bottom gap contains a Codex label. The dial
itself only shows remaining percentages; hover it for absolute reset times,
relative reset times, and the last update time. Widget settings let
you choose a refresh interval in seconds and whether the panel shows the
five-hour limit, weekly limit, or both. The default refresh interval is 10
seconds and the panel defaults to the five-hour limit. The two arc colors are
independently configurable, while both percentage labels share a separate
configurable color.

Desktop notifications can be configured independently for the five-hour and
weekly limits. Each limit has one remaining-capacity warning threshold. The
widget can also notify when a window resets and when capacity becomes available
again after exhaustion. Notification state is persisted so regular refreshes
and Plasma restarts do not repeat the same warning.

Panel mode uses the same 270-degree gauge language rather than a generic icon.
It shows the selected limit directly, or two miniature gauges when both limits
are enabled. Panel hover tooltips are disabled; clicking opens a styled details
view containing both limits, reset times, plan information, update time, and
any active rate-limit warning.

## Develop

Validate the package and test the data helper independently:

```bash
kpackagetool6 --type Plasma/Applet --upgrade .
python3 contents/code/fetch_limits.py
```

The helper prints one JSON object. It exits non-zero and returns a user-facing
error object when Codex is unavailable or not logged in.

## Create a release package

The release script validates the package, builds the `.plasmoid` archive, tests
that Plasma can install it, and creates a SHA-256 checksum:

```bash
./scripts/release.sh
```

Release files are written to `dist/`. Store listing copy and the asset checklist
are maintained in [STORE.md](STORE.md).

## Notes

The five-hour and weekly windows are ChatGPT/Codex plan limits, not OpenAI API
token billing. Their duration is taken from the server response rather than
hard-coded, so the labels remain accurate if a plan uses different windows.

The widget has been tested with Codex CLI 0.141.0. The Codex app-server
rate-limit interface is experimental and may change in future releases.
