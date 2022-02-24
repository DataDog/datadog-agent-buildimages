$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$awscli = 'https://s3.amazonaws.com/aws-cli/AWSCLI64PY3.msi'

## installs awscli inside container
Write-Host -ForegroundColor Green Installing awscli
$out = 'awscli.msi'
$sha256 = "c647a7d738fb4745c08d8b5c9687fc2d4824868d2f350613ed250a2996ead3ed"
(New-Object System.Net.WebClient).DownloadFile($awscli, $out)
if ((Get-FileHash -Algorithm SHA256 $out).Hash -ne "$sha256") { Write-Host \"Wrong hashsum for ${out}: got '$((Get-FileHash -Algorithm SHA256 $out).Hash)', expected '$sha256'.\"; exit 1 }
Start-Process msiexec -ArgumentList '/q /i awscli.msi' -Wait

Remove-Item $out
setx PATH "$Env:Path;c:\program files\amazon\awscli\bin"
$Env:Path="$Env:Path;c:\program files\amazon\awscli\bin"
Write-Host -ForegroundColor Green Done Installing awscli
