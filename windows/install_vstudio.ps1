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

$VSPackages = @(
    "Microsoft.VisualStudio.Workload.NativeDesktop",
    "Microsoft.VisualStudio.Component.VC.Tools.x86.x64", 
    "Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Win81",
    "Microsoft.VisualStudio.Workload.VCTools",
    "Microsoft.VisualStudio.Component.VC.Runtimes.x86.x64.Spectre",
    "Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Win81",
#    "Microsoft.VisualStudio.Component.Windows10SDK.17763",
    "Microsoft.VisualStudio.Component.Windows10SDK.18362"
#    "Microsoft.VisualStudio.Component.Windows10SDK.19041"
)

$VSPackageListParam = $VSPackages -join " --add "
$processparams = @{
    FilePath = $out
    NoNewWindow = $true
    Wait = $true
    ArgumentList = "--quiet --wait --norestart --nocache --installPath c:\devtools\vstudio --add $VSPackageListParam"
}
Start-Process @processparams


setx VSTUDIO_ROOT "c:\devtools\vstudio"

# add SDK added above to path for signtool
# C:\Program Files (x86)\Windows Kits\10\bin\10.0.18362.0\x64
[Environment]::SetEnvironmentVariable("Path", [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::Machine) + ";${env:ProgramFiles(x86)}\Windows Kits\10\bin\10.0.18362.0\x64", [System.EnvironmentVariableTarget]::Machine)

Remove-Item $out
Write-Host -ForegroundColor Green Done with Visual Studio