$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$awscli = 'https://s3.amazonaws.com/aws-cli/AWSCLI64PY3.msi'

## installs awscli inside container
Write-Host -ForegroundColor Green Installing awscli
$out = 'awscli.msi'
$sha256 = "e930336fb14872f6bd8fd2a6856d5a3052ad457fd8cd0279c97c629487a05b26"
(New-Object System.Net.WebClient).DownloadFile($awscli, $out)
Start-Process msiexec -ArgumentList '/q /i awscli.msi' -Wait
if ((Get-FileHash -Algorithm SHA256 $out).Hash -ne "$sha256") { Write-Host \"Wrong hashsum for ${out}: got '$((Get-FileHash -Algorithm SHA256 $out).Hash)', expected '$sha256'.\"; exit 1 }

Remove-Item $out
setx PATH "$Env:Path;c:\program files\amazon\awscli\bin"
$Env:Path="$Env:Path;c:\program files\amazon\awscli\bin"
Write-Host -ForegroundColor Green Done Installing awscli
