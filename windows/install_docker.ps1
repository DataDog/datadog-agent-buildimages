$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

mkdir C:\Docker

# Docker CLI builds maintained by a Docker engineer
$dockerVersion = "19.03.3"
$out = "C:\Docker\docker.exe"
$sha256 = "2d6ff967c717a38dd41f5ad418396bdeb84642fe04985b30925e38f593d386da"
Invoke-WebRequest -Uri "https://github.com/StefanScherer/docker-cli-builder/releases/download/$dockerVersion/docker.exe" -OutFile $out
if ((Get-FileHash -Algorithm SHA256 $out).Hash -ne "$sha256") { Write-Host \"Wrong hashsum for ${out}: got '$((Get-FileHash -Algorithm SHA256 $out).Hash)', expected '$sha256'.\"; exit 1 }

# Install manifest-tool
$manifestVersion = "v1.0.1"
$out = "C:\Docker\manifest-tool.exe"
$sha256 = "41c08bc1052534f07282eae1f2998e542734b53e79e8d84e4f989ac1c27b2861"
Invoke-WebRequest -Uri "https://github.com/estesp/manifest-tool/releases/download/$manifestVersion/manifest-tool-windows-amd64.exe" -OutFile $out
if ((Get-FileHash -Algorithm SHA256 $out).Hash -ne "$sha256") { Write-Host \"Wrong hashsum for ${out}: got '$((Get-FileHash -Algorithm SHA256 $out).Hash)', expected '$sha256'.\"; exit 1 }

# Install notary
$notaryVersion = "v0.6.1"
$out = "C:\Docker\notary.exe"
$sha256 = "9d736f9b569b6a6a3de30cbfa3c60a764acdd445cf4ced760efa9d370bcad64f"
Invoke-WebRequest -Uri "https://github.com/theupdateframework/notary/releases/download/$notaryVersion/notary-Windows-amd64.exe" -OutFile $out
if ((Get-FileHash -Algorithm SHA256 $out).Hash -ne "$sha256") { Write-Host \"Wrong hashsum for ${out}: got '$((Get-FileHash -Algorithm SHA256 $out).Hash)', expected '$sha256'.\"; exit 1 }

# Add Docker to path
setx PATH "$Env:Path;C:\Docker"
$Env:Path="$Env:Path;C:\Docker"
