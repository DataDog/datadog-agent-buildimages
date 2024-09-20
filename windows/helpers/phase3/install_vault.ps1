param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)

$ErrorActionPreference = 'Stop'

$source="https://releases.hashicorp.com/vault/$Version/vault_${Version}_windows_amd64.zip"
$target = "c:\devtools\vault.zip"
$folder = "c:\devtools\vault"
$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "vault" -Keyname "version" -TargetValue $Version
if($isInstalled -and $isCurrent) {
    Write-Host -ForegroundColor Green "vault up to date"
    return
}
if($isInstalled -and -not $isCurrent){
    Remove-Item -Recurse -Force "$folder" -ErrorAction SilentlyContinue
}

Write-Host -ForegroundColor Green "Installing vault $Version"
New-Item -ItemType Directory -Path $folder
Get-RemoteFile -RemoteFile $source -LocalFile $target -VerifyHash $Sha256
Write-Host -ForegroundColor Green "Extracting $target"
Start-Process "7z" -ArgumentList "x -o$folder $target" -Wait
Add-ToPath -NewPath "$folder" -Local -Global
Set-InstalledVersionKey -Component "vault" -Keyname "version" -TargetValue $Version
Write-Host -ForegroundColor Green "Removing temporary file $target"
Remove-Item $target
Write-Host -ForegroundColor Green Done with vault
