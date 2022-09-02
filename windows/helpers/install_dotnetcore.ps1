. .\helpers.ps1
$Version = "6.0.100"
$url = "https://download.visualstudio.microsoft.com/download/pr/0f71eaf1-ce85-480b-8e11-c3e2725b763a/9044bfd1c453e2215b6f9a0c224d20fe/dotnet-sdk-6.0.100-win-x64.exe"
Write-Host -ForegroundColor Green "Installing dotnetcore from $($Url)"

$out = "$($PSScriptRoot)\dotnetcoresdk.exe"
$sha256 = "1fcf6b9efd37d25e75b426cd8430eb3c006092bee07d748967f1dbfc3f9a0190"

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

Write-Host -ForegroundColor Green Done with DotNet Core SDK $Version
