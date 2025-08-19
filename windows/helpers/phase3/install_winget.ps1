param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)

$wingetexe="https://github.com/microsoft/winget-create/releases/download/v$($Version)/wingetcreate.exe"

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "winget" -Keyname "version" -TargetValue $Version
if($isInstalled -and $isCurrent) {
    Write-Host -ForegroundColor Green "winget up to date"
    return
}

if($installed -and -not $isCurrent){
    Remove-Item -Force \winget\wingetcreate.exe -ErrorAction SilentlyContinue
}
Write-Host -ForegroundColor Green "Downloading winget"
$out = Join-Path ([IO.Path]::GetTempPath()) 'wingetcreate.exe'

Get-RemoteFile -RemoteFile $wingetexe -LocalFile $out -VerifyHash $Sha256

# just put it in it's own directory
if(! (test-path c:\winget)){
    mkdir c:\winget
}
Copy-Item $out c:\winget\wingetcreate.exe
Remove-Item $out
Add-ToPath -NewPath "c:\winget" -Local -Global
Set-InstalledVersionKey -Component "winget" -Keyname "version" -TargetValue $Version
Write-Host -ForegroundColor Green Done with Winget

# Dotnet 6.0 **runtime** is necessary for wingetcreate, install it here
. .\helpers.ps1

$dotnetcore6url = "https://download.visualstudio.microsoft.com/download/pr/3c01bbe6-a49d-468f-8335-f195588f582f/b935469e8480e611eae4d79b2e51965e/dotnet-runtime-6.0.33-win-x64.exe"
$dotnetcore6hash = "DDF16712E509CC7575DB52CE116B004B270538646A098CBC51AB38E9E9CB45E1"
$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "dotnet" -Keyname "DownloadFile" -TargetValue $dotnetcore6url
if($isInstalled -and $isCurrent){
    Write-Host -ForegroundColor Green ".NET Core 6 Up to date"
    return
}
if(-not $isCurrent){
    Write-Host -ForegroundColor Yellow "Attempting to install .NET Core 6"
    ## presumably executable knows how to handle upgrade
}
Write-Host -ForegroundColor Green "Installing dotnet core 6 from $dotnetcore6url"
$out = Join-Path ([IO.Path]::GetTempPath()) 'dotnetcore.exe'

Get-RemoteFile -RemoteFile $dotnetcore6url -LocalFile $out -VerifyHash $dotnetcore6hash
Write-Host -ForegroundColor Green Downloading $dotnetcore6url to $out
start-process -FilePath $out -ArgumentList "/install /quiet /norestart" -wait
Remove-Item $out
Reload-Path

# Print out installed runtimes for visual inspection
dotnet --list-runtimes

# Test wingetcreate to ensure it works
wingetcreate.exe --help
