

$vcpmsi = 'https://s3.amazonaws.com/dd-agent-omnibus/VCForPython27.msi'

Write-host -ForegroundColor Green Downloading VC++ for Python
$out = "$($PSScriptRoot)\vcp.msi"
$sha256 = "070474db76a2e625513a5835df4595df9324d820f9cc97eab2a596dcbc2f5cbf"

Get-RemoteFile -RemoteFile $vcpmsi -LocalFile $out -VerifyHash $sha256

Write-host -ForegroundColor Green VC++ for Python downloaded, installing...
Start-Process msiexec -ArgumentList '/q /i vcp.msi' -Wait
Remove-Item $out
Write-Host -ForegroundColor Green Done with Visual C++ for Python
