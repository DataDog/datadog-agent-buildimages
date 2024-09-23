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
    Remove-Item -Recurse -Force c:\devtools\datadog-ci -ErrorAction SilentlyContinue
}
$source="https://github.com/DataDog/datadog-ci/releases/download/v${Version}/datadog-ci_win-x64"
$folder = "c:\devtools\datadog-ci"
$target = "c:\devtools\datadog-ci\datadog-ci"

New-Item -ItemType Directory -Path $folder
Get-RemoteFile -LocalFile $target -RemoteFile $source -VerifyHash $Sha256
Add-ToPath -NewPath "c:\devtools\datadog-ci" -Local -Global
Set-InstalledVersionKey -Component "datadog-ci" -Keyname "version" -TargetValue $Version
Write-Host -ForegroundColor Green Done with datadog-ci
