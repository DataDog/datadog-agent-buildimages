param (
    [Parameter(Mandatory=$true)][string]$Version
)

# Enabled TLS12
$ErrorActionPreference = 'Stop'

# Script directory is $PSScriptRoot

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# https://dist.nuget.org/win-x86-commandline/v5.7.0/nuget.exe

$nugetexe="https://dist.nuget.org/win-x86-commandline/v$($Version)/nuget.exe"

Write-Host -ForegroundColor Green "Downloading nuget"
$out = "$($PSScriptRoot)\nuget.exe"
(New-Object System.Net.WebClient).DownloadFile($sevenzip, $out)

# just put it in it's own directory
mkdir \nuget
Copy-Item $out \nuget\nuget.exe
Remove-Item $out
setx PATH "$Env:Path;c:\nuget"
$Env:Path="$Env:Path;c:\nuget"
Write-Host -ForegroundColor Green Done with Nuget
