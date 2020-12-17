param (
    [Parameter(Mandatory=$true)][string]$Version
)

# Enabled TLS12
$ErrorActionPreference = 'Stop'

# Script directory is $PSScriptRoot

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$shortenedver = $Version.Replace('.','')
$sevenzip="https://www.7-zip.org/a/7z$($shortenedver)-x64.exe"

Write-Host -ForegroundColor Green "Installing 7zip $sevenzip"
$out = "$($PSScriptRoot)\7zip.exe"
(New-Object System.Net.WebClient).DownloadFile($sevenzip, $out)
Start-Process 7zip.exe -ArgumentList '/S' -Wait
Remove-Item $out
setx PATH "$Env:Path;c:\program files\7-zip"
$Env:Path="$Env:Path;c:\program files\7-zip"
Write-Host -ForegroundColor Green Done with 7zip
