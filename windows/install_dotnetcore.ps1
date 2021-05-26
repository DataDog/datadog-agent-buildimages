
# Enabled TLS12
$ErrorActionPreference = 'Stop'

# Script directory is $PSScriptRoot

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Version = "5.0.103"
$url = "https://download.visualstudio.microsoft.com/download/pr/674a9f7d-862e-4f92-91b6-f1cf3fed03ce/e07db4de77ada8da2c23261dfe9db138/dotnet-sdk-5.0.103-win-x64.exe"
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
