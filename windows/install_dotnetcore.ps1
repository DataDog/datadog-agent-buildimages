
# Enabled TLS12
$ErrorActionPreference = 'Stop'

# Script directory is $PSScriptRoot

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Version = "5.0.401"
$url = "https://download.visualstudio.microsoft.com/download/pr/aa5eedba-8906-4e2b-96f8-1b4f06187460/e6757becd35f67b0897bcdda44baec93/dotnet-sdk-5.0.401-win-x64.exe"
Write-Host -ForegroundColor Green "Installing dotnetcore from $($Url)"

$out = "$($PSScriptRoot)\dotnetcoresdk.exe"

Write-Host -ForegroundColor Green Downloading $Url to $out
(New-Object System.Net.WebClient).DownloadFile($Url, $out)

# Skip extraction of XML docs - generally not useful within an image/container - helps performance
setx NUGET_XMLDOC_MODE skip

start-process -FilePath $out -ArgumentList "/install /quiet /norestart" -wait

Remove-Item $out

# Trigger first run experience by running arbitrary cmd
dotnet help

Write-Host -ForegroundColor Green Done with DotNet Core SDK $Version
