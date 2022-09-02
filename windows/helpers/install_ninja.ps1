param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)

$ErrorActionPreference = 'Stop'


$source="https://github.com/ninja-build/ninja/releases/download/v${Version}/ninja-win.zip"
$target = "c:\ninja-build"

DownloadAndExpandTo -TargetDir $target -SourceURL $source -Sha256 $Sha256
Add-ToPath -NewPath "c:\ninja-build" -Global
Write-Host -ForegroundColor Green Done with ninja-build
