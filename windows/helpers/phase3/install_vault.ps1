$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "vault" -Keyname "version" -TargetValue $ENV:VAULT_VERSION
if($isInstalled -and $isCurrent) {
    Write-Host -ForegroundColor Green "vault up to date"
    return
}
if($isInstalled -and -not $isCurrent){
    Remove-Item -Recurse -Force c:\vault -ErrorAction SilentlyContinue
}
Write-Host -ForegroundColor Green "Installing vault $ENV:VAULT_VERSION"
$vaultzip = "https://releases.hashicorp.com/vault/$ENV:VAULT_VERSION/vault_${ENV:VAULT_VERSION}_windows_amd64.zip"
$out = "$($PSScriptRoot)\vault.zip"

Write-Host -ForegroundColor Green "Downloading $vaultzip to $out"

Get-RemoteFile -RemoteFile $vaultzip -LocalFile $out -VerifyHash $ENV:VAULT_HASH

Write-Host -ForegroundColor Green "Extracting $out to c:\"

Start-Process "7z" -ArgumentList "x -oc:\ $out" -Wait

Write-Host -ForegroundColor Green "Removing temporary file $out"

Remove-Item $out

Add-ToPath -NewPath "c:\vault" -Global
Set-InstalledVersionKey -Component "vault" -Keyname "version" -TargetValue $ENV:VAULT_VERSION
Write-Host -ForegroundColor Green "Installed vault $ENV:VAULT_VERSION"
