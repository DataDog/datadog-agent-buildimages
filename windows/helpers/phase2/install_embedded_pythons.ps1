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
$packages_file = Join-Path $PSScriptRoot '..\..\..\python-packages-versions.txt'
Get-Content $packages_file | Where-Object { $_.Trim() -ne '' } | Where-Object { $_.Trim() -notlike "#*" } | Foreach-Object{
   $var = $_.Split('=')
   Add-EnvironmentVariable -Variable $var[0] -Value $var[1] -Local
}

# Python 3
$py3getpip = "https://raw.githubusercontent.com/pypa/get-pip/fa4e90301bf000c36309f3ad79c3ac720b55d6df/public/get-pip.py"
$py3getpipsha256 = "f4448a01e3ab2914c65f4ca59d4cacba6b2dbde19a483fbac46587f8bbaff424"
$out = Join-Path ([IO.Path]::GetTempPath()) 'get-pip.py'
Get-RemoteFile -LocalFile $out -RemoteFile $py3getpip -VerifyHash $py3getpipsha256
& "$py3Target\python" "$out" pip==${Env:DD_PIP_VERSION_PY3}
Remove-Item $out
If ($lastExitCode -ne "0") { throw "Previous command returned $lastExitCode" }
