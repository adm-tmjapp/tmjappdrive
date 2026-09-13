#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ARTIFACT="${1:-appbundle}"
if [[ $# -gt 0 ]]; then
  shift
fi

case "$ARTIFACT" in
  apk)
    TARGET="apk"
    ;;
  appbundle|aab)
    TARGET="appbundle"
    ;;
  *)
    echo "Uso: $0 [apk|appbundle]" >&2
    echo "Este projeto publica somente Android; builds Web, Linux e macOS não são suportados." >&2
    exit 2
    ;;
esac

flutter build "$TARGET" --release "$@"
