$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Write-Host -ForegroundColor Green "Installing go $ENV:GO_VERSION"

$gozip = "https://dl.google.com/go/go$ENV:GO_VERSION.windows-amd64.zip"

$out = 'go.zip'

Write-Host -ForegroundColor Green "Downloading $gozip to $out"

Get-RemoteFile -RemoteFile $gozip -LocalFile $out -VerifyHash $ENV:GO_SHA256

Write-Host -ForegroundColor Green "Extracting $out to c:\"

Start-Process "7z" -ArgumentList 'x -oc:\ go.zip' -Wait

Write-Host -ForegroundColor Green "Removing temporary file $out"

Remove-Item $out

Add-EnvironmentVariable -Variable GOROOT -VALUE "c:\go" -Local -Global
Add-EnvironmentVariable -Variable GOPATH -VALUE "c:\dev\go" -Global
Add-ToPath -NewPath "c:\go\bin" -Local -Global

Write-Host -ForegroundColor Green "Installed go $ENV:GO_VERSION"

