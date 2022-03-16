# Enabled TLS12
$ErrorActionPreference = 'Stop'

# Script directory is $PSScriptRoot

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


$vcpmsi = 'https://s3.amazonaws.com/dd-agent-omnibus/VCForPython27.msi'

Write-host -ForegroundColor Green Downloading VC++ for Python
$out = "$($PSScriptRoot)\vcp.msi"
$sha256 = "070474db76a2e625513a5835df4595df9324d820f9cc97eab2a596dcbc2f5cbf"

(New-Object System.Net.WebClient).DownloadFile($vcpmsi, $out)
if ((Get-FileHash -Algorithm SHA256 $out).Hash -ne "$sha256") { Write-Host \"Wrong hashsum for ${out}: got '$((Get-FileHash -Algorithm SHA256 $out).Hash)', expected '$sha256'.\"; exit 1 }

Write-host -ForegroundColor Green VC++ for Python downloaded, installing...
Start-Process msiexec -ArgumentList '/q /i vcp.msi' -Wait
Remove-Item $out
Write-Host -ForegroundColor Green Done with Visual C++ for Python
