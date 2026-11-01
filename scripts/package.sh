#!/bin/sh
# Build one plugin's package. Usage: scripts/package.sh <plugin> [out dir]
# POLYMUX_PLUGIN_TARGET names the target (default: this machine's os-arch).
# POLYMUX_PLUGIN_BINARIES is a folder whose files ship in bin/ beside the service.
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
if [ -n "${POLYMUX_PLUGIN_BINARIES:-}" ]; then
  find "$POLYMUX_PLUGIN_BINARIES" -maxdepth 1 -type f -exec cp {} "$STAGE/$(dirname "$SERVICE")/" \;
fi
chmod 755 "$STAGE/$(dirname "$SERVICE")"/*
FILE="$OUT/$NAME-$VERSION-$TARGET.tgz"
tar -czf "$FILE" -C "$STAGE" .
shasum -a 256 "$FILE" | cut -d' ' -f1 > "$FILE.sha256"
echo "$FILE"
