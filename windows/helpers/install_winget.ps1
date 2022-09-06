param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)

# Enabled TLS12
$ErrorActionPreference = 'Stop'

# Script directory is $PSScriptRoot

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


$wingetexe="https://github.com/microsoft/winget-create/releases/download/v$($Version)/wingetcreate.exe"

Write-Host -ForegroundColor Green "Downloading winget"
$out = "$($PSScriptRoot)\wingetcreate.exe"
(New-Object System.Net.WebClient).DownloadFile($wingetexe, $out)
if ((Get-FileHash -Algorithm SHA256 $out).Hash -ne "$Sha256") { Write-Host \"Wrong hashsum for ${out}: got '$((Get-FileHash -Algorithm SHA256 $out).Hash)', expected '$Sha256'.\"; exit 1 }

# just put it in it's own directory
mkdir \winget
Copy-Item $out \winget\wingetcreate.exe
Remove-Item $out
setx PATH "$Env:Path;c:\winget"
$Env:Path="$Env:Path;c:\winget"
Write-Host -ForegroundColor Green Done with Winget
