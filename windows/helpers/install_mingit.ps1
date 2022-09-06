param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)

# Enabled TLS12
$ErrorActionPreference = 'Stop'

# Script directory is $PSScriptRoot

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$mingit = "https://github.com/git-for-windows/git/releases/download/v$($Version).windows.1/MinGit-$($Version)-64-bit.zip"

Write-Host -ForegroundColor Green Installing MinGit
$out = "$($PSScriptRoot)\mingit.zip"
(New-Object System.Net.WebClient).DownloadFile($mingit, $out)
if ((Get-FileHash -Algorithm SHA256 $out).Hash -ne "$Sha256") { Write-Host \"Wrong hashsum for ${out}: got '$((Get-FileHash -Algorithm SHA256 $out).Hash)', expected '$Sha256'.\"; exit 1 }

md c:\devtools\git
& '7z' x -oc:\devtools\git $out

Remove-Item $out
# set path locally so we can initialize git config
setx PATH "$Env:Path;c:\devtools\git\cmd;c:\devtools\git\usr\bin"
$Env:Path="$Env:Path;c:\devtools\git\cmd;c:\devtools\git\usr\bin"
& 'git.exe' config --global user.name "Croissant Builder"
& 'git.exe' config --global user.email "croissant@datadoghq.com"

Write-Host -ForegroundColor Green Done with Git
