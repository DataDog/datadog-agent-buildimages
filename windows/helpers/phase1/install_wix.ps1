param (
    [Parameter(Mandatory = $true)][string]$Version
)

# Required WiX extensions for the MSI build (must match WiX toolset version):
# - Netfx: .NET Framework detection
# - Util: Utility elements (RemoveFolderEx, EventSource, ServiceConfig, FailWhenDeferred)
# - UI: Standard UI dialogs
$RequiredExtensions = @(
    "WixToolset.Netfx.wixext",
    "WixToolset.Util.wixext",
    "WixToolset.UI.wixext"
)

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "wix" -Keyname "version" -TargetValue $Version
if ($isInstalled -and $isCurrent) {
    Write-Host -ForegroundColor Green "WiX $Version already installed"
    return
}

Write-Host -ForegroundColor Green "Installing WiX $Version..."

& dotnet tool install --global wix --version $Version
if ($LASTEXITCODE -ne 0) {
    throw "Failed to install WiX tools."
}

$dotnetTools = Join-Path $env:USERPROFILE ".dotnet" "tools"
Add-ToPath -NewPath $dotnetTools -Local -Global

foreach ($ext in $RequiredExtensions) {
    $expected = "$ext/$Version"
    Write-Host "Installing WiX extension $expected..."
    & wix extension remove -g $ext
    & wix extension add -g $expected
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install WiX extension $expected."
    }
}

Set-InstalledVersionKey -Component "wix" -Keyname "version" -TargetValue $Version
Write-Host -ForegroundColor Green "Done with WiX $Version"
