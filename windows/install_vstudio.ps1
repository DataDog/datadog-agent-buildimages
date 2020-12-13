param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Url
)

# Enabled TLS12
$ErrorActionPreference = 'Stop'

# Script directory is $PSScriptRoot

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host -ForegroundColor Green "Installing Visual Studio $($Version) from $($Url)"

$out = "$($PSROOT)\vs_buildtools.exe"

Write-Host -ForegroundColor Green Downloading $Url to $out
(New-Object System.Net.WebClient).DownloadFile($Url, $out)
# write file size to make sure it worked
Write-Host -ForegroundColor Green "File size is $((get-item $out).length)"
Start-Process $out -ArgumentList  '--quiet --wait --norestart --nocache --installPath c:\devtools\vstudio --add Microsoft.VisualStudio.Workload.NativeDesktop --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64  --add Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Win81 --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Runtimes.x86.x64.Spectre --add Microsoft.VisualStudio.Component.Windows10SDK.17763' -Wait

setx VSTUDIO_ROOT "c:\devtools\vstudio"

Remove-Item $out
Write-Host -ForegroundColor Green Done with Visual Studio