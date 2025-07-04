$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


$wdk = 'https://go.microsoft.com/fwlink/?linkid=2307500' ##  wdk link

$isinstalled, $iscurrent = get-installupgradestatus -component "wdk" -keyname "downloadfile" -targetvalue $wdk
if ($isinstalled) {
    if (-not $iscurrent) {
        Write-Host -foregroundcolor yellow "not attempting to upgrade wdk"
    }
    return
}

Write-Host -foregroundcolor green installing wdk
$out = "$($psscriptroot)\wdksetup.exe"
$sha256 = "59c802a7edf1ecca172ec76a8b07702239ae83ee5ff9d1acb6742b2e224e9227"
Write-Host -foregroundcolor green downloading $wdk to $out

get-remotefile -remotefile $wdk -localfile $out -verifyhash $sha256

get-childitem $out
# write file size to make sure it worked
Write-Host -foregroundcolor green "file size is $((get-item $out).length)"


start-process $out -argumentlist '/features + /quiet' -wait


set-installedversionkey -component "wdk" -keyname "downloadfile" -targetvalue $wdk
Write-Host -foregroundcolor green done with wdk
