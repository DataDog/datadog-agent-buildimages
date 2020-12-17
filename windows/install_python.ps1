param (
    [Parameter(Mandatory=$true)][string]$Version
)

# Enabled TLS12
$ErrorActionPreference = 'Stop'

# Script directory is $PSScriptRoot

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


# https://www.python.org/ftp/python/3.9.1/python-3.9.1-amd64.exe
$pyexe = "https://www.python.org/ftp/python/$($Version)/python-$($Version)-amd64.exe"

Write-Host  -ForegroundColor Green starting with Python
$out = "$($PSScriptRoot)\python.exe"
(New-Object System.Net.WebClient).DownloadFile($pyexe, $out)

Write-Host -ForegroundColor Green Done downloading wix, installing

Start-Process $out -ArgumentList '/quiet InstallAllUsers=1' -Wait

setx PATH "$($Env:PATH);c:\program files\Python38;c:\Program files\python38\scripts"
$Env:PATH="$($Env:PATH);c:\program files\Python38;c:\Program files\python38\scripts"
Remove-Item $out

Write-Host -ForegroundColor Green Done with Python