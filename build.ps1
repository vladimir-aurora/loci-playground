# build.ps1 — configure + build all five projects for Cortex-M4F with tiarmclang.
#
# Usage:
#   pwsh -File build.ps1                # default tiarmclang at C:/ti/ticlang
#   pwsh -File build.ps1 -Clean         # delete the build dir first
#   $env:TIARMCLANG_DIR='D:/ti/ticlang'; pwsh -File build.ps1   # custom location

param(
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'
Set-Location -Path $PSScriptRoot

$buildDir = '.loci-build'
$toolchain = 'toolchain/cortex-m4-tiarmclang.cmake'

# Resolve the compiler location early so we fail with a useful message.
$ticDir = if ($env:TIARMCLANG_DIR) { $env:TIARMCLANG_DIR } else { 'C:/ti/ticlang' }
$tic    = "$ticDir/bin/tiarmclang.exe"
if (-not (Test-Path $tic)) {
    throw "tiarmclang.exe not found at $tic. Install TI Arm Clang or set `$env:TIARMCLANG_DIR."
}
Write-Host "[info] Using tiarmclang: $tic"

if ($Clean -and (Test-Path $buildDir)) {
    Write-Host "[clean] Removing $buildDir"
    Remove-Item -Recurse -Force $buildDir
}

cmake -B $buildDir -G Ninja "-DCMAKE_TOOLCHAIN_FILE=$toolchain"
if ($LASTEXITCODE -ne 0) { throw 'CMake configure failed' }

cmake --build $buildDir
if ($LASTEXITCODE -ne 0) { throw 'Build failed' }

Write-Host ""
Write-Host "Build complete. Static archives:"
Get-ChildItem -Path $buildDir -Recurse -Include *.a, *.lib, *.obj, *.o |
    Where-Object { $_.Length -gt 0 } |
    Select-Object FullName, Length |
    Format-Table -AutoSize

Write-Host ""
Write-Host "To analyse with LOCI, point any of its skills at $buildDir."
Write-Host "  Example: ask Claude '/exec-trace tc_aes_encrypt' or '/stack-depth lfs_dir_traverse'"
