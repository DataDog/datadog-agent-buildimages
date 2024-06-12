. .\helpers.ps1

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "dotnetcore" -Keyname "DownloadFile" -TargetValue $env:DOTNETCORE_URL
if($isInstalled -and $isCurrent){
    Write-Host -ForegroundColor Green ".NET Core Up to date"
    return
}
if(-not $isCurrent){
    Write-Host -ForegroundColor Yellow "Attempting to update .NET Core"
    ## presumably executable knows how to handle upgrade
}
Write-Host -ForegroundColor Green "Installing dotnetcore from $($env:DOTNETCORE_URL)"

$out = "$($PSScriptRoot)\dotnetcoresdk.exe"

Get-RemoteFile -RemoteFile $env:DOTNETCORE_URL -LocalFile $out -VerifyHash $env:DOTNETCORE_SHA256
Write-Host -ForegroundColor Green Downloading $env:DOTNETCORE_URL to $out


# Skip extraction of XML docs - generally not useful within an image/container - helps performance
Add-EnvironmentVariable -Variable "NUGET_XMLDOC_NODE" -Value "skip" -Global -Local
#setx NUGET_XMLDOC_MODE skip

start-process -FilePath $out -ArgumentList "/install /quiet /norestart" -wait

Remove-Item $out

Reload-Path
# Trigger first run experience by running arbitrary cmd
dotnet help
Set-InstalledVersionKey -Component "dotnetcore" -Keyname "DownloadFile" -TargetValue $env:DOTNETCORE_URL
Write-Host -ForegroundColor Green Done with DotNet Core SDK $env:DOTNETCORE_VERSION
