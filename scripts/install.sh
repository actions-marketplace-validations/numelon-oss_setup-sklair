#!/usr/bin/env bash
set -euo pipefail

version=${SKLAIR_VERSION#v}
if [[ ! $version =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-[0-9A-Za-z]+([.-][0-9A-Za-z]+)*)?$ ]]; then
    echo 'Specify a Sklair release version, for example 0.4.0 or v0.4.0.' >&2
    exit 1
fi

case "$RUNNER_OS" in
    Linux) platform=linux ;;
    macOS) platform=darwin ;;
    *) echo "Unsupported runner OS: $RUNNER_OS" >&2; exit 1 ;;
esac
case "$RUNNER_ARCH" in
    X64) architecture=amd64 ;;
    ARM64) architecture=arm64 ;;
    *) echo "Unsupported runner architecture: $RUNNER_ARCH" >&2; exit 1 ;;
esac

installation=$(mktemp -d "$RUNNER_TEMP/setup-sklair.XXXXXX")
mkdir "$installation/bin"
archive="sklair-$platform-$architecture.tar.gz"
base_url="https://github.com/numelon-oss/sklair/releases/download/v$version"
curl --fail --silent --show-error --location --retry 3 "$base_url/$archive" --output "$installation/$archive"
curl --fail --silent --show-error --location --retry 3 "$base_url/SHA256SUMS" --output "$installation/SHA256SUMS"

# match exactly one checksum entry for this archive, not other release assets
expected=$(awk -v filename="$archive" '$2 == filename || $2 == "*" filename { print $1 }' "$installation/SHA256SUMS")
if [[ ! $expected =~ ^[0-9A-Fa-f]{64}$ ]]; then
    echo "Missing, duplicate, or invalid checksum for $archive." >&2
    exit 1
fi
if [[ $RUNNER_OS == macOS ]]; then
    actual=$(shasum -a 256 "$installation/$archive")
else
    actual=$(sha256sum "$installation/$archive")
fi
actual=${actual%% *}
if [[ $(printf '%s' "$actual" | tr 'A-F' 'a-f') != $(printf '%s' "$expected" | tr 'A-F' 'a-f') ]]; then
    echo "Checksum mismatch for $archive." >&2
    exit 1
fi

tar -xzf "$installation/$archive" -C "$installation/bin" sklair
chmod 0755 "$installation/bin/sklair"
"$installation/bin/sklair" version
printf '%s\n' "$installation/bin" >> "$GITHUB_PATH"
