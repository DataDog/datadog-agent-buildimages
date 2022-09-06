param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)


# https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-2.7.4-1/rubyinstaller-2.7.4-1-x64.exe

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "ruby" -Keyname "version" -TargetValue $Version
if($isInstalled -and $isCurrent) {
    Write-Host -ForegroundColor Green "Ruby up to date"
    return
}
if($isInstalled -and -not $isCurrent) {
    Write-Host -ForegroundColor Yellow "Ruby out of date, but not upgrading (yet)"
    return
}
$rubyexe = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-$($Version)/rubyinstaller-$($Version)-x64.exe"

Write-Host  -ForegroundColor Green starting with Ruby
$out = "$($PSScriptRoot)\rubyinstaller.exe"

Get-RemoteFile -RemoteFile $rubyexe -LocalFile $out -VerifyHash $Sha256


Write-Host -ForegroundColor Green Done downloading Ruby, installing
Start-Process $out -ArgumentList '/verysilent /dir="c:\tools\ruby" /tasks="assocfiles,noridkinstall,modpath"' -Wait

Add-ToPath -NewPath "c:\tools\ruby\bin" -Local
Add-EnvironmentVariable -Variable RIDK -Value ((Get-Command ridk).Path) -Global
Start-Process gem -ArgumentList  'install bundler' -Wait


Remove-Item $out
Set-InstalledVersionKey -Component "ruby" -Keyname "version" -TargetValue $Version
Write-Host -ForegroundColor Green Done with Ruby
