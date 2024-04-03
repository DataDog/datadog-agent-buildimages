$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Write-Host -ForegroundColor Green "Installing go $ENV:GO_VERSION"

## temporary for MS go
$MS_GO_VERSION = "1.21.8-3"
$MS_GO_LINK="https://aka.ms/golang/release/latest/go$($MS_GO_VERSION).windows-amd64.zip"

$gozip = "https://dl.google.com/go/go$ENV:GO_VERSION.windows-amd64.zip"
$gozip = $MS_GO_LINK
$out = "$($PSScriptRoot)\go.zip"
$hash = "897e8d2b717f5e8d4d16febdcd6a600982d7eda7f352ec6518659b433fee90a5"
##
## because we want to allow multiple versions of GO, we need to handle
## the version check a bit differently.  Get all the installed versions
## and see if this one is present
##
$installedVers =  get-childitem -Path "hklm:\Software\DatadogDeveloper\go" -ErrorAction SilentlyContinue | foreach-object { $_.name | split-path -leaf }
if($installedVers -and $installedVers.Contains($ENV:GO_VERSION)) {
    Write-Host -ForegroundColor Green "Go version $ENV:GO_VERSION already installed"
    return
}
Write-Host -ForegroundColor Green "Downloading $gozip to $out"

Get-RemoteFile -RemoteFile $gozip -LocalFile $out -VerifyHash $hash

## set up proper output directory
$godir = "c:\go\$ENV:GO_VERSION"

Write-Host -ForegroundColor Green "Extracting $out to c:\"

if(!(test-path c:\go)){
    mkdir c:\go
}
Start-Process "7z" -ArgumentList "x -o$($godir) $out" -Wait

Write-Host -ForegroundColor Green "Removing temporary file $out"

Remove-Item $out

Add-EnvironmentVariable -Variable GOROOT -VALUE "$($GODIR)\go" -Local -Global
Add-EnvironmentVariable -Variable GOPATH -VALUE "c:\dev\go" -Global
Add-ToPath -NewPath "$($GODIR)\go\bin" -Local -Global

if(!(test-path "$RegRootPath\Go\$($ENV:GO_VERSION)")){
    New-Item "$RegRootPath\Go\$($ENV:GO_VERSION)" -Force
}
New-ItemProperty -Path "$RegRootPath\Go\$($ENV:GO_VERSION)" -Name "goroot" -Value "$($godir)" -PropertyType String
Write-Host -ForegroundColor Green "Installed go $ENV:GO_VERSION"
