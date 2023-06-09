param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$ZstdVersion,
    [Parameter(Mandatory=$true)][string]$Sha256
)

# Enabled TLS12
$ErrorActionPreference = 'Stop'

## check to see if this version is installed

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "sevenzip" -Keyname "version" -TargetValue $Version

if($isInstalled -and $isCurrent){
    Write-Host "SevenZip already installed and current.  Skipping"
    return
}
# assuming that exe installer would properly handle upgrade if we ever needed to
# so not installed is the same as not current

# Script directory is $PSScriptRoot
$sevenzip="https://github.com/mcmilk/7-Zip-zstd/releases/download/v$($Version)-v$($ZstdVersion)-R2/7z$($Version)-zstd-x64.exe"

Write-Host -ForegroundColor Green "Installing 7zip $sevenzip"
$out = "$($PSScriptRoot)\7zip.exe"
Get-RemoteFile -RemoteFile $sevenzip -LocalFile $out -VerifyHash $Sha256

Start-Process $out -ArgumentList '/S' -Wait
Remove-Item $out
Add-ToPath -NewPath "c:\program files\7-zip" -Local -Global

## Write the version key out to the registry
Set-InstalledVersionKey -Component "sevenzip" -Keyname "Version" -TargetValue $Version

Write-Host -ForegroundColor Green Done with 7zip
