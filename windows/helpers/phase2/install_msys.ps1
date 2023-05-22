param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)
$InstallPath = "c:\tools"
<#
.SYNOPSIS
 Invoke-Msys2Shell  Runs the shell once to do first-time startup.  

.NOTES
Taken from chocolatey installer.
#>
function Invoke-Msys2Shell($Arguments) {
    if (![string]::IsNullOrWhiteSpace($Arguments)) { $Arguments += "; " }
    $Arguments += "ps -ef | grep '[?]' | awk '{print `$2}' | xargs -r kill"
    $basepath = Join-Path $InstallPath msys64

    $params = @{
        FilePath     = Join-Path $basepath msys2_shell.cmd
        NoNewWindow  = $true
        Wait         = $true
#        PassThru     = $true
        ArgumentList = "-defterm", "-no-start", "-c", "`"$Arguments`""
    }
    Write-Host "Invoking msys2 shell command:" $params.ArgumentList
    $p = Start-Process @params
    return $lastExitCode
}
$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "msys" -Keyname "version" -TargetValue $Version
if($isInstalled -and $isCurrent) {
    Write-Host -ForegroundColor Green "MSys up to date"
    return
}
if($isInstalled -and -not $isCurrent) {
    Write-Host -ForegroundColor Yellow "upgrading MSYS"
    Remove-Item -Recurse -Force "$($InstallPath)\msys64"
}
# https://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-20200629.tar.xz
$msyszip = "https://repo.msys2.org/distrib/x86_64/msys2-base-x86_64-$($Version).tar.xz"

Write-Host  -ForegroundColor Green starting with MSYS
$out = "$($PSScriptRoot)\msys.tar.xz"

Get-RemoteFile -RemoteFile $msyszip -LocalFile $out -VerifyHash $Sha256

# uncompress the tar-xz into a tar
$msystar = "msys.tar"
& 7z x $out
start-process 7z -ArgumentList "x -o$($InstallPath) $msystar" -Wait

Remove-Item $out
Remove-Item $msystar

## invoke the first-run shell
$mshell = Invoke-Msys2Shell
Write-Host -ForegroundColor Yellow "Invoke-Msys2Shell return code $mshell"
if ( $mshell -ne "0") {
    throw "Invoke MSYS returned $mshell"
}

ridk install 3
If ($lastExitCode -ne "0") { 
    throw "ridk install 3 returned $lastExitCode" 
}
# Downgrade gcc and binutils due to https://github.com/golang/go/issues/46099
Get-RemoteFile -RemoteFile "https://s3.amazonaws.com/dd-agent-omnibus/mingw-w64-x86_64-gcc-10.2.0-11-any.pkg.tar.zst" -LocalFile "C:/mingw-w64-x86_64-gcc-10.2.0-11-any.pkg.tar.zst"
Get-RemoteFile -RemoteFile "https://s3.amazonaws.com/dd-agent-omnibus/mingw-w64-x86_64-gcc-libs-10.2.0-11-any.pkg.tar.zst" -LocalFile "C:/mingw-w64-x86_64-gcc-libs-10.2.0-11-any.pkg.tar.zst"
Get-RemoteFile -RemoteFile "https://s3.amazonaws.com/dd-agent-omnibus/mingw-w64-x86_64-binutils-2.35.1-2-any.pkg.tar.zst" -LocalFile "C:/mingw-w64-x86_64-binutils-2.35.1-2-any.pkg.tar.zst"
& C:\tools\msys64\msys2_shell.cmd -defterm -no-start -c "pacman --noconfirm -U /c/mingw-w64-x86_64-binutils-2.35.1-2-any.pkg.tar.zst /c/mingw-w64-x86_64-gcc-libs-10.2.0-11-any.pkg.tar.zst /c/mingw-w64-x86_64-gcc-10.2.0-11-any.pkg.tar.zst"

Remove-Item c:\*.zst
Set-InstalledVersionKey -Component "msys" -Keyname "version" -TargetValue $Version
Write-Host -ForegroundColor Green Done with MSYS