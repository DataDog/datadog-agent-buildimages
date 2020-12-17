# Enabled TLS12
$ErrorActionPreference = 'Stop'

# Script directory is $PSScriptRoot

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


$vcpmsi = 'https://download.microsoft.com/download/7/9/6/796EF2E4-801B-4FC4-AB28-B59FBF6D907B/VCForPython27.msi'

Write-host -ForegroundColor Green Downloading VC++ for Python
$out = "$($PSScriptRoot)\vcp.msi"

(New-Object System.Net.WebClient).DownloadFile($vcpmsi, $out)
Write-host -ForegroundColor Green VC++ for Python downloaded, installing...
Start-Process msiexec -ArgumentList '/q /i vcp.msi' -Wait
Remove-Item $out
Write-Host -ForegroundColor Green Done with Visual C++ for Python
