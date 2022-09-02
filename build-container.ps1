param(
    [Parameter(Mandatory = $false)][string] $Arch = "x64",
    [Parameter(Mandatory = $false)][string] $Tag = $null,
    [Parameter(Mandatory = $false)][switch] $Cache
)

$ErrorActionPreference = "Stop"
. .\windows\versions.ps1
$BaseTable = @{
    1809 = "mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2019";
    1909 = "mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-1909";
    2004 = "mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-2004";
    ## 20H2 reports itself as 2009 in the registry
    2009 = "mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-20H2"
    2022 = "mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2022"
}

$kernelver = [int](get-itemproperty -path "hklm:software\microsoft\windows nt\currentversion" -name releaseid).releaseid
$build = [System.Environment]::OSVersion.version.build
$productname = (get-itemproperty -path "hklm:software\microsoft\windows nt\currentversion" -n productname).productname
Write-Host -ForegroundColor Green "Detected kernel version $kernelver, build $build and product name $productname"
# Windows Server 2022 still reports 2009 as releaseid
if ($build -ge 20348) {
    $kernelver = 2022
}

Write-Host -ForegroundColor Green "Using base image $($BaseTable[$kernelver])"

$arglist = @()
if($Tag -eq $null -or $Tag -eq ""){
    $Tag ="builder_$($kernelver)_$Arch"
}
$arglist += "build"

foreach ($h in $SoftwareTable.GetEnumerator()){
    if( -not ($($h.Key) -like "*SHA256")){
        $arglist += "--build-arg"
        $arglist += "$($h.Key)=$($h.Value)"
    }
}

if( -not $Cache) {
    $arglist += "--no-cache"
}

$arglist += -split "-m 4096M --build-arg BASE_IMAGE=$($BaseTable[$kernelver]) --build-arg DD_TARGET_ARCH=$Arch --build-arg WINDOWS_VERSION=$kernelver -t $Tag --file .\windows\Dockerfile ." 
# Write-Host -ForegroundColor Green "Building with the following command:"
# Write-Host -ForegroundColor Green "$buildcommand `n"
filter timestamp {"$(Get-Date -Format o): $_"}
& docker $arglist | timestamp

