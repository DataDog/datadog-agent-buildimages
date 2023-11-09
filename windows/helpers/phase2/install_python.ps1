param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)


# https://www.python.org/ftp/python/3.9.1/python-3.9.1-amd64.exe
$pyexe = "https://www.python.org/ftp/python/$($Version)/python-$($Version)-amd64.exe"

$isInstalled, $isCurrent = Get-InstallUpgradeStatus -Component "Python" -Keyname "version" -TargetValue $Version
if($isInstalled -and $isCurrent) {
    Write-Host -ForegroundColor Green "Python up to date"
    return
}
## presumably installer exe knows how to handle upgrades

Write-Host  -ForegroundColor Green starting with Python
$out = "$($PSScriptRoot)\python.exe"

Get-RemoteFile -RemoteFile $pyexe -LocalFile $out -VerifyHash $Sha256

Write-Host -ForegroundColor Green Done downloading Python, installing

Start-Process $out -ArgumentList '/quiet InstallAllUsers=1' -Wait

Add-ToPath "c:\program files\Python39;c:\Program files\python39\scripts" -Global -Local

Remove-Item $out

$getpipurl = "https://raw.githubusercontent.com/pypa/get-pip/38e54e5de07c66e875c11a1ebbdb938854625dd8/public/get-pip.py"
$getpipsha256 = "e235c437e5c7d7524fbce3880ca39b917a73dc565e0c813465b7a7a329bb279a"
$target = "$($PSScriptRoot)\get-pip.py"

Get-RemoteFile -RemoteFile $getpipurl -LocalFile $target -VerifyHash $getpipsha256

$packages_file = "\python-packages-versions.txt"
if($Env:DD_DEV_TARGET -ne "Container") {
    $packages_file = "$($PSScriptRoot)\..\..\.." + $packages_file
}
Get-Content $packages_file | Where-Object { $_.Trim() -ne '' } | Where-Object { $_.Trim() -notlike "#*" } | Foreach-Object{
    $var = $_.Split('=')
    Add-EnvironmentVariable -Variable $var[0] -Value $var[1] -Local
 }
 
python "$($PSScriptRoot)\get-pip.py" pip==${Env:DD_PIP_VERSION_PY3}
if($Env:DD_DEV_TARGET -eq "Container") {
    python -m pip install -r /requirements.txt
} else {
    ## When installing for local use, set up the virtual environment first
    python -m venv "$($Env:USERPROFILE)\.ddbuild\agentdev"
    &  "$($Env:USERPROFILE)\.ddbuild\agentdev\scripts\activate.ps1"
    python -m pip install -r "$($PSScriptRoot)\..\..\..\requirements.txt"
}


Set-InstalledVersionKey -Component "Python" -Keyname "version" -TargetValue $Version
Write-Host -ForegroundColor Green Done with Python
