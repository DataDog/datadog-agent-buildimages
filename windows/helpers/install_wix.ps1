param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)


$shortenedver = $Version.Replace('.','')
$splitver = $Version.split(".")
$majmin = "$($splitver[0])$($splitver[1])" 

# https://github.com/wixtoolset/wix3/releases/download/wix3112rtm/wix311.exe
$wixzip = "https://github.com/wixtoolset/wix3/releases/download/wix$($shortenedver)rtm/wix$($majmin).exe"

Write-Host  -ForegroundColor Green starting with WiX
$out = "$($PSScriptRoot)\wix.exe"

Get-RemoteFile -RemoteFile $wixzip -LocalFile $out -VerifyHash $Sha256

Write-Host -ForegroundColor Green Done downloading wix, installing
#Start-Process wix.exe -ArgumentList '/quiet' -Wait
Start-Process $out -ArgumentList '/q' -Wait

Add-ToPath -NewPath "${env:ProgramFiles(x86)}\WiX Toolset v3.11\bin\" -Global
Add-EnvironmentVariable -Variable "WIX" -Value "C:\Program Files (x86)\WiX Toolset v3.11\" -Global

Remove-Item $out

Write-Host -ForegroundColor Green Done with WiX