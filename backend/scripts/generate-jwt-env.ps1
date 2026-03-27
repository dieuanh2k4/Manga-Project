param(
    [string]$EnvFilePath = "",
    [int]$KeySizeBytes = 64
)

if ($KeySizeBytes -lt 32) {
    throw "KeySizeBytes must be at least 32."
}

if ([string]::IsNullOrWhiteSpace($EnvFilePath)) {
    $backendRoot = Split-Path -Parent $PSScriptRoot
    $EnvFilePath = Join-Path $backendRoot ".env"
}

function Set-EnvValue {
    param(
        [string[]]$Lines,
        [string]$Name,
        [string]$Value
    )

    $updated = $false
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match "^\s*$([Regex]::Escape($Name))\s*=") {
            $Lines[$i] = "$Name=$Value"
            $updated = $true
            break
        }
    }

    if (-not $updated) {
        $Lines += "$Name=$Value"
    }

    return $Lines
}

$keyBytes = New-Object byte[] $KeySizeBytes
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$rng.GetBytes($keyBytes)
$rng.Dispose()
$jwtKey = [Convert]::ToBase64String($keyBytes)

$lines = @()
if (Test-Path $EnvFilePath) {
    $lines = Get-Content -Path $EnvFilePath
}

$lines = Set-EnvValue -Lines $lines -Name "Jwt__Key" -Value $jwtKey
$lines = Set-EnvValue -Lines $lines -Name "Jwt__Issuer" -Value "ProjectManga.Api"
$lines = Set-EnvValue -Lines $lines -Name "Jwt__Audience" -Value "ProjectManga.Client"
$lines = Set-EnvValue -Lines $lines -Name "Jwt__AccessTokenMinutes" -Value "120"

Set-Content -Path $EnvFilePath -Value $lines -Encoding utf8

Write-Host "Generated and saved JWT configuration to: $EnvFilePath"
Write-Host "Jwt__Key length (base64 chars): $($jwtKey.Length)"
