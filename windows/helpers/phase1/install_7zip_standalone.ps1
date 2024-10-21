param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)

# Enabled TLS12
$ErrorActionPreference = 'Stop'

## check to see if this version is installed

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "sevenzip_standalone" -Keyname "version" -TargetValue $Version

if($isInstalled -and $isCurrent){
    Write-Host "SevenZip Standalone already installed and current. Skipping"
    return
}

# Script directory is $PSScriptRoot
$sevenZipStandalone ="https://github.com/ip7z/7zip/releases/download/$Version/7zr.exe"

Write-Host -ForegroundColor Green "Installing 7zip Standalone $sevenZipStandalone"
Get-RemoteFile -RemoteFile $sevenZipStandalone -LocalFile "c:\program files\7-zip\7zr.exe" -VerifyHash $Sha256

## Write the version key out to the registry
Set-InstalledVersionKey -Component "sevenzip_standalone" -Keyname "Version" -TargetValue $Version

Write-Host -ForegroundColor Green Done with 7zip Standalone
