param(
    [string]$ApiBaseUrl = $env:API_BASE_URL,
    [string]$Target = "",
    [string]$Device = "windows",
    [string]$AdminEmail = $env:WEB_ADMIN_E2E_EMAIL,
    [string]$AdminPassword = $env:WEB_ADMIN_E2E_PASSWORD,
    [switch]$SkipPubGet
)

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$AppDir = Join-Path $RepoRoot "web_admin"
$IntegrationTestDir = Join-Path $AppDir "integration_test"

if (-not (Test-Path $AppDir)) {
    throw "Cannot find web_admin directory at $AppDir"
}

if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    $ApiBaseUrl = "http://192.168.0.195:5001/api/"
}

if (-not (Test-Path $IntegrationTestDir)) {
    throw "Cannot find web_admin/integration_test. Create integration tests before running E2E."
}

$PubspecPath = Join-Path $AppDir "pubspec.yaml"
$Pubspec = Get-Content -Path $PubspecPath -Raw
if ($Pubspec -notmatch "(?m)^\s*integration_test\s*:") {
    throw "web_admin/pubspec.yaml is missing dev dependency integration_test with sdk: flutter."
}

Push-Location $AppDir
try {
    if (-not $SkipPubGet) {
        flutter pub get
    }

    $FlutterArgs = @("test")

    if ([string]::IsNullOrWhiteSpace($Target)) {
        $FlutterArgs += "integration_test"
    } else {
        $FlutterArgs += $Target
    }

    $FlutterArgs += "--dart-define=API_BASE_URL=$ApiBaseUrl"

    if (-not [string]::IsNullOrWhiteSpace($AdminEmail)) {
        $FlutterArgs += "--dart-define=WEB_ADMIN_E2E_EMAIL=$AdminEmail"
    }

    if (-not [string]::IsNullOrWhiteSpace($AdminPassword)) {
        $FlutterArgs += "--dart-define=WEB_ADMIN_E2E_PASSWORD=$AdminPassword"
    }

    if (-not [string]::IsNullOrWhiteSpace($Device)) {
        $FlutterArgs += "-d"
        $FlutterArgs += $Device
    }

    Write-Host "Running web_admin E2E with API_BASE_URL=$ApiBaseUrl on device=$Device"
    flutter @FlutterArgs
}
finally {
    Pop-Location
}
