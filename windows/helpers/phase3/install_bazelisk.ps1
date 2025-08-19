# Install & verify Bazelisk (standalone binary ditribution) as Bazel bootstrapper
param (
    [Parameter(Mandatory = $true)][string]$Version,
    [Parameter(Mandatory = $true)][string]$Sha256
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
Set-StrictMode -Version 3.0

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component bazelisk -Keyname version -TargetValue $Version
if ($isInstalled -and $isCurrent) {
    Write-Host -ForegroundColor Yellow "Skipping bazelisk v$Version reinstallation"
    return
}

$targetDir = "c:\devtools\bazelisk"
if ($isInstalled -and -not $isCurrent) {
    Remove-Item -Recurse -Force $targetDir -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $targetDir
Get-RemoteFile -LocalFile "$targetDir\bazelisk.exe" -RemoteFile "https://github.com/bazelbuild/bazelisk/releases/download/v$Version/bazelisk-windows-amd64.exe" -VerifyHash $Sha256
Push-Location $targetDir
try {
    New-Item -ItemType SymbolicLink -Path "bazel.exe" -Target "bazelisk.exe"
} finally {
    Pop-Location
}
Add-ToPath -NewPath $targetDir -Global -Local
Write-Host -ForegroundColor Green "Installed bazelisk v$Version"

$bazeliskHome = (New-Item -ItemType Directory -Path (Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName()))).FullName
try {
    $output = & {
        $env:BAZELISK_HOME = "$bazeliskHome"
        $env:USE_BAZEL_VERSION = '7.6.1'
        bazel --version
    }
    if ($output -ne 'bazel 7.6.1') {
        throw "Unexpected bazel version: '$output'"
    }
} finally {
    Remove-Item -Recurse -Verbose "$bazeliskHome"
}

Set-InstalledVersionKey -Component bazelisk -Keyname version -TargetValue $Version
Write-Host -ForegroundColor Green "Verified bazelisk v$Version installation"
