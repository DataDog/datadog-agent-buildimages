param (
    [Parameter(Mandatory=$true)][string]$Rustup_Version,
    [Parameter(Mandatory=$true)][string]$Rustup_Sha256,
    [Parameter(Mandatory=$true)][string]$Rust_Version
)

$ErrorActionPreference = 'Stop'

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "rust-up" -Keyname "version" -TargetValue $Rustup_Version
if($isInstalled -and $isCurrent) {
    Write-Host -ForegroundColor Green "Rust-up up to date"
    return
}
# No need to check for previous installations; rust-up will remove them.

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "rust" -Keyname "version" -TargetValue $Rust_Version
if($isInstalled -and $isCurrent) {
    Write-Host -ForegroundColor Green "Rust up to date"
    return
}
# No need to check for previous installations; rust-up will remove them.

$source="https://static.rust-lang.org/rustup/archive/$Rustup_Version/x86_64-pc-windows-msvc/rustup-init.exe"

Write-Host -ForegroundColor Green "Installing rust-up"
$out = "$($PSScriptRoot)\rustup-init.exe"
Get-RemoteFile -RemoteFile $source -LocalFile $out -VerifyHash $Rustup_Sha256

Set-InstalledVersionKey -Component "rust-up" -Keyname "version" -TargetValue $Rustup_Version

Write-Host -ForegroundColor Green "Installing rust"
& $out -y --default-toolchain $Rust_Version

Set-InstalledVersionKey -Component "rust" -Keyname "version" -TargetValue $Rust_Version