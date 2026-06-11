. .\helpers.ps1
$Version = "8.0.302"
$url = "https://download.visualstudio.microsoft.com/download/pr/b6f19ef3-52ca-40b1-b78b-0712d3c8bf4d/426bd0d376479d551ce4d5ac0ecf63a5/dotnet-sdk-8.0.302-win-x64.exe"

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "dotnetcore" -Keyname "DownloadFile" -TargetValue $url
if($isInstalled -and $isCurrent){
    Write-Host -ForegroundColor Green ".NET Core Up to date"
    return
}
if(-not $isCurrent){
    Write-Host -ForegroundColor Yellow "Attempting to update .NET Core"
    ## presumably executable knows how to handle upgrade
}
Write-Host -ForegroundColor Green "Installing dotnetcore from $($Url)"

$out = "$($PSScriptRoot)\dotnetcoresdk.exe"
$sha256 = "BC6019E0192EDD180CA7B299A16B95327941B0B53806CDB125BE194AEA12492D"

Get-RemoteFile -RemoteFile $url -LocalFile $out -VerifyHash $sha256
Write-Host -ForegroundColor Green Downloading $Url to $out


# Skip extraction of XML docs - generally not useful within an image/container - helps performance
Add-EnvironmentVariable -Variable "NUGET_XMLDOC_NODE" -Value "skip" -Global -Local
#setx NUGET_XMLDOC_MODE skip

start-process -FilePath $out -ArgumentList "/install /quiet /norestart" -wait

Remove-Item $out

Reload-Path
# Trigger first run experience by running arbitrary cmd
dotnet help
Set-InstalledVersionKey -Component "dotnetcore" -Keyname "DownloadFile" -TargetValue $url
Write-Host -ForegroundColor Green Done with DotNet Core SDK $Version
