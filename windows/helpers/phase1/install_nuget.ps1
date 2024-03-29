param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)

# https://dist.nuget.org/win-x86-commandline/v5.7.0/nuget.exe

$nugetexe="https://dist.nuget.org/win-x86-commandline/v$($Version)/nuget.exe"

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "NuGet" -Keyname "version" -TargetValue $Version
if($isInstalled -and $isCurrent) {
    Write-Host -ForegroundColor Green "NuGet up to date"
    return
}
if(-not $isInstalled) {
    Remove-Item -Force "c:\nuget\nuget.exe" -ErrorAction SilentlyContinue
}
Write-Host -ForegroundColor Green "Downloading nuget"
$out = "$($PSScriptRoot)\nuget.exe"

Get-RemoteFile -RemoteFile $nugetexe -LocalFile $out -VerifyHash $Sha256

# just put it in it's own directory
if(! (test-path "c:\nuget")){
    mkdir c:\nuget
}
Copy-Item $out c:\nuget\nuget.exe
Remove-Item $out
Add-ToPath -NewPath "c:\nuget" -Local -Global

Write-Host -ForegroundColor Green Done with Nuget
Set-InstalledVersionKey -Component "NuGet" -Keyname "version" -TargetValue $Version