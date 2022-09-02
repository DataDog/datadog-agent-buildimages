param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)

# Enabled TLS12
$ErrorActionPreference = 'Stop'

# Script directory is $PSScriptRoot



$shortenedver = $Version.Replace('.','')
$sevenzip="https://www.7-zip.org/a/7z$($shortenedver)-x64.exe"

Write-Host -ForegroundColor Green "Installing 7zip $sevenzip"
$out = "$($PSScriptRoot)\7zip.exe"
Get-RemoteFile -RemoteFile $sevenzip -LocalFile $out -VerifyHash $Sha256

Start-Process 7zip.exe -ArgumentList '/S' -Wait
Remove-Item $out
Add-ToPath -NewPath "c:\program files\7-zip" -Local -Global
Write-Host -ForegroundColor Green Done with 7zip
