# Install & verify DotSlash
param (
    [Parameter(Mandatory = $true)][string]$Version,
    [Parameter(Mandatory = $true)][string]$Sha256
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
Set-StrictMode -Version 3.0

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component dotslash -Keyname version -TargetValue $Version
if ($isInstalled -and $isCurrent) {
    Write-Host -ForegroundColor Yellow "Skipping dotslash v$Version reinstallation"
    return
}

$targetDir = "c:\devtools\dotslash"
if ($isInstalled -and -not $isCurrent) {
    Remove-Item -Recurse -Force $targetDir -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $targetDir
$archive = "$targetDir\dotslash.tar.gz"
Get-RemoteFile -LocalFile $archive -RemoteFile "https://github.com/facebook/dotslash/releases/download/v$Version/dotslash-windows.tar.gz" -VerifyHash $Sha256
# The system tar is used because GNU tar, which MSYS may put first on PATH, interprets drive letters as remote hosts.
& "$env:SystemRoot\System32\tar.exe" -xzf $archive -C $targetDir dotslash.exe
Remove-Item $archive
Add-ToPath -NewPath $targetDir -Global -Local
Write-Host -ForegroundColor Green "Installed dotslash v$Version"

$output = dotslash --version
if ($output -ne "DotSlash $Version") {
    throw "Unexpected dotslash version: '$output'"
}

Set-InstalledVersionKey -Component dotslash -Keyname version -TargetValue $Version
Write-Host -ForegroundColor Green "Verified dotslash v$Version installation"
