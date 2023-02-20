param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)

$ErrorActionPreference = 'Stop'

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "ninja" -Keyname "version" -TargetValue $Version
if($isInstalled -and $isCurrent) {
    Write-Host -ForegroundColor Green "Ninja up to date"
    return
}
if($isInstalled -and -not $isCurrent){
    Remove-Item -Recurse -Force c:\ninja-build -ErrorAction SilentlyContinue
}
$source="https://github.com/ninja-build/ninja/releases/download/v${Version}/ninja-win.zip"
$target = "c:\ninja-build"

DownloadAndExpandTo -TargetDir $target -SourceURL $source -Sha256 $Sha256
Add-ToPath -NewPath "c:\ninja-build" -Global
Set-InstalledVersionKey -Component "ninja" -Keyname "version" -TargetValue $Version
Write-Host -ForegroundColor Green Done with ninja-build
