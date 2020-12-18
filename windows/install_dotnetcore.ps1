
# Enabled TLS12
$ErrorActionPreference = 'Stop'

# Script directory is $PSScriptRoot

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Version = "3.1.403"
$url = "https://download.visualstudio.microsoft.com/download/pr/38136cfe-04d4-4ce8-a8ea-369a800021df/08b29e05cd798d96b5987b417a989b80/dotnet-sdk-3.1.403-win-x64.exe"
Write-Host -ForegroundColor Green "Installing dotnetcore from $($Url)"

$out = "$($PSScriptRoot)\dotnetcoresdk.exe"

Write-Host -ForegroundColor Green Downloading $Url to $out
(New-Object System.Net.WebClient).DownloadFile($Url, $out)

start-process -FilePath $out -ArgumentList "/install /quiet /norestart" -wait

Remove-Item $out
Write-Host -ForegroundColor Green Done with DotNet Core SDK $Version