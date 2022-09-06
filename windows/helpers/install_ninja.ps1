param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)

$ErrorActionPreference = 'Stop'

function DownloadFile{
    param(
        [Parameter(Mandatory = $true)][string] $TargetFile,
        [Parameter(Mandatory = $true)][string] $SourceURL,
        [Parameter(Mandatory = $true)][string] $Sha256
    )
    $ErrorActionPreference = 'Stop'
    $ProgressPreference = 'SilentlyContinue'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    Write-Host -ForegroundColor Green "Downloading $SourceUrl to $TargetFile"
    (New-Object System.Net.WebClient).DownloadFile($SourceURL, $TargetFile)
    if ((Get-FileHash -Algorithm SHA256 $TargetFile).Hash -ne "$Sha256") { Write-Host \"Wrong hashsum for ${TargetFile}: got '$((Get-FileHash -Algorithm SHA256 $TargetFile).Hash)', expected '$Sha256'.\"; exit 1 }
}

function DownloadAndExpandTo{
    param(
        [Parameter(Mandatory = $true)][string] $TargetDir,
        [Parameter(Mandatory = $true)][string] $SourceURL,
        [Parameter(Mandatory = $true)][string] $Sha256
    )
    $tmpOutFile = New-TemporaryFile

    DownloadFile -TargetFile $tmpOutFile -SourceURL $SourceURL -Sha256 $Sha256

    If(!(Test-Path $TargetDir))
    {
        md $TargetDir
    }

    Start-Process "7z" -ArgumentList "x -o${TargetDir} $tmpOutFile" -Wait
    Remove-Item $tmpOutFile
}

$source="https://github.com/ninja-build/ninja/releases/download/v${Version}/ninja-win.zip"
$target = "c:\ninja-build"

DownloadAndExpandTo -TargetDir $target -SourceURL $source -Sha256 $Sha256
setx PATH "$Env:Path;c:\ninja-build"
$Env:Path="$Env:Path;c:\ninja-build"
Write-Host -ForegroundColor Green Done with ninja-build
