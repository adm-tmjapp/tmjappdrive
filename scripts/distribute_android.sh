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

ANDROID_APP_ID="${ANDROID_FIREBASE_APP_ID:-$(ruby -rjson -e 'puts JSON.parse(File.read("firebase.json")).dig("flutter","platforms","android","default","appId")')}"
ARTIFACT_TYPE="${ARTIFACT_TYPE:-apk}"
BUILD_NAME="${BUILD_NAME:-}"
BUILD_NUMBER="${BUILD_NUMBER:-}"
TESTERS="${TESTERS:-}"
GROUPS="${GROUPS:-}"
RELEASE_NOTES="${RELEASE_NOTES:-}"
RELEASE_NOTES_FILE="${RELEASE_NOTES_FILE:-}"
APP_ENV="${APP_ENV:-prod}"
API_BASE_URL="${API_BASE_URL:-}"

if [[ -z "$ANDROID_APP_ID" ]]; then
  echo "ANDROID_FIREBASE_APP_ID nao definido e nao foi possivel ler firebase.json" >&2
  exit 1
fi

BUILD_ARGS=(build)
if [[ "$ARTIFACT_TYPE" == "aab" ]]; then
  BUILD_ARGS+=(appbundle --release)
  ARTIFACT_PATH="build/app/outputs/bundle/release/app-release.aab"
else
  BUILD_ARGS+=(apk --release)
  ARTIFACT_PATH="build/app/outputs/flutter-apk/app-release.apk"
fi

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

flutter pub get
flutter "${BUILD_ARGS[@]}"

if [[ ! -f "$ARTIFACT_PATH" ]]; then
  echo "Artefato nao encontrado em $ARTIFACT_PATH" >&2
  exit 1
fi

DIST_ARGS=(appdistribution:distribute "$ARTIFACT_PATH" --app "$ANDROID_APP_ID")

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

echo "Distribuicao Android concluida: $ARTIFACT_PATH"
