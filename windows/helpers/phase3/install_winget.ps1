param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)


$wingetexe="https://github.com/microsoft/winget-create/releases/download/v$($Version)/wingetcreate.exe"

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "winget" -Keyname "version" -TargetValue $Version
if($isInstalled -and $isCurrent) {
    Write-Host -ForegroundColor Green "winget up to date"
    return
}

if($installed -and -not $isCurrent){
    Remove-Item -Force \winget\wingetcreate.exe -ErrorAction SilentlyContinue
}
Write-Host -ForegroundColor Green "Downloading winget"
$out = "$($PSScriptRoot)\wingetcreate.exe"

Get-RemoteFile -RemoteFile $wingetexe -LocalFile $out -VerifyHash $Sha256

# just put it in it's own directory
if(! (test-path c:\winget)){
    mkdir c:\winget
}
Copy-Item $out c:\winget\wingetcreate.exe
Remove-Item $out
Add-ToPath -NewPath "c:\winget" -Local -Global
Set-InstalledVersionKey -Component "winget" -Keyname "version" -TargetValue $Version
Write-Host -ForegroundColor Green Done with Winget
