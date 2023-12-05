param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)

$ErrorActionPreference = 'Stop'

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "rust" -Keyname "version" -TargetValue $Version
if($isInstalled -and $isCurrent) {
    Write-Host -ForegroundColor Green "Rust up to date"
    return
}
# No need to check for previous installations; rust-up will remove them.

$source="https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe"

Write-Host -ForegroundColor Green "Installing rust-up"
$out = "$($PSScriptRoot)\rustup-init.exe"
Get-RemoteFile -RemoteFile $source -LocalFile $out -VerifyHash $Sha256

& $out -y

Set-InstalledVersionKey -Component "rust" -Keyname "version" -TargetValue $Version