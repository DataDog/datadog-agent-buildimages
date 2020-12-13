param (
    [Parameter(Mandatory=$true)][string]$Version
)

# Enabled TLS12
$ErrorActionPreference = 'Stop'

# Script directory is $PSScriptRoot

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$shortenedver = $Version.Replace('.','')
$splitver = $Version.split(".")
$majmin = "$($splitver[0])$($splitver[1])" 

# https://github.com/wixtoolset/wix3/releases/download/wix3112rtm/wix311.exe
$wixzip = "https://github.com/wixtoolset/wix3/releases/download/wix$($shortenedver)rtm/wix$($majmin).exe"

Write-Host  -ForegroundColor Green starting with WiX
$out = "$($PSScriptRoot)\wix.exe"
(New-Object System.Net.WebClient).DownloadFile($wixzip, $out)

Write-Host -ForegroundColor Green Done downloading wix, installing
#Start-Process wix.exe -ArgumentList '/quiet' -Wait
Start-Process $out -ArgumentList '/q' -Wait

#Copy-Item c:\devtools\wix\sdk\inc -Destination c:\devtools\wix\sdk\vs2017\inc -Recurse
#[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";${env:ProgramFiles(x86)}\WiX Toolset v3.11\bin\", [System.EnvironmentVariableTarget]::Machine)
#setx PATH "$Env:Path;C:\devtools\wix"
#$Env:Path="$Env:Path;c:\devtools\wix"
#setx WIX "C:\devtools\wix\"
Remove-Item $out

Write-Host -ForegroundColor Green Done with WiX