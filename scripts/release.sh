#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skip_plasma_validation=false

if [[ "${1:-}" == "--skip-plasma-validation" ]]; then
    skip_plasma_validation=true
elif [[ $# -gt 0 ]]; then
    echo "Usage: $0 [--skip-plasma-validation]" >&2
    exit 2
fi

for command_name in python3 zip; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        echo "Required command not found: $command_name" >&2
        exit 1
    fi
done

version="$(cd "$root_dir" && python3 -c \
    'import json; print(json.load(open("metadata.json"))["KPlugin"]["Version"])')"

python3 -m json.tool "$root_dir/metadata.json" >/dev/null
bash -n "$root_dir/install.sh"
bash -n "$root_dir/scripts/release.sh"

if command -v xmllint >/dev/null 2>&1; then
    xmllint --noout "$root_dir/contents/config/main.xml"
elif [[ "$skip_plasma_validation" == false ]]; then
    echo "xmllint is required for a full release validation" >&2
    exit 1
fi

if command -v qmllint >/dev/null 2>&1; then
    qmllint \
        "$root_dir/contents/ui/main.qml" \
        "$root_dir/contents/ui/configGeneral.qml" \
        "$root_dir/contents/config/config.qml"
elif [[ "$skip_plasma_validation" == false ]]; then
    echo "qmllint is required for a full release validation" >&2
    exit 1
fi

dist_dir="$root_dir/dist"
archive="$dist_dir/kde-codex-usage-$version.plasmoid"
mkdir -p "$dist_dir"
rm -f "$archive" "$archive.sha256"

(
    cd "$root_dir"
    zip -q -r "$archive" metadata.json contents LICENSE \
        -x '*/__pycache__/*' '*.pyc' '*~'
)

if [[ "$skip_plasma_validation" == false ]]; then
    if ! command -v kpackagetool6 >/dev/null 2>&1; then
        echo "kpackagetool6 is required for a full release validation" >&2
        exit 1
    fi

    package_root="$(mktemp -d)"
    trap 'rm -rf "$package_root"' EXIT
    kpackagetool6 --type Plasma/Applet --packageroot "$package_root" --install "$archive"
fi

if command -v sha256sum >/dev/null 2>&1; then
    (
        cd "$dist_dir"
        sha256sum "$(basename "$archive")" >"$(basename "$archive").sha256"
    )
fi

echo "Created $archive"
