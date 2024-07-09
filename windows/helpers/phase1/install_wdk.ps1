$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Must be first, because if a developer already has installed the WDK
# then the if condition for the `Get-InstallUpgradeStatus` call will cause this to not be executed.
if (-Not (Test-Path "C:\Program Files (x86)\Windows Kits\10\build\bin\Microsoft.DriverKit.Build.Tasks.17.0.dll")) {
    # Install missing build task
    Write-Host -ForegroundColor Green "Installing missing build tasks"
    # Avoid NuGet rate limits by using cached package in our S3 bucket
    # Get-RemoteFile -RemoteFile "https://www.nuget.org/api/v2/package/Microsoft.Windows.WDK.x64/10.0.26100.1" -LocalFile "c:\tmp\Microsoft.Windows.WDK.x64.10.0.26100.1.nupkg" -VerifyHash "247B2919AE451F65BA5F1CD51C7C39730FB0FC383D607F3E8AB317FDDC8A8239"
    Get-RemoteFile -RemoteFile "https://dd-agent-omnibus.s3.amazonaws.com/microsoft.windows.wdk.x64.10.0.26100.1.nupkg" -LocalFile "c:\tmp\Microsoft.Windows.WDK.x64.10.0.26100.1.nupkg" -VerifyHash "247B2919AE451F65BA5F1CD51C7C39730FB0FC383D607F3E8AB317FDDC8A8239"
    Start-Process "7z" -ArgumentList "x -oc:\tmp c:\tmp\microsoft.windows.wdk.x64.10.0.26100.1.nupkg" -wait
    Copy-Item "c:\tmp\c\build\10.0.26100.0\bin\Microsoft.DriverKit.Build.Tasks.17.0.dll" "C:\Program Files (x86)\Windows Kits\10\build\bin\"
    Copy-Item "c:\tmp\c\build\10.0.26100.0\bin\Microsoft.DriverKit.Build.Tasks.PackageVerifier.17.0.dll" "C:\Program Files (x86)\Windows Kits\10\build\bin\"
    Remove-Item -Force -Recurse "c:\tmp\*"
    Write-Host -ForegroundColor Green "Done with missing build tasks"
}


## $wdk ='https://go.microsoft.com/fwlink/?linkid=2026156'
$wdk = 'https://go.microsoft.com/fwlink/?linkid=2085767' ## 1903 WDK link

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "wdk" -Keyname "DownloadFile" -TargetValue $wdk
if($isInstalled) {
    if(-not $isCurrent){
        Write-Host -ForegroundColor Yellow "Not attempting to upgrade WDK"
    }
    return
}
Write-Host -ForegroundColor Green Installing WDK
$out = "$($PSScriptRoot)\wdksetup.exe"
$sha256 = "c35057cb294096c63bbea093e5024a5fb4120103b20c13fa755c92f227b644e5"
Write-Host -ForegroundColor Green Downloading $wdk to $out

Get-RemoteFile -RemoteFile $wdk -LocalFile $out -VerifyHash $sha256

Get-ChildItem $out
# write file size to make sure it worked
Write-Host -ForegroundColor Green "File size is $((get-item $out).length)"


Start-Process $out -ArgumentList '/q' -Wait

#install WDK.vsix (hack)
if(!(test-path c:\tmp)){
    mkdir c:\tmp
}

# copy the vsix file out of the installed directory
copy-item -Path "C:\Program Files (x86)\Windows Kits\10\Vsix\VS2019\WDK.vsix" -Destination c:\tmp
Start-Process "7z" -ArgumentList "x -oc:\tmp c:\tmp\wdk.vsix" -wait
Copy-Item 'c:\tmp\$MSBuild\Microsoft\*' -Destination "C:\devtools\vstudio\MSBuild\Microsoft" -Recurse -Force

remove-item -Force -Path $out
remove-item -Force -Path c:\tmp\wdk.vsix
#.`clean_tmps.ps1
Set-InstalledVersionKey -Component "wdk" -KeyName "DownloadFile" -TargetValue $wdk
Write-Host -ForegroundColor Green Done with WDK
