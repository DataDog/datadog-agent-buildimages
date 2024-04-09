param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)

$ErrorActionPreference = 'Stop'

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "datadog-ci" -Keyname "version" -TargetValue $Version
if($isInstalled -and $isCurrent) {
    Write-Host -ForegroundColor Green "Datadog-ci uploader up to date"
    return
}
if($isInstalled -and -not $isCurrent){
    Remove-Item -Recurse -Force c:\datadog-ci -ErrorAction SilentlyContinue
}
$source="https://github.com/DataDog/datadog-ci/releases/download/v${Version}/datadog-ci_win-x64"
$target = "c:\datadog-ci"

DownloadAndExpandTo -TargetDir $target -SourceURL $source -Sha256 $Sha256
Add-ToPath -NewPath "c:\datadog-ci" -Global
Set-InstalledVersionKey -Component "datadog-ci" -Keyname "version" -TargetValue $Version
Write-Host -ForegroundColor Green Done with datadog-ci
