$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host -ForegroundColor Green Installing Google Cloud SDK
$gsdk = 'https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-315.0.0-windows-x86_64.zip'
$out = 'gsdk.zip'

Write-Host -ForegroundColor Green Downloading $gsdk to $out
(New-Object System.Net.WebClient).DownloadFile($gsdk, $out)
Get-ChildItem $out

# write file size to make sure it worked
Write-Host -ForegroundColor Green "File size is $((get-item $out).length)"

Expand-Archive gsdk.zip -DestinationPath C:
Remove-Item $out

# add to path
$pwd = pwd
setx PATH "$Env:Path;$pwd\google-cloud-sdk\bin"
$Env:Path="$Env:Path;$pwd\google-cloud-sdk\bin"

Write-Host -ForegroundColor Green Done Installing Google Cloud SDK
