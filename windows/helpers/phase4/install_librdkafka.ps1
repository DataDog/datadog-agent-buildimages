param (
    [Parameter(Mandatory=$true)][string]$Version
)

Write-Host -ForegroundColor Green "Installing librdkafka $Version"

c:\vcpkg\vcpkg.exe install --x-wait-for-lock  "--x-manifest-root=..\vcpkg\librdkafka\" "--x-install-root=C:\vcpkg\scripts\buildsystems\msbuild\..\..\..\installed\\" --feature-flags=versions

Write-Host -ForegroundColor Green "Installed librdkafka $Version"
