#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PLATFORM="${1:-android}"

case "$PLATFORM" in
  android)
    exec "$ROOT_DIR/scripts/distribute_android.sh"
    ;;
  ios)
    exec "$ROOT_DIR/scripts/distribute_ios.sh"
    ;;
  all)
    "$ROOT_DIR/scripts/distribute_android.sh"
    "$ROOT_DIR/scripts/distribute_ios.sh"
    ;;
  *)
    echo "Uso: $0 [android|ios|all]" >&2
    exit 1
    ;;
esac
