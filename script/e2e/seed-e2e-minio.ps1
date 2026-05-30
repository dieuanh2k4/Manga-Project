param(
    [string]$EnvFile = "",
    [string]$MinioEndpoint = $env:MINIO_ENDPOINT,
    [string]$MinioPublicEndpoint = $env:MINIO_PUBLIC_ENDPOINT,
    [string]$MinioAccessKey = $env:MINIO_ACCESS_KEY,
    [string]$MinioSecretKey = $env:MINIO_SECRET_KEY,
    [string]$MinioBucket = $env:MINIO_BUCKET,
    [string]$MinioUseSSL = $env:MINIO_USE_SSL
)

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$BackendProject = Join-Path $RepoRoot "backend\backend.csproj"

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

$MinioEndpoint = Use-EnvIfBlank -CurrentValue $MinioEndpoint -EnvName "MINIO_ENDPOINT"
$MinioPublicEndpoint = Use-EnvIfBlank -CurrentValue $MinioPublicEndpoint -EnvName "MINIO_PUBLIC_ENDPOINT"
$MinioAccessKey = Use-EnvIfBlank -CurrentValue $MinioAccessKey -EnvName "MINIO_ACCESS_KEY"
$MinioSecretKey = Use-EnvIfBlank -CurrentValue $MinioSecretKey -EnvName "MINIO_SECRET_KEY"
$MinioBucket = Use-EnvIfBlank -CurrentValue $MinioBucket -EnvName "MINIO_BUCKET"
$MinioUseSSL = Use-EnvIfBlank -CurrentValue $MinioUseSSL -EnvName "MINIO_USE_SSL"

if (-not (Test-Path $BackendProject)) {
    throw "Cannot find backend project at $BackendProject"
}

if ([string]::IsNullOrWhiteSpace($MinioBucket)) {
    $MinioBucket = "manga-e2e"
}

if ([string]::IsNullOrWhiteSpace($MinioUseSSL)) {
    $MinioUseSSL = "false"
}

function Set-EnvIfNotBlank {
    param(
        [string]$Name,
        [string]$Value
    )

    if (-not [string]::IsNullOrWhiteSpace($Value)) {
        Set-Item -Path "Env:$Name" -Value $Value
    }
}

Set-Item -Path Env:ASPNETCORE_ENVIRONMENT -Value "E2E"
Set-EnvIfNotBlank -Name "Minio__Endpoint" -Value $MinioEndpoint
Set-EnvIfNotBlank -Name "Minio__PublicEndpoint" -Value $MinioPublicEndpoint
Set-EnvIfNotBlank -Name "Minio__AccessKey" -Value $MinioAccessKey
Set-EnvIfNotBlank -Name "Minio__SecretKey" -Value $MinioSecretKey
Set-EnvIfNotBlank -Name "Minio__Bucket" -Value $MinioBucket
Set-EnvIfNotBlank -Name "Minio__UseSSL" -Value $MinioUseSSL

if ([string]::IsNullOrWhiteSpace($env:Jwt__Key)) {
    Set-Item -Path Env:Jwt__Key -Value "ProjectManga_E2E_Jwt_Key_Change_Me_At_Least_32_Chars"
}

if ([string]::IsNullOrWhiteSpace($env:Jwt__Issuer)) {
    Set-Item -Path Env:Jwt__Issuer -Value "ProjectManga.E2E"
}

if ([string]::IsNullOrWhiteSpace($env:Jwt__Audience)) {
    Set-Item -Path Env:Jwt__Audience -Value "ProjectManga.E2E"
}

Write-Host "Uploading E2E MinIO fixtures to bucket '$MinioBucket'"
dotnet run --project $BackendProject -- --seed-e2e-minio
if ($LASTEXITCODE -ne 0) {
    throw "E2E MinIO fixture upload failed with exit code $LASTEXITCODE."
}

Write-Host "E2E MinIO fixture upload completed."
