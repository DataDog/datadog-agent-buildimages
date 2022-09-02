$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


## $wdk ='https://go.microsoft.com/fwlink/?linkid=2026156'
$wdk = 'https://go.microsoft.com/fwlink/?linkid=2085767' ## 1903 WDK link

Write-Host -ForegroundColor Green Installing WDK
$out = 'wdksetup.exe'
$sha256 = "c35057cb294096c63bbea093e5024a5fb4120103b20c13fa755c92f227b644e5"
Write-Host -ForegroundColor Green Downloading $wdk to $out

Get-RemoteFile -RemoteFile $wdk -LocalFile $out -VerifyHash $sha256

Get-ChildItem $out
# write file size to make sure it worked
Write-Host -ForegroundColor Green "File size is $((get-item $out).length)"


Start-Process $out -ArgumentList '/q' -Wait

#install WDK.vsix (hack)
mkdir \tmp

# copy the vsix file out of the installed directory
copy-item -Path "C:\Program Files (x86)\Windows Kits\10\Vsix\VS2019\WDK.vsix" -Destination c:\tmp
Start-Process "7z" -ArgumentList "x -oc:\tmp c:\tmp\wdk.vsix" -wait
Copy-Item 'c:\tmp\$MSBuild\Microsoft\*' -Destination "C:\devtools\vstudio\MSBuild\Microsoft" -Recurse -Force

remove-item -Force -Path $out
remove-item -Force -Path c:\tmp\wdk.vsix
#.`clean_tmps.ps1
Write-Host -ForegroundColor Green Done with WDK