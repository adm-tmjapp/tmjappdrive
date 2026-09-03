$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$localPropertiesPath = Join-Path $projectRoot "android\local.properties"

if (-not (Test-Path -LiteralPath $localPropertiesPath)) {
    throw "android/local.properties was not found. Run 'flutter pub get' first."
}

$sdkProperty = Get-Content -LiteralPath $localPropertiesPath |
    Where-Object { $_ -match '^sdk\.dir=' } |
    Select-Object -First 1

if (-not $sdkProperty) {
    throw "sdk.dir is missing from android/local.properties."
}

$androidSdk = ($sdkProperty -replace '^sdk\.dir=', '') -replace '\\\\', '\'
$adbPath = Join-Path $androidSdk "platform-tools\adb.exe"

if (-not (Test-Path -LiteralPath $adbPath)) {
    throw "ADB was not found at '$adbPath'."
}

# Start ADB before Flutter. On Windows, an ADB server spawned while Flutter's
# bootstrap lock is open can inherit that handle and block later Flutter runs.
& $adbPath start-server
if ($LASTEXITCODE -ne 0) {
    throw "ADB failed to start (exit code $LASTEXITCODE)."
}

& $adbPath get-state 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Warning "ADB started, but no authorized Android device is available."
}
