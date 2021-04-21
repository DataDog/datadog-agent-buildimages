# Enabled TLS12
$ErrorActionPreference = 'Stop'

# Script directory is $PSScriptRoot

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


$vcpmsi = 'https://s3.amazonaws.com/dd-agent-omnibus/VCForPython27.msi'

Write-host -ForegroundColor Green Downloading VC++ for Python
$out = "$($PSScriptRoot)\vcp.msi"

(New-Object System.Net.WebClient).DownloadFile($vcpmsi, $out)

if ((Get-FileHash -Algorithm MD5 $out).Hash -ne "4E6342923A8153A94D44FF7307FCDD1F")
{
    Write-Error "VCForPython27.msi hash doesn't match"
}

Write-host -ForegroundColor Green VC++ for Python downloaded, installing...
Start-Process msiexec -ArgumentList '/q /i vcp.msi' -Wait
Remove-Item $out
Write-Host -ForegroundColor Green Done with Visual C++ for Python
