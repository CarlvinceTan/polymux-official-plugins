#!/bin/sh
# Build one plugin's package. Usage: scripts/package.sh <plugin> [out dir]
# POLYMUX_PLUGIN_TARGET names the target (default: this machine's os-arch).
set -eu
ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
NAME=${1:?usage: scripts/package.sh <plugin> [out dir]}
OUT=${2:-$ROOT/dist/$NAME}
[ -f "$ROOT/plugins/$NAME/plugin.json" ] || { echo "No plugin named $NAME." >&2; exit 2; }
VERSION=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['version'])" "$ROOT/plugins/$NAME/plugin.json")
SERVICE=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))['service'])" "$ROOT/plugins/$NAME/plugin.json")
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m); [ "$ARCH" = x86_64 ] && ARCH=amd64; [ "$ARCH" = aarch64 ] && ARCH=arm64
TARGET=${POLYMUX_PLUGIN_TARGET:-$OS-$ARCH}
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
mkdir -p "$STAGE/$(dirname "$SERVICE")" "$OUT"
cp "$ROOT/plugins/$NAME/plugin.json" "$STAGE/"
(cd "$ROOT" && CGO_ENABLED=0 go build -trimpath -o "$STAGE/$SERVICE" "./plugins/$NAME")
chmod 755 "$STAGE/$SERVICE"
FILE="$OUT/$NAME-$VERSION-$TARGET.tgz"
tar -czf "$FILE" -C "$STAGE" .
shasum -a 256 "$FILE" | cut -d' ' -f1 > "$FILE.sha256"
echo "$FILE"
