
# Enabled TLS12
$ErrorActionPreference = 'Stop'

# Script directory is $PSScriptRoot

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Version = "7.0.100"
$url = "https://download.visualstudio.microsoft.com/download/pr/5b9d1f0d-9c56-4bef-b950-c1b439489b27/b4aa387715207faa618a99e9b2dd4e35/dotnet-sdk-7.0.100-win-x64.exe"
Write-Host -ForegroundColor Green "Installing dotnetcore from $($Url)"

$out = "$($PSScriptRoot)\dotnetcoresdk.exe"
$sha512 = "32dceb94ca6b2445ec39802d7bb962e2d389801609ffb6706925539380fcb9c9ed75b932daae734ea8d5189d34c956494f50648d3dc3e292392607360bb47f35"

Write-Host -ForegroundColor Green Downloading $Url to $out
(New-Object System.Net.WebClient).DownloadFile($Url, $out)
if ((Get-FileHash -Algorithm SHA512 $out).Hash -ne "$sha512") { Write-Host \"Wrong hashsum for ${out}: got '$((Get-FileHash -Algorithm SHA512 $out).Hash)', expected '$sha512'.\"; exit 1 }

# Skip extraction of XML docs - generally not useful within an image/container - helps performance
setx NUGET_XMLDOC_MODE skip

start-process -FilePath $out -ArgumentList "/install /quiet /norestart" -wait

Remove-Item $out

# Trigger first run experience by running arbitrary cmd
dotnet help

Write-Host -ForegroundColor Green Done with DotNet Core SDK $Version
