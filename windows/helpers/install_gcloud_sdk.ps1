$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host -ForegroundColor Green Installing Google Cloud SDK
$version = $ENV:GCLOUD_SDK_VERSION
$gsdk = "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-$version-windows-x86_64.zip"
$out = "$($PSScriptRoot)\gsdk.zip"
$sha256 = $ENV:GCLOUD_SDK_SHA256

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "GCloudSDK" -Keyname "version" -TargetValue $version
if($isInstalled) {
    if($isCurrent){
        return
    } else {
        Remove-item -Recurse -Force c:\google-cloud-sdk -ErrorAction SilentlyContinue
    }
}
Write-Host -ForegroundColor Green Downloading $gsdk to $out

Get-RemoteFile -RemoteFile $gsdk -LocalFile $out -VerifyHash $sha256

Get-ChildItem $out

# write file size to make sure it worked
Write-Host -ForegroundColor Green "File size is $((get-item $out).length)"

Expand-Archive $out -DestinationPath C:\ -ProgressPreference Silen
Remove-Item $out

# add to path
#$pwd = pwd
Add-ToPath -NewPath "c:\google-cloud-sdk\bin" -Local -Global
Set-InstalledVersionKey -Component "GCloudSDK" -Keyname "version" -TargetValue $version
Write-Host -ForegroundColor Green Done Installing Google Cloud SDK
