param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
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
if ((Get-FileHash -Algorithm SHA256 $out).Hash -ne "$Sha256") { Write-Host \"Wrong hashsum for ${out}: got '$((Get-FileHash -Algorithm SHA256 $out).Hash)', expected '$Sha256'.\"; exit 1 }

Write-Host -ForegroundColor Green Done downloading wix, installing

Start-Process $out -ArgumentList '/quiet InstallAllUsers=1' -Wait

setx PATH "$($Env:PATH);c:\program files\Python38;c:\Program files\python38\scripts"
$Env:PATH="$($Env:PATH);c:\program files\Python38;c:\Program files\python38\scripts"
Remove-Item $out

curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python get-pip.py pip==${Env:DD_PIP_VERSION_PY3}
python -m pip install ../requirements.txt

Write-Host -ForegroundColor Green Done with Python
