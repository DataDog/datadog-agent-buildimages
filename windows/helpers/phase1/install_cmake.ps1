param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)

# Script directory is $PSScriptRoot

$shortenedver = $Version.Replace('.','')
$splitver = $Version.split(".")
$majmin = "$($splitver[0])$($splitver[1])" 

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "CMake" -Keyname "version" -TargetValue $Version
if($isInstalled -and $isCurrent) {
    Write-Host -ForegroundColor Green "CMake up to date"
    return
}
## presumably cmake msi can handle an upgrade, so there's no further difference
## between install and upgrade

# https://github.com/Kitware/CMake/releases/download/v3.23.0/cmake-3.23.0-windows-x86_64.msi
$cmakeurl = "https://github.com/Kitware/CMake/releases/download/v$($Version)/cmake-$($Version)-windows-x86_64.msi"

Write-Host  -ForegroundColor Green starting with CMake
$out = "$($PSScriptRoot)\cmake.msi"

Get-RemoteFile -RemoteFile $cmakeurl -LocalFile $out -VerifyHash $Sha256

Start-Process msiexec -ArgumentList "/q /i $($out) ADD_CMAKE_TO_PATH=System" -Wait

Remove-Item $out
Reload-Path
Set-InstalledVersionKey -Component "CMake" -Keyname "version" -TargetValue $Version
Write-Host -ForegroundColor Green Done with CMake