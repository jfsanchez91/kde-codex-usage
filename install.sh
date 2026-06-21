#!/usr/bin/env bash
set -euo pipefail

package_id="com.github.jfsanchez91.kde-codex-usage"
legacy_package_ids=("com.github.kdecodex.indicator")
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
package_root="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids"
installed_dir="$package_root/$package_id"
icon_root="${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor/512x512/apps"
icon_path="$icon_root/$package_id.png"

for legacy_id in "${legacy_package_ids[@]}"; do
    legacy_dir="$package_root/$legacy_id"
    if [[ -d "$legacy_dir" ]]; then
        echo "Removing legacy package: $legacy_id"
        kpackagetool6 --type Plasma/Applet --packageroot "$package_root" --remove "$legacy_id"
    fi
done

if [[ -d "$installed_dir" ]]; then
    echo "Removing previous installation: $installed_dir"
    kpackagetool6 --type Plasma/Applet --packageroot "$package_root" --remove "$package_id"
fi

kpackagetool6 --type Plasma/Applet --packageroot "$package_root" --install "$root_dir"
install -Dm644 "$root_dir/icon.png" "$icon_path"

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t "${XDG_DATA_HOME:-$HOME/.local/share}/icons/hicolor" >/dev/null 2>&1 || true
fi

echo "Installed $package_id. Add ‘Codex Usage’ from Plasma's widget picker."
