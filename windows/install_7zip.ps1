param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
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
if ((Get-FileHash -Algorithm SHA256 $out).Hash -ne "$Sha256") { Write-Host \"Wrong hashsum for ${out}: got '$((Get-FileHash -Algorithm SHA256 $out).Hash)', expected '$Sha256'.\"; exit 1 }

Start-Process 7zip.exe -ArgumentList '/S' -Wait
Remove-Item $out
setx PATH "$Env:Path;c:\program files\7-zip"
$Env:Path="$Env:Path;c:\program files\7-zip"
Write-Host -ForegroundColor Green Done with 7zip
