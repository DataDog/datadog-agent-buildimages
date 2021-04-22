# Enabled TLS12
$ErrorActionPreference = 'Stop'

# Script directory is $PSScriptRoot

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


$vcpmsi = 'https://s3.amazonaws.com/dd-agent-omnibus/VCForPython27.msi'

Write-host -ForegroundColor Green Downloading VC++ for Python
$out = "$($PSScriptRoot)\vcp.msi"

(New-Object System.Net.WebClient).DownloadFile($vcpmsi, $out)

if ((Get-FileHash -Algorithm SHA256 $out).Hash -ne "070474DB76A2E625513A5835DF4595DF9324D820F9CC97EAB2A596DCBC2F5CBF")
{
    Write-Error "VCForPython27.msi hash doesn't match"
}

Write-host -ForegroundColor Green VC++ for Python downloaded, installing...
Start-Process msiexec -ArgumentList '/q /i vcp.msi' -Wait
Remove-Item $out
Write-Host -ForegroundColor Green Done with Visual C++ for Python
