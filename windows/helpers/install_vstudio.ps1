param (
    [Parameter(Mandatory=$false)][string]$InstallRoot="c:\devtools\vstudio",
    [Parameter(Mandatory=$false)][switch]$NoQuiet
)


$VSPackages = @(
    "Microsoft.VisualStudio.Workload.ManagedDesktop",
    "Microsoft.VisualStudio.Workload.NetCoreTools",
    "Microsoft.VisualStudio.Workload.NativeDesktop",
    "Microsoft.VisualStudio.Workload.WebBuildTools",
    "Microsoft.NetCore.Component.SDK",
    "Microsoft.Net.Component.4.7.TargetingPack",
    "Microsoft.Net.Component.4.5.TargetingPack",
    "Microsoft.Net.Component.4.6.1.TargetingPack",
    "Microsoft.Net.Component.4.8.SDK",
    "Microsoft.VisualStudio.Component.FSharp",
    "Microsoft.VisualStudio.Component.FSharp.WebTemplates",
    "Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Win81",
    "Microsoft.VisualStudio.Workload.VCTools",
    "Microsoft.VisualStudio.Component.VC.ATL",
    "Microsoft.VisualStudio.Component.VC.Tools.x86.x64", 
    "Microsoft.VisualStudio.Component.VC.Runtimes.x86.x64.Spectre",
    "Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Win81",
#    "Microsoft.VisualStudio.Component.Windows10SDK.17763",
    "Microsoft.VisualStudio.Component.Windows10SDK.18362"
#    "Microsoft.VisualStudio.Component.Windows10SDK.19041"
)

$VSPackagesDesktop = @(
    "Microsoft.VisualStudio.Workload.CoreEditor",
    "Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Core",
    "Microsoft.VisualStudio.Component.IntelliCode"
)

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "vstudio" -Keyname "DownloadFile" -TargetValue $Env:VS2019INSTALLER_DOWNLOAD_URL

if($isInstalled){
    if(-not $isCurrent){
        Write-Host -ForegroundColor Yellow "Not attempting to upgrade Visual Studio"
    } else {
        Write-Host -ForegroundColor Green "Visual Studio already installed"
    }
    return
}

if($Env:DD_DEV_TARGET -eq "Container") {
    $Sha256 = $Env:VS2017BUILDTOOLS_SHA256
    $Url = $Env:VS2017BUILDTOOLS_DOWNLOAD_URL
} else {
    $Sha256 = $Env:VS2019INSTALLER_SHA256
    $Url = $Env:VS2019INSTALLER_DOWNLOAD_URL
    $VSPackages += $VSPackagesDesktop
}
Write-Host -ForegroundColor Green "Installing Visual Studio from $($Url)"

$out = "$($PSScriptRoot)\vs_buildtools.exe"

Write-Host -ForegroundColor Green Downloading $Url to $out
Get-RemoteFile -RemoteFile $Url -LocalFile $out -VerifyHash $Sha256

# write file size to make sure it worked
Write-Host -ForegroundColor Green "File size is $((get-item $out).length)"
$VSPackageListParam = $VSPackages -join " --add "
$ArgList = "--wait --norestart --nocache --installPath `"$($InstallRoot)`" --add $VSPackageListParam"
if(-not $NoQuiet){
    $ArgList = "--quiet $ArgList"
}
$processparams = @{
    FilePath = $out
    NoNewWindow = $true
    Wait = $true
    ArgumentList = $ArgList
}
Start-Process @processparams

Add-EnvironmentVariable -Variable VSTUDIO_ROOT -Value $InstallRoot -Global -Local

Add-ToPath -NewPath "${env:ProgramFiles(x86)}\Windows Kits\10\bin\10.0.18362.0\x64" -Global

Remove-Item $out
Set-InstalledVersionKey -Component vstudio -KeyName "DownloadFile" -TargetValue $Url
Write-Host -ForegroundColor Green Done with Visual Studio
