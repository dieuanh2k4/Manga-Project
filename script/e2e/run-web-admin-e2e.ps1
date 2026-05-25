param(
    [string]$EnvFile = "",
    [string]$ApiBaseUrl = $env:API_BASE_URL,
    [string]$Target = "",
    [string]$Device = "windows",
    [string]$AdminEmail = $env:WEB_ADMIN_E2E_EMAIL,
    [string]$AdminPassword = $env:WEB_ADMIN_E2E_PASSWORD,
    [string]$MangaTitle = $env:WEB_ADMIN_E2E_MANGA_TITLE,
    [string]$ConnectionString = $env:E2E_CONNECTION_STRING,
    [string]$MinioEndpoint = $env:MINIO_ENDPOINT,
    [string]$MinioPublicEndpoint = $env:MINIO_PUBLIC_ENDPOINT,
    [string]$MinioAccessKey = $env:MINIO_ACCESS_KEY,
    [string]$MinioSecretKey = $env:MINIO_SECRET_KEY,
    [string]$MinioBucket = $env:MINIO_BUCKET,
    [string]$MinioUseSSL = $env:MINIO_USE_SSL,
    [switch]$SkipSeed,
    [switch]$SeedNoReset,
    [switch]$SkipPubGet
)

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$AppDir = Join-Path $RepoRoot "web_admin"
$IntegrationTestDir = Join-Path $AppDir "integration_test"
$SeedScript = Join-Path $PSScriptRoot "seed-e2e-data.ps1"

function Import-DotEnvFile {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return
    }

    Get-Content -Path $Path | ForEach-Object {
        $Line = $_.Trim()
        if ([string]::IsNullOrWhiteSpace($Line) -or $Line.StartsWith("#")) {
            return
        }

        $Parts = $Line.Split("=", 2)
        if ($Parts.Count -ne 2) {
            return
        }

        $Name = $Parts[0].Trim()
        $Value = $Parts[1].Trim().Trim('"').Trim("'")
        if (-not [string]::IsNullOrWhiteSpace($Name)) {
            Set-Item -Path "Env:$Name" -Value $Value
        }
    }
}

function Use-EnvIfBlank {
    param(
        [string]$CurrentValue,
        [string]$EnvName
    )

    if (-not [string]::IsNullOrWhiteSpace($CurrentValue)) {
        return $CurrentValue
    }

    return [Environment]::GetEnvironmentVariable($EnvName)
}

if ([string]::IsNullOrWhiteSpace($EnvFile)) {
    $EnvFile = Join-Path $RepoRoot ".env.e2e"
}

Import-DotEnvFile -Path $EnvFile

$ApiBaseUrl = Use-EnvIfBlank -CurrentValue $ApiBaseUrl -EnvName "API_BASE_URL"
$AdminEmail = Use-EnvIfBlank -CurrentValue $AdminEmail -EnvName "WEB_ADMIN_E2E_EMAIL"
$AdminPassword = Use-EnvIfBlank -CurrentValue $AdminPassword -EnvName "WEB_ADMIN_E2E_PASSWORD"
$MangaTitle = Use-EnvIfBlank -CurrentValue $MangaTitle -EnvName "WEB_ADMIN_E2E_MANGA_TITLE"
$ConnectionString = Use-EnvIfBlank -CurrentValue $ConnectionString -EnvName "E2E_CONNECTION_STRING"
$MinioEndpoint = Use-EnvIfBlank -CurrentValue $MinioEndpoint -EnvName "MINIO_ENDPOINT"
$MinioPublicEndpoint = Use-EnvIfBlank -CurrentValue $MinioPublicEndpoint -EnvName "MINIO_PUBLIC_ENDPOINT"
$MinioAccessKey = Use-EnvIfBlank -CurrentValue $MinioAccessKey -EnvName "MINIO_ACCESS_KEY"
$MinioSecretKey = Use-EnvIfBlank -CurrentValue $MinioSecretKey -EnvName "MINIO_SECRET_KEY"
$MinioBucket = Use-EnvIfBlank -CurrentValue $MinioBucket -EnvName "MINIO_BUCKET"
$MinioUseSSL = Use-EnvIfBlank -CurrentValue $MinioUseSSL -EnvName "MINIO_USE_SSL"

if (-not (Test-Path $AppDir)) {
    throw "Cannot find web_admin directory at $AppDir"
}

if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    $ApiBaseUrl = "http://192.168.0.195:5001/api/"
    # $ApiBaseUrl = "http://10.76.200.178:5001/api/"
}

if (-not $ApiBaseUrl.EndsWith("/")) {
    $ApiBaseUrl = "$ApiBaseUrl/"
}

if (-not (Test-Path $IntegrationTestDir)) {
    throw "Cannot find web_admin/integration_test. Create integration tests before running E2E."
}

$PubspecPath = Join-Path $AppDir "pubspec.yaml"
$Pubspec = Get-Content -Path $PubspecPath -Raw
if ($Pubspec -notmatch "(?m)^\s*integration_test\s*:") {
    throw "web_admin/pubspec.yaml is missing dev dependency integration_test with sdk: flutter."
}

if (-not $SkipSeed) {
    if (-not (Test-Path $SeedScript)) {
        throw "Cannot find E2E seed script at $SeedScript"
    }

    $SeedArgs = @{}
    if (-not [string]::IsNullOrWhiteSpace($EnvFile)) {
        $SeedArgs.EnvFile = $EnvFile
    }
    if (-not [string]::IsNullOrWhiteSpace($ConnectionString)) {
        $SeedArgs.ConnectionString = $ConnectionString
    }
    if (-not [string]::IsNullOrWhiteSpace($MinioEndpoint)) {
        $SeedArgs.MinioEndpoint = $MinioEndpoint
    }
    if (-not [string]::IsNullOrWhiteSpace($MinioPublicEndpoint)) {
        $SeedArgs.MinioPublicEndpoint = $MinioPublicEndpoint
    }
    if (-not [string]::IsNullOrWhiteSpace($MinioAccessKey)) {
        $SeedArgs.MinioAccessKey = $MinioAccessKey
    }
    if (-not [string]::IsNullOrWhiteSpace($MinioSecretKey)) {
        $SeedArgs.MinioSecretKey = $MinioSecretKey
    }
    if (-not [string]::IsNullOrWhiteSpace($MinioBucket)) {
        $SeedArgs.MinioBucket = $MinioBucket
    }
    if (-not [string]::IsNullOrWhiteSpace($MinioUseSSL)) {
        $SeedArgs.MinioUseSSL = $MinioUseSSL
    }
    if ($SeedNoReset) {
        $SeedArgs.NoReset = $true
    }

    & $SeedScript @SeedArgs
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

    if (-not [string]::IsNullOrWhiteSpace($MangaTitle)) {
        $FlutterArgs += "--dart-define=WEB_ADMIN_E2E_MANGA_TITLE=$MangaTitle"
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
