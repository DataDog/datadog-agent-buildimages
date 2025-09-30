param (
    [Parameter(Mandatory=$false)][string]$InstallRoot="c:\devtools\vstudio",
    [Parameter(Mandatory=$false)][switch]$NoQuiet
)

$VSPackages = @(
    "Microsoft.Net.Component.4.6.2.TargetingPack",
    "Microsoft.Net.Component.4.7.2.TargetingPack",
    "Microsoft.Net.Component.4.8.SDK",
    "Microsoft.Net.Component.4.8.TargetingPack",
    "Microsoft.Net.ComponentGroup.4.8.DeveloperTools",
    "Microsoft.NetCore.Component.SDK",
    "Microsoft.VisualStudio.Component.VC.ATL",
    "Microsoft.VisualStudio.Component.VC.Tools.ARM64",
    "Microsoft.VisualStudio.Component.VC.Tools.ARM64EC",
    "Microsoft.VisualStudio.Component.VC.Tools.x86.x64", 
    "Microsoft.VisualStudio.Component.VC.Runtimes.ARM64.Spectre",
    "Microsoft.VisualStudio.Component.VC.Runtimes.ARM64EC.Spectre",
    "Microsoft.VisualStudio.Component.VC.Runtimes.x86.x64.Spectre",
    "Microsoft.VisualStudio.Workload.ManagedDesktop",
    "Microsoft.VisualStudio.Workload.NativeDesktop",
    "Microsoft.VisualStudio.Workload.NetCoreTools",
    "Microsoft.VisualStudio.Workload.WebBuildTools",
    "Microsoft.VisualStudio.Workload.VCTools",
    "Component.Microsoft.Windows.DriverKit.BuildTools",
    "Microsoft.VisualStudio.Component.Windows11SDK.26100"
)

$VSPackagesDesktop = @(
    "Microsoft.VisualStudio.Workload.CoreEditor",
    "Microsoft.VisualStudio.ComponentGroup.NativeDesktop.Core",
    "Microsoft.VisualStudio.Component.IntelliCode"
)

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "vstudio" -Keyname "DownloadFile" -TargetValue $Env:VSINSTALLER_DOWNLOAD_URL

if($isInstalled){
    if(-not $isCurrent){
        Write-Host -ForegroundColor Yellow "Not attempting to upgrade Visual Studio"
    } else {
        Write-Host -ForegroundColor Green "Visual Studio already installed"
    }
    return
}

if($Env:DD_DEV_TARGET -eq "Container") {
    $Sha256 = $Env:VSBUILDTOOLS_SHA256
    $Url = $Env:VSBUILDTOOLS_DOWNLOAD_URL
} else {
    $Sha256 = $Env:VSINSTALLER_SHA256
    $Url = $Env:VSINSTALLER_DOWNLOAD_URL
    $VSPackages += $VSPackagesDesktop
}
Write-Host -ForegroundColor Green "Installing Visual Studio from $($Url)"

$out = Join-Path ([IO.Path]::GetTempPath()) 'vs_buildtools.exe'

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
$st = get-date
Write-Host "Calling Start-Process $st"
Start-Process @processparams
Write-Host "start-process done $st $(get-date)"

Add-EnvironmentVariable -Variable VSTUDIO_ROOT -Value $InstallRoot -Global -Local

Add-ToPath -NewPath "${env:ProgramFiles(x86)}\Windows Kits\10\bin\10.0.26100.0\x64" -Global

Remove-Item $out
Set-InstalledVersionKey -Component vstudio -KeyName "DownloadFile" -TargetValue $Url
Write-Host -ForegroundColor Green Done with Visual Studio
