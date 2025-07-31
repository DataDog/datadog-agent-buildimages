param (
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Sha256
)


# https://www.python.org/ftp/python/X.Y.Z/python-X.Y.Z-amd64.exe
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

Add-EnvironmentVariable -Variable PYTHONUTF8 -Value 1 -Local -Global
Add-ToPath "c:\program files\Python312;c:\Program files\python312\scripts" -Global -Local

Remove-Item $out

$getpipurl = "https://raw.githubusercontent.com/pypa/get-pip/66d8a0f637083e2c3ddffc0cb1e65ce126afb856/public/get-pip.py"
$getpipsha256 = "6fb7b781206356f45ad79efbb19322caa6c2a5ad39092d0d44d0fec94117e118"
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
if($Env:DD_DEV_TARGET -ne "Container") {
    ## When installing for local use, set up the virtual environment first
    python -m venv "$($Env:USERPROFILE)\.ddbuild\agentdev"
    &  "$($Env:USERPROFILE)\.ddbuild\agentdev\scripts\activate.ps1"
}

python -m pip install uv==${Env:DD_UV_VERSION}

$repoPath = "$($PSScriptRoot)\datadog-agent-dev"
Write-Host -ForegroundColor Green "Cloning dda repository..."
git clone --depth 1 --branch "$($Env:DDA_VERSION)" https://github.com/DataDog/datadog-agent-dev.git "$repoPath"

Push-Location "$repoPath"
try {
    Write-Host -ForegroundColor Green "Installing dda..."
    python -m uv export --no-editable --no-hashes -o requirements.txt
    python -m pip install -r requirements.txt
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to install dda"
        exit $LASTEXITCODE
    }
} finally {
    Pop-Location
}

Write-Host -ForegroundColor Green "Cleaning up repository..."
Remove-Item -Recurse -Force "$repoPath"

python -m dda self telemetry disable
python -m dda config set update.mode off
python -m dda -v self dep sync -f legacy-build
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to sync dda dependencies"
    exit $LASTEXITCODE
}

Set-InstalledVersionKey -Component "Python" -Keyname "version" -TargetValue $Version
Write-Host -ForegroundColor Green Done with Python
