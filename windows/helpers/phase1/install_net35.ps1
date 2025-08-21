#
# Installs .NET Runtime 3.5, used by Wix 3.11 and the Visual C++ Compiler for Python 2.7
#
$ErrorActionPreference = "Stop"

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "netfx35" -Keyname "version" -TargetValue "1"
if($isInstalled){
    Write-Host -ForegroundColor Green "NetFX 3.51 already installed"
    return
}
if($Env:DD_DEV_TARGET -ne "Container") {
    $osInfo = Get-CimInstance -classname win32_operatingsystem
    if($osinfo.ProductType -eq "1"){
        & dism /online /add-capability /CapabilityName:Netfx3 /Quiet /NoRestart
        Set-InstalledVersionKey -Component "netfx35" -Keyname "version" -TargetValue "1"
        return
    }
}

$Env:DOTNET_RUNNING_IN_CONTAINER="true"

& dism /online /add-capability /capabilityname:NetFx3
Set-InstalledVersionKey -Component "netfx35" -Keyname "version" -TargetValue "1"
