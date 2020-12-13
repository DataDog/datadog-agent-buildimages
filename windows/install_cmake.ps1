param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Arch
)

# Enabled TLS12
$ErrorActionPreference = 'Stop'

# Script directory is $PSScriptRoot

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$shortenedver = $Version.Replace('.','')
$splitver = $Version.split(".")
$majmin = "$($splitver[0])$($splitver[1])" 

# https://github.com/Kitware/CMake/releases/download/v3.19.1/cmake-3.19.1-win64-x64.msi
# https://github.com/Kitware/CMake/releases/download/v3.19.1/cmake-3.19.1-win32-x86.msi
$cmakeurl = ""
if($Arch -eq 'x64' ) {
    $cmakeurl = "https://github.com/Kitware/CMake/releases/download/v$($Version)/cmake-$($Version)-win64-x64.msi"
} else {
    $cmakeurl = "https://github.com/Kitware/CMake/releases/download/v$($Version)/cmake-$($Version)-win32-x86.msi"
}


Write-Host  -ForegroundColor Green starting with CMake
$out = "$($PSScriptRoot)\cmake.msi"
(New-Object System.Net.WebClient).DownloadFile($cmakeurl, $out)


Start-Process msiexec -ArgumentList "/q /i $($out) ADD_CMAKE_TO_PATH=System" -Wait

Remove-Item $out

Write-Host -ForegroundColor Green Done with CMake