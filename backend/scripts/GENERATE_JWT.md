# Huong dan tao JWT tu script PowerShell

Script: `scripts/generate-jwt-env.ps1`

## Muc tieu

Script se tao key JWT ngau nhien va ghi/cap nhat cac bien sau vao file `.env`:

- `Jwt__Key`
- `Jwt__Issuer`
- `Jwt__Audience`
- `Jwt__AccessTokenMinutes`

## Cach chay nhanh (tu thu muc backend)

```powershell
cd .\backend
.\scripts\generate-jwt-env.ps1
```

## Cach chay tu thu muc goc project (ProjectManga)

```powershell
.\backend\scripts\generate-jwt-env.ps1
```

## Neu bi chan boi Execution Policy

```powershell
powershell -ExecutionPolicy Bypass -File .\backend\scripts\generate-jwt-env.ps1
```

## Tuy chinh tham so

```powershell
.\scripts\generate-jwt-env.ps1 -EnvFilePath ".\.env" -KeySizeBytes 64
```

- `EnvFilePath`: duong dan file `.env` muon ghi.
- `KeySizeBytes`: do dai key truoc khi Base64 (toi thieu `32`, mac dinh `64`).

## Kiem tra ket qua

Sau khi chay, mo file `.env` va dam bao co cac dong:

```env
Jwt__Key=...
Jwt__Issuer=ProjectManga.Api
Jwt__Audience=ProjectManga.Client
Jwt__AccessTokenMinutes=120
```

Script cung in ra console:

- duong dan file `.env` da cap nhat
- do dai `Jwt__Key` (base64 chars)
