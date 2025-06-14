# Source: https://github.com/moby/buildkit/blob/master/docs/windows.md#cni--networking-setup
. .\windows\helpers.ps1
# get the CNI plugins (binaries)
$cniPluginVersion = "0.3.1"
$sha256 = "4f36ee6905ada238ca2a9e1bfb8a1fb2912c2d88c4b6e5af4c41a42db70d7d68"
$cniBinDir = "$env:ProgramFiles\containerd\cni\bin"
mkdir $cniBinDir -Force
$cni_url = "https://github.com/microsoft/windows-container-networking/releases/download/v$cniPluginVersion/windows-container-networking-cni-amd64-v$cniPluginVersion.zip"
$out = "$($PSScriptRoot)\windows-container-networking-cni-amd64-v$cniPluginVersion.zip"
Get-RemoteFile -RemoteFile $cni_url -LocalFile $out -VerifyHash $sha256
tar xvf $out -C $cniBinDir

# NOTE: depending on your host setup, the IPs may change after restart
# you can only run this script from here to end for a refresh.
# without downloading the binaries again.

$cniVersion = "1.0.0"
$cniConfPath = "$env:ProgramFiles\containerd\cni\conf\0-containerd-nat.conf"

$networkName = 'nat'
# Get-HnsNetwork is available once you have enabled the 'Hyper-V Host Compute Service' feature
# which must have been done at the Quick setup above
# Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V, Containers -All
# the default one named `nat` should be available, except for WS2019, see notes below.
$natInfo = Get-HnsNetwork -ErrorAction Ignore | Where-Object { $_.Name -eq $networkName }
if ($null -eq $natInfo) {
    throw "NAT network not found, check if you enabled containers, Hyper-V features and restarted the machine"
}
$gateway = $natInfo.Subnets[0].GatewayAddress
$subnet = $natInfo.Subnets[0].AddressPrefix

$natConfig = @"
{
    "cniVersion": "$cniVersion",
    "name": "$networkName",
    "type": "nat",
    "master": "Ethernet",
    "ipam": {
        "subnet": "$subnet",
        "routes": [
            {
                "gateway": "$gateway"
            }
        ]
    },
    "capabilities": {
        "portMappings": true,
        "dns": true
    }
}
"@
Set-Content -Path $cniConfPath -Value $natConfig
# take a look
cat $cniConfPath

# quick test with nanoserver:ltsc20YY (YMMV)
$YY = 22
ctr i pull mcr.microsoft.com/windows/nanoserver:ltsc20$YY
ctr run --rm --cni mcr.microsoft.com/windows/nanoserver:ltsc20$YY cni-test cmd /C curl -I example.com
