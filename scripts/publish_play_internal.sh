#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v bundle >/dev/null 2>&1; then
  echo "Bundler não encontrado no PATH" >&2
  exit 1
fi

if [[ -z "${PLAY_JSON_KEY_DATA:-}" ]]; then
  echo "Defina PLAY_JSON_KEY_DATA com o JSON da conta de serviço do Google Play" >&2
  exit 1
fi

export PLAY_PACKAGE_NAME="${PLAY_PACKAGE_NAME:-br.com.tmjapp.tmjapp.drive.tmjappdrive}"
export VERSION_NAME="${VERSION_NAME:-1.0.2}"
export VERSION_CODE="${VERSION_CODE:-6}"

bundle install
bundle exec fastlane android internal
