param(
    [string]$ApiBaseUrl = $env:API_BASE_URL,
    [string]$Target = "",
    [string]$Device = "",
    [switch]$SkipPubGet
)

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$AppDir = Join-Path $RepoRoot "app_manga"
$IntegrationTestDir = Join-Path $AppDir "integration_test"

if (-not (Test-Path $AppDir)) {
    throw "Cannot find app_manga directory at $AppDir"
}

if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    $ApiBaseUrl = "http://192.168.0.195:5001/api"
}

if (-not (Test-Path $IntegrationTestDir)) {
    throw "Cannot find app_manga/integration_test. Create integration tests before running E2E."
}

$PubspecPath = Join-Path $AppDir "pubspec.yaml"
$Pubspec = Get-Content -Path $PubspecPath -Raw
if ($Pubspec -notmatch "(?m)^\s*integration_test\s*:") {
    throw "app_manga/pubspec.yaml is missing dev dependency integration_test with sdk: flutter."
}

Push-Location $AppDir
try {
    if (-not $SkipPubGet) {
        flutter pub get
    }

    $FlutterArgs = @(
        "test"
    )

    if ([string]::IsNullOrWhiteSpace($Target)) {
        $FlutterArgs += "integration_test"
    } else {
        $FlutterArgs += $Target
    }

    $FlutterArgs += "--dart-define=API_BASE_URL=$ApiBaseUrl"

    if (-not [string]::IsNullOrWhiteSpace($Device)) {
        $FlutterArgs += "-d"
        $FlutterArgs += $Device
    }

    Write-Host "Running app_manga E2E with API_BASE_URL=$ApiBaseUrl"
    flutter @FlutterArgs
}
finally {
    Pop-Location
}
