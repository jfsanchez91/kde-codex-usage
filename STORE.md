# KDE Store listing

## Category

**Plasma 6 Monitoring**

## Name

**Codex Usage**

## Summary

A KDE Plasma desktop and panel widget for monitoring Codex usage limits and
reset times.

## Description

Codex Usage displays the rolling usage windows associated with the current
ChatGPT/Codex account. It supports both a resizable desktop gauge and a compact
panel gauge with a detailed popup.

Features include:

- Five-hour and weekly usage limits
- Remaining percentages and reset times
- Desktop and panel layouts
- Configurable refresh interval
- Configurable gauge and percentage colors
- Choice of the limit shown in panel mode

The widget uses the locally installed Codex CLI and reuses its authenticated
session. It does not read or store an OpenAI API key.

## Requirements

- KDE Plasma 6
- Python 3.10 or newer
- Codex CLI available in the Plasma session's `PATH`
- An authenticated session created with `codex login`
- Plasma5Support QML compatibility module

The widget has been tested with Codex CLI 0.141.0. Its rate-limit app-server
interface is experimental and may change in future Codex releases.

This is an unofficial community project and is not affiliated with or endorsed
by OpenAI.

## Links

- Source: https://github.com/jfsanchez91/kde-codex-usage
- Issues: https://github.com/jfsanchez91/kde-codex-usage/issues
- License: MIT

## Assets to upload manually

- Square product icon
- Desktop widget screenshot
- Panel gauge screenshot
- Expanded panel popup screenshot
- Settings window screenshot
- `dist/kde-codex-usage-<version>.plasmoid`
