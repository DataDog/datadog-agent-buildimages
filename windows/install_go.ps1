$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Write-Host -ForegroundColor Green "Installing go $ENV:GO_VERSION"

$gozip = "https://dl.google.com/go/go$ENV:GO_VERSION.windows-amd64.zip"
if ($Env:TARGET_ARCH -eq "x86") {
    $gozip = "https://dl.google.com/go/go$ENV:GO_VERSION.windows-386.zip"
}

$out = 'go.zip'

Write-Host -ForegroundColor Green "Downloading $gozip to $out"

(New-Object System.Net.WebClient).DownloadFile($gozip, $out)

Write-Host -ForegroundColor Green "Extracting $out to c:\"

Start-Process "7z" -ArgumentList 'x -oc:\ go.zip' -Wait

Write-Host -ForegroundColor Green "Removing temporary file $out"

Remove-Item $out

setx GOROOT c:\go
$Env:GOROOT="c:\go"
setx PATH "$Env:Path;c:\go\bin;"
$Env:Path="$Env:Path;c:\go\bin;"

Write-Host -ForegroundColor Green "Installed go $ENV:GO_VERSION"

