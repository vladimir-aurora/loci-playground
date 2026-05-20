# setup.ps1 — idempotently clone the five upstream repos.
# Safe to re-run; existing checkouts are left alone.
#
# Usage:  pwsh -File setup.ps1

$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot

$repos = @(
    @{ Path = 'micro-ecc/upstream'; Url = 'https://github.com/kmackay/micro-ecc.git' }
    @{ Path = 'littlefs/upstream';  Url = 'https://github.com/littlefs-project/littlefs.git' }
    @{ Path = 'tinycrypt/upstream'; Url = 'https://github.com/intel/tinycrypt.git' }
    @{ Path = 'printf/upstream';    Url = 'https://github.com/eyalroz/printf.git' }
    @{ Path = 'cjson/upstream';     Url = 'https://github.com/DaveGamble/cJSON.git' }
)

foreach ($r in $repos) {
    if (Test-Path "$($r.Path)/.git") {
        Write-Host "[skip] $($r.Path) already cloned"
        continue
    }
    Write-Host "[clone] $($r.Url) -> $($r.Path)"
    git clone --depth 1 $r.Url $r.Path
    if ($LASTEXITCODE -ne 0) { throw "git clone failed for $($r.Url)" }
}

Write-Host ""
Write-Host "Setup complete. Next:"
Write-Host "  pwsh -File build.ps1"
