param(
    [Parameter(Mandatory = $false)][string] $Arch = "x64",
    [Parameter(Mandatory = $false)][string] $Tag = $null,
    [Parameter(Mandatory = $false)][switch] $Cache
)


$BaseTable = @{
    1809 = "mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2019";
    1909 = "mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-1909";
    2004 = "mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-2004"
}

$kernelver = [int](get-itemproperty -path "hklm:software\microsoft\windows nt\currentversion" -name releaseid).releaseid
Write-Host -ForegroundColor Green "Detected kernel version $kernelver, using base image $($BaseTable[$kernelver])"

if($Tag -eq $null -or $Tag -eq ""){
    $Tag ="builder_$($kernelver)_$Arch"
}
$buildcommandparams = "--build-arg BASE_IMAGE=$($BaseTable[$kernelver]) --build-arg DD_TARGET_ARCH=$Arch --build-arg WINDOWS_VERSION=$kernelver -t $Tag --file .\windows\Dockerfile ."
if( -not $Cache) {
    $buildcommandparams = "--no-cache $buildcommandparams"
}
$buildcommand = "build $buildcommandparams"
# Write-Host -ForegroundColor Green "Building with the following command:"
# Write-Host -ForegroundColor Green "$buildcommand `n"
& docker $buildcommand.split()