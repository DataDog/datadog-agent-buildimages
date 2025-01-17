#
# Installs embedded python for use in unit testing.
# Be careful to use unique environment variables indicating location
# of the python files.
#
# We need to provide a location so that the test scripts can find python,
# but also need to make sure it doesn't confuse the actual builds.
#

# Uses:
# EMBEDDED_PYTHON_3_VERSION

# this downloads the necessary file

$ErrorActionPreference = 'Stop'

if($Env:DD_DEV_TARGET -ne "Container") {
   # I think this is actually necessary on server OSes.  Come back to this 
   # on server OSes.
   Write-Host -ForegroundColor Green "Skipping embedded pythons on local install"
   return
}

$py3 = "https://s3.amazonaws.com/dd-agent-omnibus/python-windows-${Env:EMBEDDED_PYTHON_3_VERSION}-amd64.zip"

$py3Target = "c:\embeddedpy\py${Env:EMBEDDED_PYTHON_3_VERSION}"

DownloadAndExpandTo -TargetDir $py3Target -SourceURL $py3 -Sha256 "$Env:EMBEDDED_PYTHON_3_SHA256"

Add-EnvironmentVariable -Variable "TEST_EMBEDDED_PY3" -Value $py3Target -Global

# Read DD_PIP_VERSION{,_PY3} and DD_SETUPTOOLS_VERSION{,_PY3} to variables
Get-Content \python-packages-versions.txt | Where-Object { $_.Trim() -ne '' } | Where-Object { $_.Trim() -notlike "#*" } | Foreach-Object{
   $var = $_.Split('=')
   Add-EnvironmentVariable -Variable $var[0] -Value $var[1] -Local
}

# Python 3
$py3getpip = "https://raw.githubusercontent.com/pypa/get-pip/66d8a0f637083e2c3ddffc0cb1e65ce126afb856/public/get-pip.py"
$py3getpipsha256 = "6fb7b781206356f45ad79efbb19322caa6c2a5ad39092d0d44d0fec94117e118"
Get-RemoteFile -LocalFile "get-pip.py" -RemoteFile $py3getpip -VerifyHash $py3getpipsha256
& "$py3Target\python" get-pip.py pip==${Env:DD_PIP_VERSION_PY3}
If ($lastExitCode -ne "0") { throw "Previous command returned $lastExitCode" }
& "$py3Target\python" -m pip install -r ../requirements.txt
If ($lastExitCode -ne "0") { throw "Previous command returned $lastExitCode" }
