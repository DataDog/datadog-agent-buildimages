param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)

##
## mingit is used in the container version; We'll install the full WinGit
## in developer mode

function InstallMinGit() {
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
}

function InstallWinGit() {
    
    $wingit = $Env:WINGIT_URL
    $Sha256 = $Env:WINGIT_SHA256
    $isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "git" -Keyname "version" -TargetValue $wingit
    if($isInstalled -and $isCurrent){
        Write-Host -ForegroundColor Green "WinGit already installed"
        return
    }
    Write-Host -ForegroundColor Green "Installing WinGit"
    $out = "$($PSScriptRoot)\wingit.exe"
    Get-RemoteFile -RemoteFile $wingit -LocalFile $out -VerifyHash $Sha256

    Start-Process $out -ArgumentList "/VERYSILENT" -Wait -NoNewWindow
    Remove-Item $out
    # set path locally so we can initialize git config
    Reload-Path
    Set-InstalledVersionKey -Component "git" -Keyname "Version" -TargetValue $wingit
    Write-Host -ForegroundColor Green Done with Git
}

if($Env:DD_DEV_TARGET -eq "Container") {
    InstallMinGit
    return
} else {
    InstallWinGit
    return
}
return
