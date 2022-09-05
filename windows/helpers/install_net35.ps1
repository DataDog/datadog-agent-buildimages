#
# Installs .NET Runtime 3.5, used by Wix 3.11 and the Visual C++ Compiler for Python 2.7
#
$ErrorActionPreference = "Stop"

$UpgradeTable = @{
    1607 = @{
        netfxzip = "https://dotnetbinaries.blob.core.windows.net/dockerassets/microsoft-windows-netfx3-ltsc2016.zip";
        netfxsha256 = "303866ec4f396fda465d5c8c563d44b4aa884c60dbe6b20d3ee755b604c4b8cb";
        patch="http://download.windowsupdate.com/d/msdownload/update/software/secu/2020/02/windows10.0-kb4537764-x64_93e41ada5a984e3749ecd87bc5515bdc48cefb4d.msu";
        patchsha256="b94ef8fa977c6e8255d8b50a19ac6512de725da5eae2f3ba96db6ace1a64e244";
        expandedpatch="windows10.0-kb4537764-x64.cab"
    };
    1809 = @{
        ## Taken from the mcr.microsoft.com/dotnet/framework/runtime:3.5 Dockerfile:
        ## https://github.com/microsoft/dotnet-framework-docker/blob/26597e42d157cc1e09d1e0dc8f23c32e6c3d1467/3.5/runtime/windowsservercore-ltsc2019/Dockerfile

        netfxzip = "https://dotnetbinaries.blob.core.windows.net/dockerassets/microsoft-windows-netfx3-1809.zip";
        netfxsha256 = "439f0b98438d9d302a21765cdfe2f28af784aa6a63dfff11c4e1a8a20e9fdf93"
        # Trying to get the patch with HTTPS yields:
        # 2022-02-24T15:53:44.6586746+00:00: curl: (60) schannel: SNI or certificate check failed: SEC_E_WRONG_PRINCIPAL (0x80090322) - The target principal name is incorrect.
        patch = "http://download.windowsupdate.com/c/msdownload/update/software/updt/2020/01/windows10.0-kb4534119-x64_a2dce2c83c58ea57145e9069f403d4a5d4f98713.msu";
        patchsha256 = "0287ba4106ba5462ba542e0124c4211f50bbce1123167375f125ea27b8f48632"
        expandedpatch = "windows10.0-kb4534119-x64.cab"
    };
    1909 = @{ 
        ## Taken from the mcr.microsoft.com/dotnet/framework/runtime:3.5 Dockerfile:
        ## https://github.com/microsoft/dotnet-framework-docker/blob/abc2ca65b28058f7c71ec8cd8763a8fbf2a9c03f/3.5/runtime/windowsservercore-1909/Dockerfile

        netfxzip = "https://dotnetbinaries.blob.core.windows.net/dockerassets/microsoft-windows-netfx3-1909.zip";
        netfxsha256 = "e451de8d0de5b6e8c6275e7f5baeec0fe755238964a42b89602f5e7a57542de2"
        # Trying to get the patch with HTTPS yields:
        # 2022-02-24T15:53:44.6586746+00:00: curl: (60) schannel: SNI or certificate check failed: SEC_E_WRONG_PRINCIPAL (0x80090322) - The target principal name is incorrect.
        patch = "http://download.windowsupdate.com/d/msdownload/update/software/updt/2020/01/windows10.0-kb4534132-x64-ndp48_21067bd5f9c305ee6a6cee79db6ca38587cb6ad8.msu";
        patchsha256 = "6f8acc2f1d9d83230ec400a04c5de07899dbf1ab3c8b299b0cea973c18abe009"
        expandedpatch = "windows10.0-kb4534132-x64-ndp48.cab"
    };
    2004 = @{
        # Taken from the mcr.microsoft.com/dotnet/framework/runtime:3.5 Dockerfile:
        # https://github.com/microsoft/dotnet-framework-docker/blob/25bdac46765c6dae7d05994cace836303f63b5e3/src/runtime/3.5/windowsservercore-2004/Dockerfile
        netfxzip = "https://dotnetbinaries.blob.core.windows.net/dockerassets/microsoft-windows-netfx3-2004.zip";
        netfxsha256 = "06ce7df5864490c76da45bd5d83662810afdbd44c719b710166e9eaf8ddc73e2"
        # Trying to get the patch with HTTPS yields:
        # 2022-02-24T15:53:44.6586746+00:00: curl: (60) schannel: SNI or certificate check failed: SEC_E_WRONG_PRINCIPAL (0x80090322) - The target principal name is incorrect.
        patch = "http://download.windowsupdate.com/c/msdownload/update/software/updt/2020/10/windows10.0-kb4580419-x64-ndp48_197efbd77177abe76a587359cea77bda5398c594.msu";
        patchsha256 = "5890767a66b8f979378128c70b1caa1a20e61c31176f8cbf598d7ef424f7b2d2"
        expandedpatch = "Windows10.0-KB4580419-x64-NDP48.cab"
    }
    2009 = @{ ## 20H2 reports itself as 2009 from the registry
        # Taken from the mcr.microsoft.com/dotnet/framework/runtime:3.5 Dockerfile:
        # https://github.com/microsoft/dotnet-framework-docker/blob/e0b59f4aeb47bd6bf13e4c7ec6676a1935306df9/src/runtime/3.5/windowsservercore-20H2/Dockerfile
        netfxzip = "https://dotnetbinaries.blob.core.windows.net/dockerassets/microsoft-windows-netfx3-2009.zip";
        netfxsha256 = "396ad6808a3d6013ff86e0e0163a8602da3fc7ddf36b82b2b18792f6497b88f3"
        # Trying to get the patch with HTTPS yields:
        # 2022-02-24T15:53:44.6586746+00:00: curl: (60) schannel: SNI or certificate check failed: SEC_E_WRONG_PRINCIPAL (0x80090322) - The target principal name is incorrect.
        patch = "http://download.windowsupdate.com/c/msdownload/update/software/updt/2020/10/windows10.0-kb4580419-x64-ndp48_197efbd77177abe76a587359cea77bda5398c594.msu";
        patchsha256 = "5890767a66b8f979378128c70b1caa1a20e61c31176f8cbf598d7ef424f7b2d2"
        expandedpatch = "Windows10.0-KB4580419-x64-NDP48.cab"
    }
    2022 = @{
        # Taken from the mcr.microsoft.com/dotnet/framework/runtime:3.5 Dockerfile:
        # https://github.com/microsoft/dotnet-framework-docker/blob/ee63b25718f434065cd9d1010580ba2a7ab2119f/src/runtime/3.5/windowsservercore-ltsc2022/Dockerfile
        netfxzip = "https://dotnetbinaries.blob.core.windows.net/dockerassets/microsoft-windows-netfx3-ltsc2022.zip";
        netfxsha256 = "e7bb9d923dd9e9d11629fab173ad78ecd622c3ab669344e421db62dfac93d16b"
        # Trying to get the patch with HTTPS yields:
        # 2022-02-24T15:53:44.6586746+00:00: curl: (60) schannel: SNI or certificate check failed: SEC_E_WRONG_PRINCIPAL (0x80090322) - The target principal name is incorrect.
        patch = "http://download.windowsupdate.com/c/msdownload/update/software/updt/2021/08/windows10.0-kb5005538-x64-ndp48_451a4214d51de628ef2c3c8a69c87826b2ab43c8.msu";
        patchsha256 = "d752801b38de2cd6e442385d0a2c9983a5bbe7ed87225bbb3190cdbdc1c0f067"
        expandedpatch = "windows10.0-kb5005538-x64-ndp48.cab"
    }
}
$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "netfx35" -Keyname "version" -TargetValue "1"
if($isInstalled){
    Write-Host -ForegroundColor Green "NetFX 3.51 already installed"
    return
}
if($Env:DD_DEV_TARGET -ne "Container") {
    $osInfo = Get-CimInstance -classname win32_operatingsystem
    if($osinfo.ProductType -eq "1"){
        & dism /online /enable-feature /FeatureName:Netfx3 /all
        return
    }
}
$kernelver = [int](get-itemproperty -path "hklm:software\microsoft\windows nt\currentversion" -name releaseid).releaseid
$build = [System.Environment]::OSVersion.version.build
$productname = (get-itemproperty -path "hklm:software\microsoft\windows nt\currentversion" -n productname).productname
Write-Host -ForegroundColor Green "Detected kernel version $kernelver, build $build and product name $productname"
# Windows Server 2022 still reports 2009 as releaseid
if ($build -ge 20348) {
    $kernelver = 2022
}

$Env:DOTNET_RUNNING_IN_CONTAINER="true"

$out = "$($PSScriptRoot)\microsoft-windows-netfx3.zip"
$sha256 = $UpgradeTable[$kernelver]["netfxsha256"]
Write-Host curl -fSLo $out $UpgradeTable[$kernelver]["netfxzip"]
Get-RemoteFile -RemoteFile $UpgradeTable[$kernelver]["netfxzip"] -LocalFile $out -VerifyHash $sha256

expand-archive -Path $out -DestinationPath .
remove-item -force $out
$cabfile = "microsoft-windows-netfx3-ondemand-package~31bf3856ad364e35~amd64~~.cab"
if($kernelver -eq 1607){
    $cabfile = "microsoft-windows-netfx3-ondemand-package.cab"
}
DISM /Online /Quiet /Add-Package /PackagePath:$($cabfile)
remove-item $cabfile
Remove-Item -Force -Recurse ${Env:TEMP}\* -ErrorAction SilentlyContinue


$out = "$($PSScriptRoot)\patch.msu"
$sha256 = $UpgradeTable[$kernelver]["patchsha256"]
Write-Host curl.exe -fSLo $out $UpgradeTable[$kernelver]["patch"]
Get-RemoteFile -RemoteFile $UpgradeTable[$kernelver]["patch"] -LocalFile $out -VerifyHash $sha256


mkdir patch
expand "$($PSScriptRoot)\patch.msu" patch -F:*
remove-item -force "$($PSScriptRoot)\patch.msu"
Write-Host DISM /Online /Quiet /Add-Package /PackagePath:$($UpgradeTable[$kernelver]["expandedpatch"])
DISM /Online /Quiet /Add-Package /PackagePath:$($UpgradeTable[$kernelver]["expandedpatch"])
remove-item -force -recurse patch

Set-InstalledVersionKey -Component "netfx35" -Keyname "version" -TargetValue "1"