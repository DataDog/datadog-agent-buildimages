param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)

# Enabled TLS12


# Script directory is $PSScriptRoot

$mingit = "https://github.com/git-for-windows/git/releases/download/v$($Version).windows.1/MinGit-$($Version)-64-bit.zip"

Write-Host -ForegroundColor Green Installing MinGit
$out = "$($PSScriptRoot)\mingit.zip"
Get-RemoteFile -RemoteFile $mingit -LocalFile $out -VerifyHash $Sha256

md c:\devtools\git
& '7z' x -oc:\devtools\git $out

Remove-Item $out
# set path locally so we can initialize git config
Add-ToPath -NewPath "c:\devtools\git\cmd;c:\devtools\git\usr\bin" -Local -Global
& 'git.exe' config --global user.name "Croissant Builder"
& 'git.exe' config --global user.email "croissant@datadoghq.com"

Write-Host -ForegroundColor Green Done with Git
