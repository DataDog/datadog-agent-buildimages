$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

if(!(test-path c:\docker)){
    mkdir C:\Docker
}

# Docker CLI builds maintained by a Docker engineer
$dockerVersion = "19.03.3"
$out = "C:\Docker\docker.exe"
$sha256 = "2d6ff967c717a38dd41f5ad418396bdeb84642fe04985b30925e38f593d386da"
$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "docker-cli" -Keyname "version" -TargetValue $dockerVersion
if(-not $isInstalled -or -not $isCurrent) {
    Get-RemoteFile -RemoteFile "https://github.com/StefanScherer/docker-cli-builder/releases/download/$dockerVersion/docker.exe" -LocalFile $out -VerifyHash $sha256
    Set-InstalledVersionKey -Component "docker-cli" -Keyname "version" -TargetValue $dockerVersion
}

# Install manifest-tool
$manifestVersion = "v1.0.1"
$out = "C:\Docker\manifest-tool.exe"
$sha256 = "41c08bc1052534f07282eae1f2998e542734b53e79e8d84e4f989ac1c27b2861"
$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "docker-manifest" -Keyname "version" -TargetValue $manifestVersion
if(-not $isInstalled -or -not $isCurrent) {
    Get-RemoteFile -RemoteFile "https://github.com/estesp/manifest-tool/releases/download/$manifestVersion/manifest-tool-windows-amd64.exe" -LocalFile $out -VerifyHash $sha256
    Set-InstalledVersionKey -Component "docker-manifest" -Keyname "version" -TargetValue $manifestVersion
}

# Install notary
$notaryVersion = "v0.6.1"
$out = "C:\Docker\notary.exe"
$sha256 = "9d736f9b569b6a6a3de30cbfa3c60a764acdd445cf4ced760efa9d370bcad64f"
$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "docker-notary" -Keyname "version" -TargetValue $notaryVersion
if(-not $isInstalled -or -not $isCurrent) {
    Get-RemoteFile -RemoteFile "https://github.com/theupdateframework/notary/releases/download/$notaryVersion/notary-Windows-amd64.exe" -LocalFile $out -VerifyHash $sha256
    Set-InstalledVersionKey -Component "docker-notary" -Keyname "version" -TargetValue $notaryVersion
}
# Add Docker to path
Add-ToPath -NewPath "c:\Docker" -Local -Global
