#Requires -Version 5.0
<#
.SYNOPSIS
  Configure, build, and install GameNetworkingSockets for Windows x64 + OpenSSL (vcpkg, Ninja, MSVC).

.DESCRIPTION
  Run from a "x64 Native Tools" or Developer PowerShell (or after ilammy/msvc-dev-cmd in CI).
  Optional env: VCPKG_ROOT, VCPKG_COMMIT, PACKAGE_NAME (base name for zip in repo root).
#>
$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path

if (-not $env:VCPKG_ROOT) { $env:VCPKG_ROOT = Join-Path $RepoRoot "vcpkg" }
if (-not $env:VCPKG_COMMIT) { $env:VCPKG_COMMIT = "fba75d09065fcc76a25dcf386b1d00d33f5175af" }

if (-not (Test-Path (Join-Path $env:VCPKG_ROOT ".git"))) {
    git clone https://github.com/microsoft/vcpkg.git $env:VCPKG_ROOT
}
Push-Location $env:VCPKG_ROOT
try {
    git fetch origin $env:VCPKG_COMMIT 2>$null
    git checkout -f $env:VCPKG_COMMIT
    if (-not (Test-Path (Join-Path $env:VCPKG_ROOT "vcpkg.exe"))) {
        & .\bootstrap-vcpkg.bat
    }
}
finally { Pop-Location }

& (Join-Path $env:VCPKG_ROOT "vcpkg.exe") install --triplet=x64-windows

$BuildDir = if ($env:BUILD_DIR) { $env:BUILD_DIR } else { Join-Path $RepoRoot "build-windows-x64" }
$InstallPrefix = if ($env:INSTALL_PREFIX) { $env:INSTALL_PREFIX } else { Join-Path $RepoRoot "install-windows-x64" }
$Toolchain = Join-Path $env:VCPKG_ROOT "scripts\buildsystems\vcpkg.cmake"

$cmakeArgs = @(
    "-B", $BuildDir,
    "-G", "Ninja",
    "-S", $RepoRoot,
    "-DCMAKE_BUILD_TYPE=Release",
    "-DCMAKE_TOOLCHAIN_FILE=$Toolchain",
    "-DUSE_CRYPTO=OpenSSL",
    "-DBUILD_TESTS=OFF", "-DBUILD_EXAMPLES=OFF", "-DBUILD_TOOLS=OFF"
)
cmake @cmakeArgs
cmake --build $BuildDir --verbose
if (Test-Path $InstallPrefix) { Remove-Item -Recurse -Force $InstallPrefix }
cmake --install $BuildDir --prefix $InstallPrefix

if ($env:PACKAGE_NAME) {
    $zipPath = Join-Path $RepoRoot ("{0}.zip" -f $env:PACKAGE_NAME)
    if (Test-Path $zipPath) { Remove-Item -Force $zipPath }
    Compress-Archive -Path (Join-Path $InstallPrefix "*") -DestinationPath $zipPath
    Write-Host "Wrote $zipPath"
}

Write-Host "Installed to $InstallPrefix"
