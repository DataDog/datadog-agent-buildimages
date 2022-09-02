param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)


$wingetexe="https://github.com/microsoft/winget-create/releases/download/v$($Version)/wingetcreate.exe"

Write-Host -ForegroundColor Green "Downloading winget"
$out = "$($PSScriptRoot)\wingetcreate.exe"

Get-RemoteFile -RemoteFile $wingetexe -LocalFile $out -VerifyHash $Sha256

# just put it in it's own directory
mkdir \winget
Copy-Item $out \winget\wingetcreate.exe
Remove-Item $out
Add-ToPath -NewPath "c:\winget" -Local -Global
Write-Host -ForegroundColor Green Done with Winget
