param(
    [string]$EnvFile = "",
    [string]$ApiBaseUrl = $env:API_BASE_URL,
    [string]$Target = "",
    [string]$Device = "",
    [string]$AppUserName = $env:APP_MANGA_E2E_USERNAME,
    [string]$AppPassword = $env:APP_MANGA_E2E_PASSWORD,
    [string]$MangaTitle = $env:APP_MANGA_E2E_MANGA_TITLE,
    [string]$ChapterTitle = $env:APP_MANGA_E2E_CHAPTER_TITLE,
    [string]$SearchQuery = $env:APP_MANGA_E2E_SEARCH_QUERY,
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
$AppDir = Join-Path $RepoRoot "app_manga"
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
$AppUserName = Use-EnvIfBlank -CurrentValue $AppUserName -EnvName "APP_MANGA_E2E_USERNAME"
$AppPassword = Use-EnvIfBlank -CurrentValue $AppPassword -EnvName "APP_MANGA_E2E_PASSWORD"
$MangaTitle = Use-EnvIfBlank -CurrentValue $MangaTitle -EnvName "APP_MANGA_E2E_MANGA_TITLE"
$ChapterTitle = Use-EnvIfBlank -CurrentValue $ChapterTitle -EnvName "APP_MANGA_E2E_CHAPTER_TITLE"
$SearchQuery = Use-EnvIfBlank -CurrentValue $SearchQuery -EnvName "APP_MANGA_E2E_SEARCH_QUERY"
$ConnectionString = Use-EnvIfBlank -CurrentValue $ConnectionString -EnvName "E2E_CONNECTION_STRING"
$MinioEndpoint = Use-EnvIfBlank -CurrentValue $MinioEndpoint -EnvName "MINIO_ENDPOINT"
$MinioPublicEndpoint = Use-EnvIfBlank -CurrentValue $MinioPublicEndpoint -EnvName "MINIO_PUBLIC_ENDPOINT"
$MinioAccessKey = Use-EnvIfBlank -CurrentValue $MinioAccessKey -EnvName "MINIO_ACCESS_KEY"
$MinioSecretKey = Use-EnvIfBlank -CurrentValue $MinioSecretKey -EnvName "MINIO_SECRET_KEY"
$MinioBucket = Use-EnvIfBlank -CurrentValue $MinioBucket -EnvName "MINIO_BUCKET"
$MinioUseSSL = Use-EnvIfBlank -CurrentValue $MinioUseSSL -EnvName "MINIO_USE_SSL"

if (-not (Test-Path $AppDir)) {
    throw "Cannot find app_manga directory at $AppDir"
}

if ([string]::IsNullOrWhiteSpace($ApiBaseUrl)) {
    $ApiBaseUrl = "http://192.168.0.195:5001/api"
    # $ApiBaseUrl = "http://10.76.200.178:5001/api"
}

if (-not (Test-Path $IntegrationTestDir)) {
    throw "Cannot find app_manga/integration_test. Create integration tests before running E2E."
}

$PubspecPath = Join-Path $AppDir "pubspec.yaml"
$Pubspec = Get-Content -Path $PubspecPath -Raw
if ($Pubspec -notmatch "(?m)^\s*integration_test\s*:") {
    throw "app_manga/pubspec.yaml is missing dev dependency integration_test with sdk: flutter."
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

    $FlutterArgs = @(
        "test"
    )

    if ([string]::IsNullOrWhiteSpace($Target)) {
        $FlutterArgs += "integration_test"
    } else {
        $FlutterArgs += $Target
    }

    $FlutterArgs += "--dart-define=API_BASE_URL=$ApiBaseUrl"

    if (-not [string]::IsNullOrWhiteSpace($AppUserName)) {
        $FlutterArgs += "--dart-define=APP_MANGA_E2E_USERNAME=$AppUserName"
    }

    if (-not [string]::IsNullOrWhiteSpace($AppPassword)) {
        $FlutterArgs += "--dart-define=APP_MANGA_E2E_PASSWORD=$AppPassword"
    }

    if (-not [string]::IsNullOrWhiteSpace($MangaTitle)) {
        $FlutterArgs += "--dart-define=APP_MANGA_E2E_MANGA_TITLE=$MangaTitle"
    }

    if (-not [string]::IsNullOrWhiteSpace($ChapterTitle)) {
        $FlutterArgs += "--dart-define=APP_MANGA_E2E_CHAPTER_TITLE=$ChapterTitle"
    }

    if (-not [string]::IsNullOrWhiteSpace($SearchQuery)) {
        $FlutterArgs += "--dart-define=APP_MANGA_E2E_SEARCH_QUERY=$SearchQuery"
    }

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
