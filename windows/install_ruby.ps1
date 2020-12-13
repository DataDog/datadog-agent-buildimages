param (
    [Parameter(Mandatory=$true)][string]$Version
)

# Enabled TLS12
$ErrorActionPreference = 'Stop'

# Script directory is $PSScriptRoot

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# https://github.com/oneclick/rubyinstaller2/releases/download/rubyinstaller-2.4.3-1/rubyinstaller-2.4.3-1-x64.exe

$splitver = $Version.split(".")
$majmin = "$($splitver[0]).$($splitver[1]).$($splitver[2])-$($splitver[3])" 

$rubyexe = "https://github.com/oneclick/rubyinstaller2/releases/download/rubyinstaller-$($majmin)/rubyinstaller-$($majmin)-x64.exe"

Write-Host  -ForegroundColor Green starting with Ruby
$out = "$($PSScriptRoot)\rubyinstaller.exe"
(New-Object System.Net.WebClient).DownloadFile($rubyexe, $out)

Write-Host -ForegroundColor Green Done downloading Ruby, installing
Start-Process $out -ArgumentList '/verysilent /dir="c:\tools\ruby24" /tasks="assocfiles,noridkinstall,modpath"' -Wait
$Env:PATH="$Env:PATH;c:\tools\ruby24\bin"
setx RIDK ((Get-Command ridk).Path)
Start-Process gem -ArgumentList  'install bundler' -Wait


Remove-Item $out

Write-Host -ForegroundColor Green Done with Ruby