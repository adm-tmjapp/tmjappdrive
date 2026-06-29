#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter nao encontrado no PATH" >&2
  exit 1
fi

if ! command -v firebase >/dev/null 2>&1; then
  echo "firebase CLI nao encontrado no PATH" >&2
  exit 1
fi

IOS_APP_ID="${IOS_FIREBASE_APP_ID:-$(ruby -rjson -e 'puts JSON.parse(File.read("firebase.json")).dig("flutter","platforms","ios","default","appId")')}"
EXPORT_OPTIONS_PLIST="${EXPORT_OPTIONS_PLIST:-}"
BUILD_NAME="${BUILD_NAME:-}"
BUILD_NUMBER="${BUILD_NUMBER:-}"
TESTERS="${TESTERS:-}"
GROUPS="${GROUPS:-}"
RELEASE_NOTES="${RELEASE_NOTES:-}"
RELEASE_NOTES_FILE="${RELEASE_NOTES_FILE:-}"
APP_ENV="${APP_ENV:-prod}"
API_BASE_URL="${API_BASE_URL:-}"

if [[ -z "$IOS_APP_ID" ]]; then
  echo "IOS_FIREBASE_APP_ID nao definido e nao foi possivel ler firebase.json" >&2
  exit 1
fi

BUILD_ARGS=(build ipa --release)

if [[ -n "$BUILD_NAME" ]]; then
  BUILD_ARGS+=("--build-name=$BUILD_NAME")
fi

if [[ -n "$BUILD_NUMBER" ]]; then
  BUILD_ARGS+=("--build-number=$BUILD_NUMBER")
fi

BUILD_ARGS+=("--dart-define=APP_ENV=$APP_ENV")

if [[ -n "$API_BASE_URL" ]]; then
  BUILD_ARGS+=("--dart-define=API_BASE_URL=$API_BASE_URL")
fi

if [[ -n "$EXPORT_OPTIONS_PLIST" ]]; then
  BUILD_ARGS+=("--export-options-plist=$EXPORT_OPTIONS_PLIST")
fi

flutter pub get
flutter "${BUILD_ARGS[@]}"

IPA_PATH="$(find build/ios/ipa -maxdepth 1 -name '*.ipa' | head -n 1)"

if [[ -z "$IPA_PATH" || ! -f "$IPA_PATH" ]]; then
  echo "IPA nao encontrado em build/ios/ipa" >&2
  exit 1
fi

DIST_ARGS=(appdistribution:distribute "$IPA_PATH" --app "$IOS_APP_ID")

if [[ -n "$TESTERS" ]]; then
  DIST_ARGS+=(--testers "$TESTERS")
fi

if [[ -n "$GROUPS" ]]; then
  DIST_ARGS+=(--groups "$GROUPS")
fi

if [[ -n "$RELEASE_NOTES_FILE" ]]; then
  DIST_ARGS+=(--release-notes-file "$RELEASE_NOTES_FILE")
elif [[ -n "$RELEASE_NOTES" ]]; then
  DIST_ARGS+=(--release-notes "$RELEASE_NOTES")
fi

firebase "${DIST_ARGS[@]}"

echo "Distribuicao iOS concluida: $IPA_PATH"
