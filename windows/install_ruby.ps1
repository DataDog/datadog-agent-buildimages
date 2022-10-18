param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)

# Enabled TLS12
$ErrorActionPreference = 'Stop'

# Script directory is $PSScriptRoot

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-2.7.4-1/rubyinstaller-2.7.4-1-x64.exe

$rubyexe = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-$($Version)/rubyinstaller-$($Version)-x64.exe"

Write-Host  -ForegroundColor Green starting with Ruby
$out = "$($PSScriptRoot)\rubyinstaller.exe"
(New-Object System.Net.WebClient).DownloadFile($rubyexe, $out)
if ((Get-FileHash -Algorithm SHA256 $out).Hash -ne "$Sha256") { Write-Host \"Wrong hashsum for ${out}: got '$((Get-FileHash -Algorithm SHA256 $out).Hash)', expected '$Sha256'.\"; exit 1 }

Write-Host -ForegroundColor Green Done downloading Ruby, installing
Start-Process $out -ArgumentList '/verysilent /dir="c:\tools\ruby" /tasks="assocfiles,noridkinstall,modpath"' -Wait
$Env:PATH="$Env:PATH;c:\tools\ruby\bin"
setx RIDK ((Get-Command ridk).Path)
Start-Process gem -ArgumentList  'install bundler -v 2.3.24' -Wait


Remove-Item $out

Write-Host -ForegroundColor Green Done with Ruby
