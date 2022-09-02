param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)

# https://dist.nuget.org/win-x86-commandline/v5.7.0/nuget.exe

$nugetexe="https://dist.nuget.org/win-x86-commandline/v$($Version)/nuget.exe"

Write-Host -ForegroundColor Green "Downloading nuget"
$out = "$($PSScriptRoot)\nuget.exe"

Get-RemoteFile -RemoteFile $nugetexe -LocalFile $out -VerifyHash $Sha256

# just put it in it's own directory
mkdir \nuget
Copy-Item $out \nuget\nuget.exe
Remove-Item $out
Add-ToPath -NewPath "c:\nuget" -Local -Global

Write-Host -ForegroundColor Green Done with Nuget
